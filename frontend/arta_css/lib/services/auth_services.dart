// ==================== SERVICES ====================

// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  UserRole? get userRole => _currentUser?.role;

  // Demo users for testing
  final List<Map<String, dynamic>> _demoUsers = [
    {
      'email': 'admin@valenzuela.gov.ph',
      'password': 'admin123',
      'id': '1',
      'name': 'John Doe',
      'role': 'administrator',
      'department': 'IT Administration',
    },
    {
      'email': 'editor@valenzuela.gov.ph',
      'password': 'editor123',
      'id': '2',
      'name': 'Maria Santos',
      'role': 'editor',
      'department': 'Business Licensing',
    },
    {
      'email': 'analyst@valenzuela.gov.ph',
      'password': 'analyst123',
      'id': '3',
      'name': 'Carlos Rodriguez',
      'role': 'analyst',
      'department': 'Data Analytics',
    },
    {
      'email': 'viewer@valenzuela.gov.ph',
      'password': 'viewer123',
      'id': '4',
      'name': 'Anna Garcia',
      'role': 'viewer',
      'department': 'Building Permits',
    },
  ];

  Future<bool> login(String email, String password) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Find user in demo users
      final userMap = _demoUsers.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
        orElse: () => {},
      );

      if (userMap.isEmpty) {
        return false;
      }

      // Create user model
      _currentUser = UserModel(
        id: userMap['id'],
        name: userMap['name'],
        email: userMap['email'],
        role: UserRole.values.firstWhere(
          (e) => e.toString() == 'UserRole.${userMap['role']}',
        ),
        department: userMap['department'],
        lastLogin: DateTime.now(),
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      );

      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Login error: $e');
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

  // Auto-login for testing (optional)
  Future<void> autoLogin(UserRole role) async {
    final userMap = _demoUsers.firstWhere(
      (u) => u['role'] == role.toString().split('.').last,
    );

    _currentUser = UserModel(
      id: userMap['id'],
      name: userMap['name'],
      email: userMap['email'],
      role: role,
      department: userMap['department'],
      lastLogin: DateTime.now(),
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    );

    _isAuthenticated = true;
    notifyListeners();
  }
}
