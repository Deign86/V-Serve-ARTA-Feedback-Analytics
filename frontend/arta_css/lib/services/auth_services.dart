// ==================== SERVICES ====================

// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'cache_service.dart';

class AuthService extends ChangeNotifier with CachingMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  
  static const String _sessionCacheKey = 'cached_session';
  static const String _sessionTimestampKey = 'session_timestamp';

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  UserRole? get userRole => _currentUser?.role;
  
  /// Constructor - try to restore session from cache
  AuthService() {
    _restoreSession();
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

  /// Hash a password using SHA-256 (must match backend seeding)
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
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
    try {
      // Hash the provided password
      final passwordHash = _hashPassword(password);

      // Query Firestore for user with matching email
      final querySnapshot = await _firestore
          .collection('system_users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('status', isEqualTo: 'Active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('Login failed: User not found or inactive - $email');
        return false;
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();

      // Verify password hash
      final storedHash = userData['passwordHash'] as String?;
      if (storedHash == null || storedHash != passwordHash) {
        debugPrint('Login failed: Invalid password for $email');
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
      
      // Save session to cache for faster subsequent logins
      await _saveSession();
      
      debugPrint('Login successful for ${_currentUser!.name} (${_currentUser!.role})');
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
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
