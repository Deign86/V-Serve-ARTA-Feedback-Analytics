// ==================== SERVICES ====================

// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'cache_service.dart';
import 'audit_log_service.dart';

class AuthService extends ChangeNotifier with CachingMixin {
  // Lazy initialization of Firestore to avoid accessing before Firebase is ready
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  // Audit log service reference (set externally to avoid circular dependency)
  AuditLogService? _auditLogService;
  
  /// Set the audit log service for logging authentication events
  void setAuditService(AuditLogService auditService) {
    _auditLogService = auditService;
  }
  
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  
  static const String _sessionCacheKey = 'cached_session';
  static const String _sessionTimestampKey = 'session_timestamp';
  
  // Login attempt rate limiting
  static const int _maxLoginAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  static const String _loginAttemptsKey = 'login_attempts';
  static const String _lockoutUntilKey = 'lockout_until';
  
  int _loginAttempts = 0;
  DateTime? _lockoutUntil;
  
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
  UserRole? get userRole => _currentUser?.role;
  
  /// Constructor - try to restore session from cache
  AuthService() {
    _restoreSession();
    _restoreLoginAttempts();
  }
  
  /// Restore login attempt state from cache
  Future<void> _restoreLoginAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _loginAttempts = prefs.getInt(_loginAttemptsKey) ?? 0;
      final lockoutStr = prefs.getString(_lockoutUntilKey);
      if (lockoutStr != null) {
        _lockoutUntil = DateTime.tryParse(lockoutStr);
        // Clear if lockout has expired
        if (_lockoutUntil != null && DateTime.now().isAfter(_lockoutUntil!)) {
          _lockoutUntil = null;
          _loginAttempts = 0;
          await _clearLoginAttempts();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AuthService: Error restoring login attempts: $e');
    }
  }
  
