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

      await _firestore.collection(_collectionName).add(logEntry);
      debugPrint('AuditLogService: Logged action - ${actionType.name}: $actionDescription');
      return true;
    } catch (e) {
      debugPrint('AuditLogService: Error logging action: $e');
      return false;
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
      'totalLogs': _logs.length,
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
