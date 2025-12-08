// ==================== MODELS ====================

// lib/models/user_model.dart
enum UserRole {
  administrator,
  editor,
  analyst,
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

  // Permissions based on role
  bool get canCreateSurveys => role == UserRole.administrator || role == UserRole.editor;
  bool get canEditSurveys => role == UserRole.administrator || role == UserRole.editor;
  bool get canViewAnalytics => true; // All roles can view analytics
  bool get canExportData => role != UserRole.viewer;
  bool get canManageUsers => role == UserRole.administrator;
  bool get canDeleteSurveys => role == UserRole.administrator;

  String get roleDisplayName {
    switch (role) {
      case UserRole.administrator:
        return 'Administrator';
      case UserRole.editor:
        return 'Editor';
      case UserRole.analyst:
        return 'Analyst';
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