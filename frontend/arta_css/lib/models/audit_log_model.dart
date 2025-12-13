import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of auditable actions in the system
enum AuditActionType {
  // User Management Actions
  userCreated,
  userUpdated,
  userDeleted,
  userStatusChanged,
  userRoleChanged,
  
  // Authentication Actions
  loginSuccess,
  loginFailed,
  logout,
  
  // Survey Configuration Actions
  surveyConfigChanged,
  artaConfigViewed,     // Admin viewed ARTA configuration
  
  // Feedback/Survey Actions
  feedbackDeleted,
  feedbackExported,
  surveySubmitted,      // User submitted a survey
  surveyStarted,        // User started a new survey
  
  // Admin Data Access Actions
  dashboardViewed,      // Admin viewed dashboard
  analyticsViewed,      // Admin viewed detailed analytics
  feedbackBrowserViewed, // Admin browsed feedback data
  userListViewed,       // Admin viewed user list
  auditLogViewed,       // Admin viewed audit logs
  dataExportsViewed,    // Admin viewed data exports screen
  
  // System Actions
  settingsChanged,
}

/// Model representing an audit log entry
class AuditLogEntry {
  final String id;
  final AuditActionType actionType;
  final String actionDescription;
  final DateTime timestamp;
  
  // Actor information (who performed the action)
  final String actorId;
  final String actorName;
  final String actorEmail;
  final String actorRole;
  
  // Target information (what was affected)
  final String? targetId;
  final String? targetType;
  final String? targetName;
  
  // Change details (sanitized - no sensitive data)
  final Map<String, dynamic>? previousValues;
  final Map<String, dynamic>? newValues;
  
  // Additional metadata
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? additionalInfo;

  AuditLogEntry({
    required this.id,
    required this.actionType,
    required this.actionDescription,
    required this.timestamp,
    required this.actorId,
    required this.actorName,
    required this.actorEmail,
    required this.actorRole,
    this.targetId,
    this.targetType,
    this.targetName,
    this.previousValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    this.additionalInfo,
  });

  /// Create from Firestore document
  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] ?? '',
      actionType: _parseActionType(json['actionType'] ?? ''),
      actionDescription: json['actionDescription'] ?? '',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      actorId: json['actorId'] ?? '',
      actorName: json['actorName'] ?? 'Unknown',
      actorEmail: json['actorEmail'] ?? '',
      actorRole: json['actorRole'] ?? '',
      targetId: json['targetId'],
      targetType: json['targetType'],
      targetName: json['targetName'],
      previousValues: json['previousValues'] != null
          ? Map<String, dynamic>.from(json['previousValues'])
          : null,
      newValues: json['newValues'] != null
          ? Map<String, dynamic>.from(json['newValues'])
          : null,
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      additionalInfo: json['additionalInfo'] != null
          ? Map<String, dynamic>.from(json['additionalInfo'])
          : null,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionType': actionType.name,
      'actionDescription': actionDescription,
      'timestamp': Timestamp.fromDate(timestamp),
      'actorId': actorId,
      'actorName': actorName,
      'actorEmail': actorEmail,
      'actorRole': actorRole,
      'targetId': targetId,
      'targetType': targetType,
      'targetName': targetName,
      'previousValues': previousValues,
      'newValues': newValues,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'additionalInfo': additionalInfo,
    };
  }

  /// Parse action type from string
  static AuditActionType _parseActionType(String type) {
    try {
      return AuditActionType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => AuditActionType.settingsChanged,
      );
    } catch (_) {
      return AuditActionType.settingsChanged;
    }
  }

  /// Get human-readable action type display name
  String get actionTypeDisplayName {
    switch (actionType) {
      case AuditActionType.userCreated:
        return 'User Created';
      case AuditActionType.userUpdated:
        return 'User Updated';
      case AuditActionType.userDeleted:
        return 'User Deleted';
      case AuditActionType.userStatusChanged:
        return 'User Status Changed';
      case AuditActionType.userRoleChanged:
        return 'User Role Changed';
      case AuditActionType.loginSuccess:
        return 'Login Success';
      case AuditActionType.loginFailed:
        return 'Login Failed';
      case AuditActionType.logout:
        return 'Logout';
      case AuditActionType.surveyConfigChanged:
        return 'Survey Config Changed';
      case AuditActionType.artaConfigViewed:
        return 'ARTA Config Viewed';
      case AuditActionType.feedbackDeleted:
        return 'Feedback Deleted';
      case AuditActionType.feedbackExported:
        return 'Feedback Exported';
      case AuditActionType.surveySubmitted:
        return 'Survey Submitted';
      case AuditActionType.surveyStarted:
        return 'Survey Started';
      case AuditActionType.dashboardViewed:
        return 'Dashboard Viewed';
      case AuditActionType.analyticsViewed:
        return 'Analytics Viewed';
      case AuditActionType.feedbackBrowserViewed:
        return 'Feedback Browser Viewed';
      case AuditActionType.userListViewed:
        return 'User List Viewed';
      case AuditActionType.auditLogViewed:
        return 'Audit Log Viewed';
      case AuditActionType.dataExportsViewed:
        return 'Data Exports Viewed';
      case AuditActionType.settingsChanged:
        return 'Settings Changed';
    }
  }

  /// Get icon name for the action type
  String get actionIconName {
    switch (actionType) {
      case AuditActionType.userCreated:
        return 'person_add';
      case AuditActionType.userUpdated:
        return 'edit';
      case AuditActionType.userDeleted:
        return 'person_remove';
      case AuditActionType.userStatusChanged:
        return 'toggle_on';
      case AuditActionType.userRoleChanged:
        return 'admin_panel_settings';
      case AuditActionType.loginSuccess:
        return 'login';
      case AuditActionType.loginFailed:
        return 'block';
      case AuditActionType.logout:
        return 'logout';
      case AuditActionType.surveyConfigChanged:
        return 'settings';
      case AuditActionType.artaConfigViewed:
        return 'settings_applications';
      case AuditActionType.feedbackDeleted:
        return 'delete';
      case AuditActionType.feedbackExported:
        return 'download';
      case AuditActionType.surveySubmitted:
        return 'send';
      case AuditActionType.surveyStarted:
        return 'play_arrow';
      case AuditActionType.dashboardViewed:
        return 'dashboard';
      case AuditActionType.analyticsViewed:
        return 'analytics';
      case AuditActionType.feedbackBrowserViewed:
        return 'list_alt';
      case AuditActionType.userListViewed:
        return 'people';
      case AuditActionType.auditLogViewed:
        return 'history';
      case AuditActionType.dataExportsViewed:
        return 'download';
      case AuditActionType.settingsChanged:
        return 'tune';
    }
  }

  /// Get severity level for the action (for UI coloring)
  AuditSeverity get severity {
    switch (actionType) {
      case AuditActionType.userDeleted:
      case AuditActionType.feedbackDeleted:
      case AuditActionType.loginFailed:
        return AuditSeverity.high;
      case AuditActionType.userRoleChanged:
      case AuditActionType.userStatusChanged:
      case AuditActionType.userUpdated:
        return AuditSeverity.medium;
      default:
        return AuditSeverity.low;
    }
  }
}

/// Severity levels for audit events
enum AuditSeverity {
  low,    // Informational events (login, logout, export)
  medium, // Moderate changes (user updates, config changes)
  high,   // Critical changes (deletions, role changes)
}
