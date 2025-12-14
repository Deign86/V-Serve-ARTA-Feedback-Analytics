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
  List<AuditLogEntry> _logs = [];
  bool _isLoading = false;
  String? _error;
  bool _isListening = false;
  
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
  
  @override
  void dispose() {
    super.dispose();
  }
}
