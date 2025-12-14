// Stub for user_management_service.dart - used on platforms where Firebase is not available
// This allows the code to compile without firebase dependencies

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import 'audit_log_service_stub.dart';

/// Model representing an admin/system user (shared between stub and real implementation)
class SystemUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final String status;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  SystemUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.status,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory SystemUser.fromJson(Map<String, dynamic> json) {
    return SystemUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Analyst/Viewer',
      department: json['department'] ?? '',
      status: json['status'] ?? 'Active',
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseDateTime(json['lastLoginAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map) {
      if (value['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch((value['_seconds'] as int) * 1000);
      }
      if (value['seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch((value['seconds'] as int) * 1000);
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '??';
  }

  SystemUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? department,
    String? status,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return SystemUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

/// Stub UserManagementService for native desktop platforms
/// On these platforms, use UserManagementServiceHttp instead
class UserManagementService extends ChangeNotifier with CachingMixin {
  final List<SystemUser> _users = [];
  final bool _isLoading = false;
  String? _error;
  
  // ignore: unused_field - Required for interface compatibility with HTTP service
  AuditLogService? _auditLogService;

  List<SystemUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void setAuditService(AuditLogService auditService) {
    _auditLogService = auditService;
  }
  
  UserManagementService();
  
  Future<void> fetchUsers({bool forceRefresh = false}) async {
    throw UnimplementedError('Use UserManagementServiceHttp on native desktop platforms');
  }
  
  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String department,
    String status = 'Active',
  }) async {
    throw UnimplementedError('Use UserManagementServiceHttp on native desktop platforms');
  }
  
  Future<bool> updateUser({
    required String userId,
    String? name,
    String? email,
    String? role,
    String? department,
    String? status,
    String? newPassword,
  }) async {
    throw UnimplementedError('Use UserManagementServiceHttp on native desktop platforms');
  }
  
  Future<bool> deleteUser(String userId, {String? userName, String? userEmail, bool hardDelete = true}) async {
    throw UnimplementedError('Use UserManagementServiceHttp on native desktop platforms');
  }
  
}
