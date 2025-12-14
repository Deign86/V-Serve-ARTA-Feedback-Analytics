// Stub for auth_services.dart - used on platforms where Firebase is not available
// This allows the code to compile without firebase dependencies

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'cache_service.dart';
// Note: We don't import the audit_log_service since it also uses Firebase
// The HTTP version should be used instead

/// Stub AuthService for native desktop platforms
/// On these platforms, use AuthServiceHttp instead
class AuthService extends ChangeNotifier with CachingMixin {
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  
  /// Completer to track when session restoration is complete
  late final Future<void> sessionRestored;
  
  static const String _sessionCacheKey = 'cached_session';
  static const String _sessionTimestampKey = 'session_timestamp';
  
  // Login attempt rate limiting
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  static const String _loginAttemptsKey = 'login_attempts';
  static const String _lockoutUntilKey = 'lockout_until';
  
  int _loginAttempts = 0;
  DateTime? _lockoutUntil;
  
  // Audit log service reference
  dynamic _auditLogService;
  
  void setAuditService(dynamic auditService) {
    _auditLogService = auditService;
  }

  // Protected setters for subclass access
  @protected
  set currentUserInternal(UserModel? user) => _currentUser = user;
  @protected
  set isAuthenticatedInternal(bool value) => _isAuthenticated = value;
  @protected
  Future<void> recordFailedAttemptInternal() => _recordFailedAttempt();
  @protected
  Future<void> resetLoginAttemptsInternal() => _resetLoginAttempts();
  
  /// Check if account is currently locked out
  bool get isLockedOut {
    if (_lockoutUntil == null) return false;
    if (DateTime.now().isAfter(_lockoutUntil!)) {
      _lockoutUntil = null;
      _loginAttempts = 0;
      _clearLoginAttempts();
      return false;
    }
    return true;
  }
  
  /// Get remaining lockout time in minutes
  int get remainingLockoutMinutes {
    if (_lockoutUntil == null) return 0;
    final remaining = _lockoutUntil!.difference(DateTime.now());
    return remaining.inMinutes + 1; // Round up
  }
  
  /// Get remaining login attempts
  int get remainingAttempts => _maxLoginAttempts - _loginAttempts;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  UserRole? get userRole => _currentUser?.role;
  
  /// Constructor - try to restore session from cache
  AuthService() {
    sessionRestored = _initializeSession();
  }
  
  /// Initialize session restoration
  Future<void> _initializeSession() async {
    await _restoreSession();
    await _restoreLoginAttempts();
    _isInitialized = true;
    notifyListeners();
  }
  
  /// Restore session from cache
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionCacheKey);
      final timestampStr = prefs.getString(_sessionTimestampKey);
      
      if (sessionJson == null || timestampStr == null) {
        debugPrint('AuthService: No cached session found');
        return;
      }
      
      final timestamp = DateTime.tryParse(timestampStr);
      if (timestamp == null || DateTime.now().difference(timestamp) > const Duration(days: 7)) {
        debugPrint('AuthService: Cached session expired');
        await _clearSession();
        return;
      }
      
      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
      _currentUser = UserModel(
        id: sessionData['id'] ?? '',
        name: sessionData['name'] ?? '',
        email: sessionData['email'] ?? '',
        role: _parseRole(sessionData['role'] ?? 'viewer'),
        department: sessionData['department'] ?? '',
        lastLogin: sessionData['lastLogin'] != null
            ? DateTime.tryParse(sessionData['lastLogin']) ?? DateTime.now()
            : DateTime.now(),
        createdAt: sessionData['createdAt'] != null
            ? DateTime.tryParse(sessionData['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
      _isAuthenticated = true;
      
      debugPrint('AuthService: Session restored for ${_currentUser!.name}');
    } catch (e) {
      debugPrint('AuthService: Error restoring session: $e');
    }
  }
  
  /// Restore login attempt state from cache
  Future<void> _restoreLoginAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _loginAttempts = prefs.getInt(_loginAttemptsKey) ?? 0;
      final lockoutStr = prefs.getString(_lockoutUntilKey);
      if (lockoutStr != null) {
        _lockoutUntil = DateTime.tryParse(lockoutStr);
      }
    } catch (e) {
      debugPrint('AuthService: Error restoring login attempts: $e');
    }
  }
  
  /// Record a failed login attempt
  Future<void> _recordFailedAttempt() async {
    _loginAttempts++;
    if (_loginAttempts >= _maxLoginAttempts) {
      _lockoutUntil = DateTime.now().add(_lockoutDuration);
      debugPrint('AuthService: Account locked until $_lockoutUntil');
    }
    await _saveLoginAttempts();
  }
  
  /// Reset login attempts
  Future<void> _resetLoginAttempts() async {
    _loginAttempts = 0;
    _lockoutUntil = null;
    await _clearLoginAttempts();
  }
  
  /// Save login attempts to cache
  Future<void> _saveLoginAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_loginAttemptsKey, _loginAttempts);
      if (_lockoutUntil != null) {
        await prefs.setString(_lockoutUntilKey, _lockoutUntil!.toIso8601String());
      }
    } catch (e) {
      debugPrint('AuthService: Error saving login attempts: $e');
    }
  }
  
  /// Clear login attempts from cache
  Future<void> _clearLoginAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loginAttemptsKey);
      await prefs.remove(_lockoutUntilKey);
    } catch (e) {
      debugPrint('AuthService: Error clearing login attempts: $e');
    }
  }
  
  /// Clear session from cache
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionCacheKey);
      await prefs.remove(_sessionTimestampKey);
    } catch (e) {
      debugPrint('AuthService: Error clearing session: $e');
    }
  }
  
  /// Convert role string to UserRole enum
  static UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'administrator':
      case 'admin':
        return UserRole.administrator;
      case 'editor':
        return UserRole.editor;
      case 'analyst':
      case 'analyst/viewer':
        return UserRole.analyst;
      case 'viewer':
        return UserRole.viewer;
      default:
        return UserRole.viewer;
    }
  }
  
  Future<bool> login(String email, String password) async {
    throw UnimplementedError('Use AuthServiceHttp on native desktop platforms');
  }
  
  Future<void> autoLogin(UserRole role) async {
    throw UnimplementedError('Use AuthServiceHttp on native desktop platforms');
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    await _clearSession();
    notifyListeners();
    
    debugPrint('AuthService: Logged out');
  }

  bool hasPermission(String permission) {
    if (_currentUser == null) return false;

    switch (permission) {
      case 'create_surveys':
        return _currentUser!.canCreateSurveys;
      case 'edit_surveys':
        return _currentUser!.canEditSurveys;
      case 'view_analytics':
        return _currentUser!.canViewAnalytics;
      case 'detailed_analytics':
        return _currentUser!.canAccessDetailedAnalytics;
      case 'export_data':
        return _currentUser!.canExportData;
      case 'manage_users':
        return _currentUser!.canManageUsers;
      case 'configuration':
        return _currentUser!.canAccessConfiguration;
      case 'delete_surveys':
        return _currentUser!.canDeleteSurveys;
      default:
        return false;
    }
  }
  
  /// Check if current user is an administrator
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  
  /// Check if current user is a viewer (non-admin)
  bool get isViewer => _currentUser?.isViewer ?? true;
}
