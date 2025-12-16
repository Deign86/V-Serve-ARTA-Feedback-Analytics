// HTTP-compatible AuditLogService implementation
// This version syncs audit logs with the centralized backend (Firestore)
// All platforms share the same audit logs for consistency

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import '../models/audit_log_model.dart';
import '../models/user_model.dart';
import 'api_config.dart';
import 'cache_service.dart';

/// HTTP-compatible implementation of AuditLogService
/// Uses centralized backend API for global audit log storage
class AuditLogServiceHttp extends ChangeNotifier with CachingMixin {
  final ApiClient _apiClient = ApiClient();
  
  List<AuditLogEntry> _logs = [];
  bool _isLoading = false;
  String? _error;
  
  // Filtering options
  AuditActionType? _filterActionType;
  String? _filterActorId;
  DateTimeRange? _filterDateRange;
  
  bool _isListening = false;
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 30);
  
  // Getters
  List<AuditLogEntry> get logs => _getFilteredLogs();
  List<AuditLogEntry> get allLogs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isListening => _isListening;
  AuditActionType? get filterActionType => _filterActionType;
  String? get filterActorId => _filterActorId;
  DateTimeRange? get filterDateRange => _filterDateRange;
  
  /// Sensitive fields that should never be logged
  static const List<String> _sensitiveFields = [
    'password',
    'passwordHash',
    'token',
    'secret',
    'apiKey',
    'accessToken',
    'refreshToken',
  ];
  
  AuditLogServiceHttp() {
    // Fetch logs from backend on initialization
    fetchLogs();
  }
  
  /// Fetch logs from the centralized backend API
  Future<void> _fetchLogsFromBackend({int limit = 1000}) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      
      if (_filterActionType != null) {
        queryParams['actionType'] = _filterActionType!.name;
      }
      if (_filterActorId != null) {
        queryParams['actorId'] = _filterActorId!;
      }
      
      final response = await _apiClient.get('/audit-logs', queryParams: queryParams);
      
      if (response.isSuccess && response.data != null) {
        final logsData = response.data!['logs'] as List<dynamic>?;
        if (logsData != null) {
          _logs = logsData
              .map((e) => AuditLogEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _error = null;
          debugPrint('AuditLogServiceHttp: Fetched ${_logs.length} logs from backend');
        }
      } else {
        _error = response.error ?? 'Failed to fetch audit logs';
        debugPrint('AuditLogServiceHttp: Error fetching logs: $_error');
      }
    } catch (e) {
      _error = 'Network error: $e';
      debugPrint('AuditLogServiceHttp: Error fetching logs: $e');
    }
  }
  
  /// Save a log entry to the centralized backend
  Future<bool> _saveLogToBackend(AuditLogEntry logEntry) async {
    try {
      final response = await _apiClient.post('/audit-logs', body: logEntry.toJson());
      
      if (response.isSuccess) {
        debugPrint('AuditLogServiceHttp: Saved log to backend');
        return true;
      } else {
        debugPrint('AuditLogServiceHttp: Error saving log: ${response.error}');
        return false;
      }
    } catch (e) {
      debugPrint('AuditLogServiceHttp: Error saving log to backend: $e');
      return false;
    }
  }
  
  /// Sanitize data before logging - removes sensitive information
  static Map<String, dynamic> _sanitizeData(Map<String, dynamic>? data) {
    if (data == null) return {};
    
    final sanitized = Map<String, dynamic>.from(data);
    
    for (final key in sanitized.keys.toList()) {
      if (_sensitiveFields.any((field) => 
          key.toLowerCase().contains(field.toLowerCase()))) {
        sanitized[key] = '[REDACTED]';
      }
    }
    
    return sanitized;
  }
  
  /// Log an audit entry (stored in centralized backend)
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
    try {
      final logEntry = AuditLogEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        actionType: actionType,
        actionDescription: actionDescription,
        timestamp: DateTime.now(),
        actorId: actor?.id ?? 'system',
        actorName: actor?.name ?? 'System',
        actorEmail: actor?.email ?? 'system@arta.gov.ph',
        actorRole: actor?.roleDisplayName ?? 'System',
        targetId: targetId,
        targetType: targetType,
        targetName: targetName,
        previousValues: _sanitizeData(previousValues),
        newValues: _sanitizeData(newValues),
        additionalInfo: additionalInfo,
      );
      
      // Save to centralized backend first
      final success = await _saveLogToBackend(logEntry);
      
      if (success) {
        // Add to local list for immediate display (most recent first)
        _logs.insert(0, logEntry);
        notifyListeners();
      }
      
      if (kDebugMode) {
        debugPrint('AuditLogServiceHttp: Logged action - ${actionType.name}: $actionDescription');
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuditLogServiceHttp: Error logging action: $e');
      }
      return false;
    }
  }
  
  // ========== Convenience logging methods ==========
  
  /// Log successful login
  Future<void> logLoginSuccess({required UserModel user}) async {
    await logAction(
      actionType: AuditActionType.loginSuccess,
      actionDescription: '${user.name} logged in successfully',
      actor: user,
    );
  }
  
  /// Log failed login attempt
  Future<void> logLoginFailed({required String attemptedEmail, String? reason}) async {
    await logAction(
      actionType: AuditActionType.loginFailed,
      actionDescription: 'Failed login attempt for $attemptedEmail${reason != null ? ': $reason' : ''}',
      actor: null,
      additionalInfo: {'attemptedEmail': attemptedEmail, 'reason': reason},
    );
  }
  
  /// Log logout
  Future<void> logLogout({required UserModel user}) async {
    await logAction(
      actionType: AuditActionType.logout,
      actionDescription: '${user.name} logged out',
      actor: user,
    );
  }
  
  /// Log user created
  Future<void> logUserCreated({
    UserModel? actor,
    required String newUserId,
    required String newUserName,
    required String newUserEmail,
    required String newUserRole,
    String? newUserDepartment,
  }) async {
    await logAction(
      actionType: AuditActionType.userCreated,
      actionDescription: 'Created new user: $newUserName ($newUserEmail)',
      actor: actor,
      targetId: newUserId,
      targetType: 'user',
      targetName: newUserName,
      newValues: {
        'name': newUserName,
        'email': newUserEmail,
        'role': newUserRole,
        'department': newUserDepartment,
      },
    );
  }
  
  /// Log user updated
  Future<void> logUserUpdated({
    UserModel? actor,
    required String targetUserId,
    required String targetUserName,
    Map<String, dynamic>? previousValues,
    Map<String, dynamic>? newValues,
  }) async {
    await logAction(
      actionType: AuditActionType.userUpdated,
      actionDescription: 'Updated user: $targetUserName',
      actor: actor,
      targetId: targetUserId,
      targetType: 'user',
      targetName: targetUserName,
      previousValues: previousValues,
      newValues: newValues,
    );
  }
  
  /// Log user role changed
  Future<void> logUserRoleChanged({
    UserModel? actor,
    required String targetUserId,
    required String targetUserName,
    required String previousRole,
    required String newRole,
  }) async {
    await logAction(
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
  
  /// Log user status changed
  Future<void> logUserStatusChanged({
    UserModel? actor,
    required String targetUserId,
    required String targetUserName,
    required String previousStatus,
    required String newStatus,
  }) async {
    await logAction(
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
  
  /// Log user deleted
  Future<void> logUserDeleted({
    UserModel? actor,
    required String deletedUserId,
    required String deletedUserName,
    String? deletedUserEmail,
  }) async {
    await logAction(
      actionType: AuditActionType.userDeleted,
      actionDescription: 'Deleted user: $deletedUserName',
      actor: actor,
      targetId: deletedUserId,
      targetType: 'user',
      targetName: deletedUserName,
      additionalInfo: {'deletedEmail': deletedUserEmail},
    );
  }
  
  /// Log survey config changed
  Future<void> logSurveyConfigChanged({
    UserModel? actor,
    required String configKey,
    required dynamic previousValue,
    required dynamic newValue,
  }) async {
    await logAction(
      actionType: AuditActionType.surveyConfigChanged,
      actionDescription: 'Changed survey config: $configKey',
      actor: actor,
      targetType: 'config',
      targetName: configKey,
      previousValues: {'value': previousValue},
      newValues: {'value': newValue},
    );
  }
  
  /// Log feedback exported
  Future<void> logFeedbackExported({
    UserModel? actor,
    required String exportFormat,
    required int recordCount,
    Map<String, dynamic>? filters,
  }) async {
    await logAction(
      actionType: AuditActionType.feedbackExported,
      actionDescription: 'Exported $recordCount feedback records as $exportFormat',
      actor: actor,
      targetType: 'export',
      targetName: exportFormat,
      additionalInfo: {
        'format': exportFormat,
        'recordCount': recordCount,
        'filters': filters,
      },
    );
  }
  
  /// Log dashboard viewed
  Future<void> logDashboardViewed({UserModel? actor}) async {
    await logAction(
      actionType: AuditActionType.dashboardViewed,
      actionDescription: 'Viewed dashboard',
      actor: actor,
      targetType: 'page',
      targetName: 'Dashboard',
    );
  }
  
  /// Log analytics viewed
  Future<void> logAnalyticsViewed({UserModel? actor}) async {
    await logAction(
      actionType: AuditActionType.analyticsViewed,
      actionDescription: 'Viewed analytics',
      actor: actor,
      targetType: 'page',
      targetName: 'Analytics',
    );
  }
  
  /// Log user list viewed
  Future<void> logUserListViewed({UserModel? actor}) async {
    await logAction(
      actionType: AuditActionType.userListViewed,
      actionDescription: 'Viewed user list',
      actor: actor,
      targetType: 'page',
      targetName: 'User Management',
    );
  }
  
  /// Log audit log viewed
  Future<void> logAuditLogViewed({UserModel? actor}) async {
    await logAction(
      actionType: AuditActionType.auditLogViewed,
      actionDescription: 'Viewed audit log',
      actor: actor,
      targetType: 'page',
      targetName: 'Audit Log',
    );
  }
  
  /// Log data exports viewed
  Future<void> logDataExportsViewed({UserModel? actor}) async {
    await logAction(
      actionType: AuditActionType.dataExportsViewed,
      actionDescription: 'Viewed data exports',
      actor: actor,
      targetType: 'page',
      targetName: 'Data Exports',
    );
  }
  
  /// Log ARTA config viewed
  Future<void> logArtaConfigViewed({UserModel? actor}) async {
    await logAction(
      actionType: AuditActionType.artaConfigViewed,
      actionDescription: 'Viewed ARTA configuration',
      actor: actor,
      targetType: 'page',
      targetName: 'ARTA Configuration',
    );
  }
  
  /// Log settings viewed
  Future<void> logSettingsViewed({UserModel? actor}) async {
    await logAction(
      actionType: AuditActionType.settingsChanged,
      actionDescription: 'Viewed settings',
      actor: actor,
      targetType: 'page',
      targetName: 'Settings',
    );
  }
  
  /// Log survey started
  Future<void> logSurveyStarted({UserModel? actor}) async {
    await logAction(
      actionType: AuditActionType.surveyStarted,
      actionDescription: 'Survey started by anonymous user',
      actor: actor,
      targetType: 'survey',
      targetName: 'CSS Survey',
    );
  }
  
  /// Log survey submitted
  Future<void> logSurveySubmitted({
    UserModel? actor,
    String? clientType,
    String? serviceAvailed,
    String? region,
  }) async {
    await logAction(
      actionType: AuditActionType.surveySubmitted,
      actionDescription: 'Survey submitted for $serviceAvailed',
      actor: actor,
      targetType: 'survey',
      targetName: 'CSS Survey',
      additionalInfo: {
        'clientType': clientType,
        'serviceAvailed': serviceAvailed,
        'region': region,
      },
    );
  }
  
  // ========== Filtering and fetching ==========
  
  /// Get filtered logs based on current filters
  List<AuditLogEntry> _getFilteredLogs() {
    var filtered = _logs.toList();
    
    if (_filterActionType != null) {
      filtered = filtered.where((l) => l.actionType == _filterActionType).toList();
    }
    
    if (_filterActorId != null) {
      filtered = filtered.where((l) => l.actorId == _filterActorId).toList();
    }
    
    if (_filterDateRange != null) {
      filtered = filtered.where((l) =>
          l.timestamp.isAfter(_filterDateRange!.start) &&
          l.timestamp.isBefore(_filterDateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }
    
    return filtered;
  }
  
  /// Set filter by action type
  void setActionTypeFilter(AuditActionType? actionType) {
    _filterActionType = actionType;
    notifyListeners();
  }
  
  /// Set filter by actor
  void setActorFilter(String? actorId) {
    _filterActorId = actorId;
    notifyListeners();
  }
  
  /// Set filter by date range
  void setDateRangeFilter(DateTimeRange? dateRange) {
    _filterDateRange = dateRange;
    notifyListeners();
  }
  
  /// Clear all filters
  void clearFilters() {
    _filterActionType = null;
    _filterActorId = null;
    _filterDateRange = null;
    notifyListeners();
  }
  
  /// Start listening for updates (polling from backend)
  void startRealtimeUpdates() {
    if (_isListening) return;
    
    _isListening = true;
    notifyListeners();
    
    // Start polling for updates from the centralized backend
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      fetchLogs(forceRefresh: true);
    });
    
    debugPrint('AuditLogServiceHttp: Started polling for updates');
  }
  
  /// Stop listening
  void stopRealtimeUpdates() {
    _isListening = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('AuditLogServiceHttp: Stopped polling for updates');
  }
  
  /// Fetch logs from centralized backend
  Future<void> fetchLogs({int limit = 1000, bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    await _fetchLogsFromBackend(limit: limit);
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// Set filters
  void setFilters({AuditActionType? actionType, String? actorId, DateTimeRange? dateRange}) {
    _filterActionType = actionType;
    if (actorId != null) _filterActorId = actorId;
    if (dateRange != null) _filterDateRange = dateRange;
    notifyListeners();
  }
  
  /// Get audit statistics
  Map<String, dynamic> getAuditStats() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final logsToday = _logs.where((l) => l.timestamp.isAfter(todayStart)).length;
    final logsThisWeek = _logs.where((l) => l.timestamp.isAfter(weekAgo)).length;
    
    // Count failed logins
    final failedLogins = _logs.where((l) => 
      l.actionType == AuditActionType.loginFailed
    ).length;
    
    // Count by type
    final typeCount = <String, int>{};
    for (final log in _logs) {
      final typeName = log.actionType.name;
      typeCount[typeName] = (typeCount[typeName] ?? 0) + 1;
    }
    
    return {
      'totalLogs': _logs.length,
      'logsToday': logsToday,
      'logsThisWeek': logsThisWeek,
      'failedLogins': failedLogins,
      'byType': typeCount,
    };
  }
  
  /// Clear all logs (admin action - clears from backend would need separate endpoint)
  Future<void> clearLogs() async {
    // Note: This only clears local cache. Backend logs are persistent.
    // To clear backend logs, a dedicated admin endpoint would be needed.
    _logs = [];
    notifyListeners();
    debugPrint('AuditLogServiceHttp: Cleared local log cache');
  }
  
  /// Get unique actors for filtering
  List<String> getUniqueActors() {
    return _logs.map((l) => l.actorName).toSet().toList()..sort();
  }
  
  @override
  void dispose() {
    stopRealtimeUpdates();
    _apiClient.dispose();
    super.dispose();
  }
}
