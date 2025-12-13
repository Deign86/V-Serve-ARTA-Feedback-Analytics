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
  
  // Feedback Actions
  feedbackDeleted,
  feedbackExported,
  
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
      case AuditActionType.feedbackDeleted:
        return 'Feedback Deleted';
      case AuditActionType.feedbackExported:
        return 'Feedback Exported';
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
      case AuditActionType.feedbackDeleted:
        return 'delete';
      case AuditActionType.feedbackExported:
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
