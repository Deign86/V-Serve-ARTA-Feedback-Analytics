// Stub for alert_service.dart - used on platforms where Firebase is not available
// This allows the code to compile without firebase dependencies

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/audit_log_model.dart';

/// Severity levels for alerts
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

/// Model for an alert
class AlertEntry {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final String? sourceLogId;
  final bool isRead;
  final bool emailSent;
  
  AlertEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.sourceLogId,
    this.isRead = false,
    this.emailSent = false,
  });
  
  factory AlertEntry.fromJson(Map<String, dynamic> json) {
    return AlertEntry(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Alert',
      message: json['message'] ?? '',
      severity: _parseSeverity(json['severity']),
      timestamp: _parseTimestamp(json['timestamp']),
      sourceLogId: json['sourceLogId'],
      isRead: json['isRead'] ?? false,
      emailSent: json['emailSent'] ?? false,
    );
  }
  
  static AlertSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return AlertSeverity.critical;
      case 'high':
        return AlertSeverity.high;
      case 'medium':
        return AlertSeverity.medium;
      default:
        return AlertSeverity.low;
    }
  }
  
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is Map) {
      if (value['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch((value['_seconds'] as int) * 1000);
      }
      if (value['seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch((value['seconds'] as int) * 1000);
      }
    }
    return DateTime.now();
  }
  
  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    'severity': severity.name,
    'timestamp': timestamp.toIso8601String(),
    'sourceLogId': sourceLogId,
    'isRead': isRead,
    'emailSent': emailSent,
  };
}

/// Stub AlertService for native desktop platforms
/// On these platforms, alerts would be fetched via HTTP if needed
class AlertService extends ChangeNotifier {
  // ignore: unused_field - kept for API compatibility with real AlertService
  static const String _alertsCollection = 'alerts';
  
  final List<AlertEntry> _alerts = [];
  final bool _isLoading = false;
  
  List<AlertEntry> get alerts => _alerts;
  List<AlertEntry> get unreadAlerts => _alerts.where((a) => !a.isRead).toList();
  int get unreadCount => unreadAlerts.length;
  bool get isLoading => _isLoading;
  
  static const List<AuditActionType> highSeverityActions = [
    AuditActionType.loginFailed,
    AuditActionType.userDeleted,
    AuditActionType.feedbackDeleted,
    AuditActionType.userStatusChanged,
    AuditActionType.userRoleChanged,
  ];
  
  Future<void> createAlertFromAuditLog(AuditLogEntry log) async {
    // Stub - no-op on native desktop
    if (kDebugMode) {
      debugPrint('AlertService: Stub - createAlertFromAuditLog called');
    }
  }
  
  Future<void> fetchAlerts({int limit = 50}) async {
    // Stub - no-op on native desktop
    if (kDebugMode) {
      debugPrint('AlertService: Stub - fetchAlerts called');
    }
  }
  
  Future<void> markAsRead(String alertId) async {}
  
  Future<void> markAllAsRead() async {}
  
  Future<void> deleteAlert(String alertId) async {}
  
  @override
  void dispose() {
    super.dispose();
  }
}
