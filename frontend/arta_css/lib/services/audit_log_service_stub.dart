// Stub for audit_log_service.dart - used on platforms where Firebase is not available
// This allows the code to compile without firebase dependencies

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import '../models/audit_log_model.dart';
import '../models/user_model.dart';
import 'cache_service.dart';

/// Stub AuditLogService for native desktop platforms
/// On these platforms, use AuditLogServiceHttp instead
class AuditLogService extends ChangeNotifier with CachingMixin {
  final List<AuditLogEntry> _logs = [];
  final bool _isLoading = false;
  String? _error;
  final bool _isListening = false;
  
  AuditActionType? _filterActionType;
  String? _filterActorId;
  DateTimeRange? _filterDateRange;
  
  List<AuditLogEntry> get logs => _logs;
  List<AuditLogEntry> get allLogs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isListening => _isListening;
  AuditActionType? get filterActionType => _filterActionType;
  String? get filterActorId => _filterActorId;
  DateTimeRange? get filterDateRange => _filterDateRange;
  
  AuditLogService();
  
  Future<bool> logAction({
    required AuditActionType actionType,
    required String actionDescription,
    required UserModel? actor,
    String? targetId,
    String? targetType,
    String? targetName,
    Map<String, dynamic>? previousValues,
    Map<String, dynamic>? newValues,
    Map<String, dynamic>? additionalInfo,
  }) async {
    throw UnimplementedError('Use AuditLogServiceHttp on native desktop platforms');
  }
  
  Future<void> fetchLogs({int limit = 100, bool forceRefresh = false}) async {
    throw UnimplementedError('Use AuditLogServiceHttp on native desktop platforms');
  }
  
  Future<void> startListening({int limit = 100}) async {
    throw UnimplementedError('Use AuditLogServiceHttp on native desktop platforms');
  }
  
  void stopListening() {}
  
  void setFilterActionType(AuditActionType? type) {
    _filterActionType = type;
    notifyListeners();
  }
  
  void setFilterActorId(String? actorId) {
    _filterActorId = actorId;
    notifyListeners();
  }
  
  void setFilterDateRange(DateTimeRange? dateRange) {
    _filterDateRange = dateRange;
    notifyListeners();
  }
  
  void clearFilters() {
    _filterActionType = null;
    _filterActorId = null;
    _filterDateRange = null;
    notifyListeners();
  }
  
  /// Log survey configuration change
  Future<bool> logSurveyConfigChanged({
    required UserModel? actor,
    required String configKey,
    required dynamic previousValue,
    required dynamic newValue,
  }) async {
    return logAction(
      actionType: AuditActionType.surveyConfigChanged,
      actionDescription: 'Changed survey configuration: $configKey',
      actor: actor,
      targetType: 'survey_config',
      targetName: configKey,
      previousValues: {configKey: previousValue},
      newValues: {configKey: newValue},
    );
  }
  
  /// Log feedback deletion
  Future<bool> logFeedbackDeleted({
    required UserModel? actor,
    required String feedbackId,
    Map<String, dynamic>? feedbackData,
  }) async {
    return logAction(
      actionType: AuditActionType.feedbackDeleted,
      actionDescription: 'Deleted feedback entry: $feedbackId',
      actor: actor,
      targetId: feedbackId,
      targetType: 'feedback',
      previousValues: feedbackData,
    );
  }
  
  /// Log feedback export
  Future<bool> logFeedbackExported({
    required UserModel? actor,
    required String exportFormat,
    required int recordCount,
    Map<String, dynamic>? filters,
  }) async {
    return logAction(
      actionType: AuditActionType.feedbackExported,
      actionDescription: 'Exported $recordCount feedback records as $exportFormat',
      actor: actor,
      targetType: 'feedback_export',
      additionalInfo: {
        'format': exportFormat,
        'recordCount': recordCount,
        if (filters != null) 'filters': filters,
      },
    );
  }

