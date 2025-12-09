// ==================== SERVICES ====================

// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  UserRole? get userRole => _currentUser?.role;

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
      case 'export_data':
        return _currentUser!.canExportData;
      case 'manage_users':
        return _currentUser!.canManageUsers;
      case 'delete_surveys':
        return _currentUser!.canDeleteSurveys;
      default:
        return false;
    }
  }

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
