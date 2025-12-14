// HTTP-based AuthService implementation
// Uses the backend API instead of direct Firebase/Firestore access

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_config.dart';
import 'auth_services_stub.dart';

/// HTTP-based implementation of AuthService
/// Uses the backend API for authentication instead of direct Firebase access
class AuthServiceHttp extends AuthService {
  final ApiClient _apiClient = ApiClient();
  
  // Audit log service reference (set externally to avoid circular dependency)
  // Accepts both base AuditLogService and AuditLogServiceHttp
  dynamic _auditLogService;
  
  @override
  void setAuditService(dynamic auditService) {
    _auditLogService = auditService;
  }
  
  @override
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
      final response = await _apiClient.post('/auth/login', body: {
        'email': email,
        'password': password,
      });
      
      if (!response.isSuccess) {
        if (kDebugMode) debugPrint('Login failed: ${response.error}');
        
        // Record failed attempt
        await recordFailedAttemptInternal();
        
        // Log failed login attempt
        await _auditLogService?.logLoginFailed(
          attemptedEmail: email,
          reason: response.error ?? 'Unknown error',
        );
        return false;
      }
      
      final userData = response.data?['user'] as Map<String, dynamic>?;
      if (userData == null) {
        if (kDebugMode) debugPrint('Login failed: No user data in response');
        await recordFailedAttemptInternal();
        return false;
      }
      
      // Create user model from response
      currentUserInternal = UserModel(
        id: userData['id'] ?? '',
        name: userData['name'] ?? 'Unknown',
        email: userData['email'] ?? email,
        role: _parseRole(userData['role'] ?? 'viewer'),
        department: userData['department'] ?? '',
        lastLogin: DateTime.now(),
        createdAt: userData['createdAt'] != null
            ? DateTime.tryParse(userData['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
      
      isAuthenticatedInternal = true;
      notifyListeners();
      
      // Reset login attempts on successful login
      await resetLoginAttemptsInternal();
      
      // Save session to cache
      await _saveSession();
      
      // Log successful login
      await _auditLogService?.logLoginSuccess(user: currentUser!);
      
      if (kDebugMode) debugPrint('Login successful for ${currentUser!.name} (${currentUser!.role})');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Login error: $e');
      await _auditLogService?.logLoginFailed(
        attemptedEmail: email,
        reason: 'System error: ${e.toString()}',
      );
      return false;
    }
  }
  
  /// Save session to persistent cache
  Future<void> _saveSession() async {
    if (currentUser == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = {
        'id': currentUser!.id,
        'name': currentUser!.name,
        'email': currentUser!.email,
        'role': currentUser!.role.toString().split('.').last,
        'department': currentUser!.department,
        'lastLogin': currentUser!.lastLogin.toIso8601String(),
        'createdAt': currentUser!.createdAt.toIso8601String(),
      };
      
      await prefs.setString('cached_session', jsonEncode(sessionData));
      await prefs.setString('session_timestamp', DateTime.now().toIso8601String());
      debugPrint('AuthServiceHttp: Session saved');
    } catch (e) {
      debugPrint('AuthServiceHttp: Error saving session: $e');
    }
  }
  
  /// Convert role string to UserRole enum
  static UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'administrator':
      case 'admin': // Backend may store as 'admin' or 'Administrator'
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
  
  @override
  Future<void> autoLogin(UserRole role) async {
    // Auto-login is typically for testing - with HTTP API we'd need a test endpoint
    // For now, skip auto-login functionality
    debugPrint('AuthServiceHttp: Auto-login not supported in HTTP mode');
  }
  
  /// Validate session with the server
  Future<bool> validateSession() async {
    if (currentUser == null) return false;
    
    try {
      final response = await _apiClient.get('/auth/user', queryParams: {
        'email': currentUser!.email,
      });
      
      return response.isSuccess;
    } catch (e) {
      debugPrint('Session validation error: $e');
      return false;
    }
  }
  
  /// Check if API is reachable
  Future<bool> isApiAvailable() async {
    return await _apiClient.ping();
  }
}