  /// Log user creation
  Future<bool> logUserCreated({
    required UserModel? actor,
    required String newUserId,
    required String newUserName,
    required String newUserEmail,
    required String newUserRole,
    required String newUserDepartment,
  }) async {
    return logAction(
      actionType: AuditActionType.userCreated,
      actionDescription: 'Created new user account for $newUserName',
      actor: actor,
      targetId: newUserId,
      targetType: 'user',
      targetName: newUserName,
      newValues: {
        'name': newUserName,
        'email': newUserEmail,
        'role': newUserRole,
        'department': newUserDepartment,
        'status': 'Active',
      },
    );
  }

  /// Log user update
  Future<bool> logUserUpdated({
    required UserModel? actor,
    required String targetUserId,
    required String targetUserName,
    required Map<String, dynamic> previousValues,
    required Map<String, dynamic> newValues,
  }) async {
    final changes = <String>[];
    for (final key in newValues.keys) {
      if (previousValues[key] != newValues[key]) {
        changes.add(key);
      }
    }
    
    return logAction(
      actionType: AuditActionType.userUpdated,
      actionDescription: 'Updated user $targetUserName (changed: ${changes.join(", ")})',
      actor: actor,
      targetId: targetUserId,
      targetType: 'user',
      targetName: targetUserName,
      previousValues: previousValues,
      newValues: newValues,
    );
  }

  /// Log user deletion
  Future<bool> logUserDeleted({
    required UserModel? actor,
    required String deletedUserId,
    required String deletedUserName,
    required String deletedUserEmail,
  }) async {
    return logAction(
      actionType: AuditActionType.userDeleted,
      actionDescription: 'Deleted user account: $deletedUserName ($deletedUserEmail)',
      actor: actor,
      targetId: deletedUserId,
      targetType: 'user',
      targetName: deletedUserName,
      previousValues: {
        'name': deletedUserName,
        'email': deletedUserEmail,
      },
    );
  }

  /// Log user status change
  Future<bool> logUserStatusChanged({
    required UserModel? actor,
    required String targetUserId,
    required String targetUserName,
    required String previousStatus,
    required String newStatus,
  }) async {
    return logAction(
      actionType: AuditActionType.userStatusChanged,
      actionDescription: 'Changed status of $targetUserName from $previousStatus to $newStatus',
      actor: actor,
      targetId: targetUserId,
      targetType: 'user',
      targetName: targetUserName,
      previousValues: {'status': previousStatus},
      newValues: {'status': newStatus},
    );
  }

  /// Log user role change
  Future<bool> logUserRoleChanged({
    required UserModel? actor,
    required String targetUserId,
    required String targetUserName,
    required String previousRole,
    required String newRole,
  }) async {
    return logAction(
      actionType: AuditActionType.userRoleChanged,
      actionDescription: 'Changed role of $targetUserName from $previousRole to $newRole',
      actor: actor,
      targetId: targetUserId,
      targetType: 'user',
      targetName: targetUserName,
      previousValues: {'role': previousRole},
      newValues: {'role': newRole},
    );
  }

  /// Log successful login
  Future<bool> logLoginSuccess({
    required UserModel user,
  }) async {
    return logAction(
      actionType: AuditActionType.loginSuccess,
      actionDescription: 'User ${user.name} logged in successfully',
      actor: user,
      targetId: user.id,
      targetType: 'session',
      targetName: user.email,
    );
  }

  /// Log failed login attempt
  Future<bool> logLoginFailed({
    required String attemptedEmail,
    String? reason,
  }) async {
    return logAction(
      actionType: AuditActionType.loginFailed,
      actionDescription: 'Failed login attempt for $attemptedEmail',
      actor: null,
      targetType: 'session',
      targetName: attemptedEmail,
      additionalInfo: {
        'attemptedEmail': attemptedEmail,
        'reason': reason ?? 'Invalid credentials',
      },
    );
  }

  /// Log logout
  Future<bool> logLogout({
    required UserModel user,
  }) async {
    return logAction(
      actionType: AuditActionType.logout,
      actionDescription: 'User ${user.name} logged out',
      actor: user,
      targetId: user.id,
      targetType: 'session',
      targetName: user.email,
    );
  }
  
}
