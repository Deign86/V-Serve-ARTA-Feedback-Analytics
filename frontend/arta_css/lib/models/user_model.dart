// ==================== MODELS ====================

// lib/models/user_model.dart
enum UserRole {
  administrator,
  editor, // Legacy - treated as viewer
  analyst, // Legacy - treated as viewer
  viewer,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final bool isActive;
  final DateTime lastLogin;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.isActive = true,
    required this.lastLogin,
    required this.createdAt,
  });

  /// Check if user is an administrator (full access)
  bool get isAdmin => role == UserRole.administrator;
  
  /// Check if user is a viewer (limited access)
  bool get isViewer => role == UserRole.viewer || role == UserRole.editor || role == UserRole.analyst;

  // Permissions based on role - RBAC: Admin (full access) vs Viewer (limited access)
  bool get canCreateSurveys => isAdmin;
  bool get canEditSurveys => isAdmin;
  bool get canViewAnalytics => true; // All roles can view basic analytics
  bool get canAccessDetailedAnalytics => isAdmin; // Only admin can access detailed analytics
  bool get canExportData => true; // All roles can export data
  bool get canManageUsers => isAdmin; // Only admin can manage users
  bool get canAccessConfiguration => isAdmin; // Only admin can access ARTA configuration
  bool get canDeleteSurveys => isAdmin;

  String get roleDisplayName {
    switch (role) {
      case UserRole.administrator:
        return 'Administrator';
      case UserRole.editor:
      case UserRole.analyst:
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
      ),
      department: json['department'],
      isActive: json['isActive'] ?? true,
      lastLogin: DateTime.parse(json['lastLogin']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'department': department,
      'isActive': isActive,
      'lastLogin': lastLogin.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}