  /// Save login attempt state
  Future<void> _saveLoginAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_loginAttemptsKey, _loginAttempts);
      if (_lockoutUntil != null) {
        await prefs.setString(_lockoutUntilKey, _lockoutUntil!.toIso8601String());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AuthService: Error saving login attempts: $e');
    }
  }
  
  /// Clear login attempt state
  Future<void> _clearLoginAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loginAttemptsKey);
      await prefs.remove(_lockoutUntilKey);
    } catch (e) {
      if (kDebugMode) debugPrint('AuthService: Error clearing login attempts: $e');
    }
  }
  
  /// Record a failed login attempt
  Future<void> _recordFailedAttempt() async {
    _loginAttempts++;
    if (_loginAttempts >= _maxLoginAttempts) {
      _lockoutUntil = DateTime.now().add(_lockoutDuration);
    }
    await _saveLoginAttempts();
    notifyListeners();
  }
  
  /// Reset login attempts on successful login
  Future<void> _resetLoginAttempts() async {
    _loginAttempts = 0;
    _lockoutUntil = null;
    await _clearLoginAttempts();
  }
  
  /// Restore session from persistent cache
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionCacheKey);
      final timestampStr = prefs.getString(_sessionTimestampKey);
      
      if (sessionJson == null || timestampStr == null) return;
      
      final timestamp = DateTime.parse(timestampStr);
      // Session expires after 24 hours
      if (DateTime.now().difference(timestamp).inHours > 24) {
        await _clearSession();
        return;
      }
      
      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
      _currentUser = UserModel(
        id: sessionData['id'] ?? '',
        name: sessionData['name'] ?? 'Unknown',
        email: sessionData['email'] ?? '',
        role: _parseRole(sessionData['role'] ?? 'viewer'),
        department: sessionData['department'] ?? '',
        lastLogin: DateTime.tryParse(sessionData['lastLogin'] ?? '') ?? DateTime.now(),
        createdAt: DateTime.tryParse(sessionData['createdAt'] ?? '') ?? DateTime.now(),
      );
      
      _isAuthenticated = true;
      debugPrint('AuthService: Session restored for ${_currentUser!.name}');
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService: Error restoring session: $e');
    }
  }
  
  /// Save session to persistent cache
  Future<void> _saveSession() async {
    if (_currentUser == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = {
        'id': _currentUser!.id,
        'name': _currentUser!.name,
        'email': _currentUser!.email,
        'role': _currentUser!.role.toString().split('.').last,
        'department': _currentUser!.department,
        'lastLogin': _currentUser!.lastLogin.toIso8601String(),
        'createdAt': _currentUser!.createdAt.toIso8601String(),
      };
      
      await prefs.setString(_sessionCacheKey, jsonEncode(sessionData));
      await prefs.setString(_sessionTimestampKey, DateTime.now().toIso8601String());
      debugPrint('AuthService: Session saved');
    } catch (e) {
      debugPrint('AuthService: Error saving session: $e');
    }
  }
  
  /// Clear session from cache
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionCacheKey);
      await prefs.remove(_sessionTimestampKey);
      debugPrint('AuthService: Session cleared');
    } catch (e) {
      debugPrint('AuthService: Error clearing session: $e');
    }
  }

  /// Hash a password using bcrypt (secure, memory-hard algorithm)
  /// Note: For login, we use checkpw() instead of comparing hashes directly
  static String hashPassword(String password) {
    // Generate a salt with work factor 12 (good balance of security and performance)
    final salt = BCrypt.gensalt(logRounds: 12);
    return BCrypt.hashpw(password, salt);
  }

  /// Verify a password against a stored bcrypt hash
  static bool verifyPassword(String password, String hashedPassword) {
    try {
      return BCrypt.checkpw(password, hashedPassword);
    } catch (e) {
      debugPrint('Password verification error: $e');
      return false;
    }
  }

  /// Convert Firestore role string to UserRole enum
  static UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'administrator':
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
    // Check for lockout first
    if (isLockedOut) {
      await _auditLogService?.logLoginFailed(
        attemptedEmail: email,
        reason: 'Account locked - too many failed attempts',
      );
      return false;
    }
    
    try {
      // Query Firestore for user with matching email
      final querySnapshot = await _firestore
          .collection('system_users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('status', isEqualTo: 'Active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (kDebugMode) debugPrint('Login failed: User not found or inactive - $email');
        // Record failed attempt
        await _recordFailedAttempt();
        // Log failed login attempt
        await _auditLogService?.logLoginFailed(
          attemptedEmail: email,
          reason: 'User not found or inactive',
        );
        return false;
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();

      // Verify password using bcrypt
      final storedHash = userData['passwordHash'] as String?;
      if (storedHash == null || !verifyPassword(password, storedHash)) {
        if (kDebugMode) debugPrint('Login failed: Invalid password for $email');
        // Record failed attempt
        await _recordFailedAttempt();
        // Log failed login attempt
        await _auditLogService?.logLoginFailed(
          attemptedEmail: email,
          reason: 'Invalid password',
        );
        return false;
      }

      // Create user model from Firestore data
      _currentUser = UserModel(
        id: userDoc.id,
        name: userData['name'] ?? 'Unknown',
        email: userData['email'] ?? email,
        role: _parseRole(userData['role'] ?? 'viewer'),
        department: userData['department'] ?? '',
        lastLogin: DateTime.now(),
        createdAt: userData['createdAt'] is Timestamp
            ? (userData['createdAt'] as Timestamp).toDate()
            : DateTime.now().subtract(const Duration(days: 90)),
      );

      // Update last login timestamp in Firestore
      await _firestore.collection('system_users').doc(userDoc.id).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      _isAuthenticated = true;
      notifyListeners();
      
      // Reset login attempts on successful login
      await _resetLoginAttempts();
      
      // Save session to cache for faster subsequent logins
      await _saveSession();
      
      // Log successful login
      await _auditLogService?.logLoginSuccess(user: _currentUser!);
      
      if (kDebugMode) debugPrint('Login successful for ${_currentUser!.name} (${_currentUser!.role})');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Login error: $e');
      // Log failed login attempt with error
      await _auditLogService?.logLoginFailed(
        attemptedEmail: email,
        reason: 'System error: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> logout() async {
    // Log logout before clearing user
    if (_currentUser != null) {
      await _auditLogService?.logLogout(user: _currentUser!);
    }
    
    _currentUser = null;
    _isAuthenticated = false;
    await _clearSession();
    notifyListeners();
  }

  // Check if user has specific permission
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

  // Auto-login for testing (optional) - fetches from Firestore
  Future<void> autoLogin(UserRole role) async {
    try {
      final roleString = role.toString().split('.').last;
      String firestoreRole;
      switch (roleString) {
        case 'administrator':
          firestoreRole = 'Administrator';
          break;
        case 'editor':
          firestoreRole = 'Editor';
          break;
        case 'analyst':
          firestoreRole = 'Analyst';
          break;
        case 'viewer':
        default:
          firestoreRole = 'Viewer';
          break;
      }

      final querySnapshot = await _firestore
          .collection('system_users')
          .where('role', isEqualTo: firestoreRole)
          .where('status', isEqualTo: 'Active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('Auto-login failed: No user found with role $firestoreRole');
        return;
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();

      _currentUser = UserModel(
        id: userDoc.id,
        name: userData['name'] ?? 'Unknown',
        email: userData['email'] ?? '',
        role: role,
        department: userData['department'] ?? '',
        lastLogin: DateTime.now(),
        createdAt: userData['createdAt'] is Timestamp
            ? (userData['createdAt'] as Timestamp).toDate()
            : DateTime.now().subtract(const Duration(days: 90)),
      );

      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Auto-login error: $e');
    }
  }
}
