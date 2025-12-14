import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log_model.dart';
import '../models/user_model.dart';
import 'cache_service.dart';

/// Service for logging and retrieving audit entries
/// Implements non-repudiation by maintaining immutable audit trails
class AuditLogService extends ChangeNotifier with CachingMixin {
  // Lazy initialization of Firestore to avoid accessing before Firebase is ready
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  static const String _collectionName = 'audit_logs';
  static const String _auditLogsCacheKey = 'audit_logs_list';
  
  List<AuditLogEntry> _logs = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetch;
  
  // Total count of logs in Firestore (not limited by fetch)
  int _totalLogsCount = 0;
  
  // Filtering options
  AuditActionType? _filterActionType;
  String? _filterActorId;
  DateTimeRange? _filterDateRange;
  
  StreamSubscription<QuerySnapshot>? _logsSubscription;
  bool _isListening = false;
  
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

  /// Log an audit entry to Firestore
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
      // Create log entry with sanitized data
      final logEntry = {
        'actionType': actionType.name,
        'actionDescription': actionDescription,
        'timestamp': FieldValue.serverTimestamp(),
        'actorId': actor?.id ?? 'system',
        'actorName': actor?.name ?? 'System',
        'actorEmail': actor?.email ?? 'system@arta.gov.ph',
        'actorRole': actor?.roleDisplayName ?? 'System',
        'targetId': targetId,
        'targetType': targetType,
        'targetName': targetName,
        'previousValues': _sanitizeData(previousValues),
        'newValues': _sanitizeData(newValues),
        'additionalInfo': additionalInfo,
        // Note: ipAddress and userAgent would be added server-side in production
      };

      final docRef = await _firestore.collection(_collectionName).add(logEntry);
      if (kDebugMode) {
        debugPrint('AuditLogService: Logged action - ${actionType.name}: $actionDescription');
      }
      
      // Trigger alert for high-severity actions
      await _triggerAlertIfNeeded(actionType, actionDescription, docRef.id, actor);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuditLogService: Error logging action: $e');
      }
      return false;
    }
  }
  
  /// Trigger alert for high-severity audit actions
  Future<void> _triggerAlertIfNeeded(
    AuditActionType actionType,
    String description,
    String logId,
    UserModel? actor,
  ) async {
    // High-severity actions that require admin notification
    const highSeverityActions = [
      AuditActionType.loginFailed,
      AuditActionType.userDeleted,
      AuditActionType.feedbackDeleted,
      AuditActionType.userStatusChanged,
      AuditActionType.userRoleChanged,
    ];
    
    if (!highSeverityActions.contains(actionType)) return;
    
    try {
      // Create alert entry in Firestore for the alert service to pick up
      await _firestore.collection('alerts').add({
        'title': _getAlertTitle(actionType),
        'message': description,
        'severity': _getAlertSeverity(actionType),
        'timestamp': FieldValue.serverTimestamp(),
        'sourceLogId': logId,
        'isRead': false,
        'emailSent': false,
      });
      
      // Queue email notification for critical events
      if (actionType == AuditActionType.userDeleted || 
          actionType == AuditActionType.feedbackDeleted) {
        await _queueAdminEmailNotification(actionType, description);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuditLogService: Error triggering alert: $e');
      }
    }
  }
  
  String _getAlertTitle(AuditActionType actionType) {
    switch (actionType) {
      case AuditActionType.loginFailed:
        return 'Failed Login Attempt';
      case AuditActionType.userDeleted:
        return 'User Account Deleted';
      case AuditActionType.feedbackDeleted:
        return 'Feedback Data Deleted';
      case AuditActionType.userStatusChanged:
        return 'User Status Changed';
      case AuditActionType.userRoleChanged:
        return 'User Role Changed';
      default:
        return 'System Event';
    }
  }
  
  String _getAlertSeverity(AuditActionType actionType) {
    switch (actionType) {
      case AuditActionType.userDeleted:
      case AuditActionType.feedbackDeleted:
        return 'critical';
      case AuditActionType.loginFailed:
      case AuditActionType.userStatusChanged:
      case AuditActionType.userRoleChanged:
        return 'high';
      default:
        return 'medium';
    }
  }
  
  /// Queue email notification for admin users
  Future<void> _queueAdminEmailNotification(
    AuditActionType actionType,
    String description,
  ) async {
    try {
      // Get all active admin users
      final adminsSnapshot = await _firestore
          .collection('system_users')
          .where('role', isEqualTo: 'Administrator')
          .where('status', isEqualTo: 'Active')
          .get();
      
      if (adminsSnapshot.docs.isEmpty) return;
      
      // Queue email for each admin
      for (final adminDoc in adminsSnapshot.docs) {
        final email = adminDoc.data()['email'] as String?;
        final name = adminDoc.data()['name'] as String? ?? 'Admin';
        
        if (email == null || email.isEmpty) continue;
        
        await _firestore.collection('email_queue').add({
          'to': email,
          'subject': '[ARTA CSS Alert] ${_getAlertSeverity(actionType).toUpperCase()}: ${_getAlertTitle(actionType)}',
          'body': '''
Dear $name,

A ${_getAlertSeverity(actionType).toUpperCase()} severity event has occurred in the ARTA Client Satisfaction Survey system.

Event: ${_getAlertTitle(actionType)}
Details: $description
Time: ${DateTime.now().toLocal()}

Please review the audit logs in the admin dashboard for more details.

---
ARTA CSS Alert System
City Government of Valenzuela
''',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'retries': 0,
        });
        
        if (kDebugMode) {
          debugPrint('AuditLogService: Queued email notification to $email');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuditLogService: Error queueing email: $e');
      }
    }
  }

  // ==================== Convenience logging methods ====================

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
    // Determine what changed for the description
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
      actor: null, // No actor since login failed
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
        'filters': filters,
      },
    );
  }

  // ==================== Survey/User Actions ====================

  /// Log when a survey is submitted by a citizen/user
  Future<bool> logSurveySubmitted({
    String? clientType,
    String? serviceAvailed,
    String? region,
  }) async {
    return logAction(
      actionType: AuditActionType.surveySubmitted,
      actionDescription: 'Survey submitted by ${clientType ?? "Anonymous"} user',
      actor: null, // Anonymous user
      targetType: 'survey',
      additionalInfo: {
        'clientType': clientType ?? 'Unknown',
        'serviceAvailed': serviceAvailed ?? 'Unknown',
        'region': region ?? 'Unknown',
        'submittedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log when a user starts a new survey
  Future<bool> logSurveyStarted({
    String? clientType,
  }) async {
    return logAction(
      actionType: AuditActionType.surveyStarted,
      actionDescription: 'New survey started by ${clientType ?? "Anonymous"} user',
      actor: null, // Anonymous user
      targetType: 'survey',
      additionalInfo: {
        'clientType': clientType ?? 'Unknown',
        'startedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // ==================== Admin Data Access Actions ====================

  /// Log when admin views the dashboard
  Future<bool> logDashboardViewed({
    required UserModel? actor,
  }) async {
    return logAction(
      actionType: AuditActionType.dashboardViewed,
      actionDescription: 'Viewed admin dashboard',
      actor: actor,
      targetType: 'dashboard',
    );
  }

  /// Log when admin views detailed analytics
  Future<bool> logAnalyticsViewed({
    required UserModel? actor,
    String? analyticsType,
  }) async {
    return logAction(
      actionType: AuditActionType.analyticsViewed,
      actionDescription: 'Viewed ${analyticsType ?? "detailed"} analytics',
      actor: actor,
      targetType: 'analytics',
      additionalInfo: analyticsType != null ? {'analyticsType': analyticsType} : null,
    );
  }

  /// Log when admin browses feedback data
  Future<bool> logFeedbackBrowserViewed({
    required UserModel? actor,
    int? recordCount,
  }) async {
    return logAction(
      actionType: AuditActionType.feedbackBrowserViewed,
      actionDescription: 'Browsed feedback data${recordCount != null ? " ($recordCount records)" : ""}',
      actor: actor,
      targetType: 'feedback_browser',
      additionalInfo: recordCount != null ? {'recordCount': recordCount} : null,
    );
  }

  /// Log when admin views user list
  Future<bool> logUserListViewed({
    required UserModel? actor,
  }) async {
    return logAction(
      actionType: AuditActionType.userListViewed,
      actionDescription: 'Viewed user management list',
      actor: actor,
      targetType: 'user_list',
    );
  }

  /// Log when admin views audit logs
  Future<bool> logAuditLogViewed({
    required UserModel? actor,
  }) async {
    return logAction(
      actionType: AuditActionType.auditLogViewed,
      actionDescription: 'Viewed audit log history',
      actor: actor,
      targetType: 'audit_log',
    );
  }

  /// Log when admin views data exports screen
  Future<bool> logDataExportsViewed({
    required UserModel? actor,
  }) async {
    return logAction(
      actionType: AuditActionType.dataExportsViewed,
      actionDescription: 'Viewed data exports screen',
      actor: actor,
      targetType: 'data_exports',
    );
  }

  /// Log when admin views ARTA configuration screen
  Future<bool> logArtaConfigViewed({
    required UserModel? actor,
  }) async {
    return logAction(
      actionType: AuditActionType.artaConfigViewed,
      actionDescription: 'Viewed ARTA configuration settings',
      actor: actor,
      targetType: 'arta_config',
    );
  }

  /// Log when admin views Settings screen
  Future<bool> logSettingsViewed({
    required UserModel? actor,
  }) async {
    return logAction(
      actionType: AuditActionType.settingsChanged,
      actionDescription: 'Viewed system settings',
      actor: actor,
      targetType: 'settings',
    );
  }

  // ==================== Retrieval methods ====================

  /// Get filtered logs based on current filters
  List<AuditLogEntry> _getFilteredLogs() {
    var filtered = _logs.toList();

    if (_filterActionType != null) {
      filtered = filtered.where((log) => log.actionType == _filterActionType).toList();
    }

    if (_filterActorId != null) {
      filtered = filtered.where((log) => log.actorId == _filterActorId).toList();
    }

    if (_filterDateRange != null) {
      filtered = filtered.where((log) =>
          log.timestamp.isAfter(_filterDateRange!.start) &&
          log.timestamp.isBefore(_filterDateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }

    return filtered;
  }

  /// Set filters
  void setFilters({
    AuditActionType? actionType,
    String? actorId,
    DateTimeRange? dateRange,
  }) {
    _filterActionType = actionType;
    _filterActorId = actorId;
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

  /// Fetch audit logs from Firestore
  Future<void> fetchLogs({bool forceRefresh = false, int limit = 100}) async {
    // Check cache first
    if (!forceRefresh && _logs.isNotEmpty && _lastFetch != null) {
      final diff = DateTime.now().difference(_lastFetch!);
      if (diff.inMinutes < 5) {
        return;
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch logs with limit
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      _logs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AuditLogEntry.fromJson(data);
      }).toList();

      // Fetch total count separately using count() aggregation
      try {
        final countQuery = await _firestore
            .collection(_collectionName)
            .count()
            .get();
        _totalLogsCount = countQuery.count ?? _logs.length;
      } catch (e) {
        // Fallback to using _logs.length if count() not supported
        _totalLogsCount = _logs.length;
        debugPrint('AuditLogService: Count aggregation failed, using logs length: $e');
      }

      _lastFetch = DateTime.now();
      _isLoading = false;
      
      // Cache in memory
      cacheService.setInMemory(_auditLogsCacheKey, _logs, ttl: CacheConfig.defaultTTL);
      
      notifyListeners();
    } catch (e) {
      debugPrint('AuditLogService: Error fetching logs: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start real-time updates for audit logs
  void startRealtimeUpdates({int limit = 100}) {
    if (_isListening) return;

    debugPrint('=== STARTING AUDIT LOG LISTENER ===');
    _isListening = true;
    _isLoading = true;
    notifyListeners();

    _logsSubscription = _firestore
        .collection(_collectionName)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint('Audit log update: ${snapshot.docs.length} entries');

            _logs = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return AuditLogEntry.fromJson(data);
            }).toList();

            _lastFetch = DateTime.now();
            _isLoading = false;
            _error = null;

            cacheService.setInMemory(_auditLogsCacheKey, _logs, ttl: CacheConfig.defaultTTL);
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Audit log listener error: $error');
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Stop real-time updates
  void stopRealtimeUpdates() {
    debugPrint('=== STOPPING AUDIT LOG LISTENER ===');
    _logsSubscription?.cancel();
    _logsSubscription = null;
    _isListening = false;
  }

  /// Get logs for a specific user (actor)
  Future<List<AuditLogEntry>> getLogsForActor(String actorId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('actorId', isEqualTo: actorId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AuditLogEntry.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('AuditLogService: Error fetching logs for actor: $e');
      return [];
    }
  }

  /// Get logs for a specific target
  Future<List<AuditLogEntry>> getLogsForTarget(String targetId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('targetId', isEqualTo: targetId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AuditLogEntry.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('AuditLogService: Error fetching logs for target: $e');
      return [];
    }
  }

  /// Get audit statistics
  Map<String, dynamic> getAuditStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(const Duration(days: 7));
    
    return {
      'totalLogs': _totalLogsCount > 0 ? _totalLogsCount : _logs.length,
      'logsToday': _logs.where((l) => l.timestamp.isAfter(today)).length,
      'logsThisWeek': _logs.where((l) => l.timestamp.isAfter(thisWeek)).length,
      'loginAttempts': _logs.where((l) => 
          l.actionType == AuditActionType.loginSuccess || 
          l.actionType == AuditActionType.loginFailed).length,
      'failedLogins': _logs.where((l) => l.actionType == AuditActionType.loginFailed).length,
      'userChanges': _logs.where((l) => 
          l.actionType == AuditActionType.userCreated ||
          l.actionType == AuditActionType.userUpdated ||
          l.actionType == AuditActionType.userDeleted ||
          l.actionType == AuditActionType.userRoleChanged ||
          l.actionType == AuditActionType.userStatusChanged).length,
      'lastFetch': _lastFetch?.toIso8601String(),
    };
  }

  @override
  void dispose() {
    stopRealtimeUpdates();
    super.dispose();
  }
}
