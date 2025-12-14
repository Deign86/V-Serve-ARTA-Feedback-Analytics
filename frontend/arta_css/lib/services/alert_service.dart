import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  factory AlertEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlertEntry(
      id: doc.id,
      title: data['title'] ?? 'Alert',
      message: data['message'] ?? '',
      severity: _parseSeverity(data['severity']),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sourceLogId: data['sourceLogId'],
      isRead: data['isRead'] ?? false,
      emailSent: data['emailSent'] ?? false,
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
  
  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    'severity': severity.name,
    'timestamp': FieldValue.serverTimestamp(),
    'sourceLogId': sourceLogId,
    'isRead': isRead,
    'emailSent': emailSent,
  };
}

/// Service for managing alerts and sending notifications for high-severity events
class AlertService extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  static const String _alertsCollection = 'alerts';
  static const String _emailQueueCollection = 'email_queue';
  
  List<AlertEntry> _alerts = [];
  bool _isLoading = false;
  
  List<AlertEntry> get alerts => _alerts;
  List<AlertEntry> get unreadAlerts => _alerts.where((a) => !a.isRead).toList();
  int get unreadCount => unreadAlerts.length;
  bool get isLoading => _isLoading;
  
  /// Audit action types that trigger HIGH severity alerts
  static const List<AuditActionType> highSeverityActions = [
    AuditActionType.loginFailed,
    AuditActionType.userDeleted,
    AuditActionType.feedbackDeleted,
    AuditActionType.userStatusChanged,
    AuditActionType.userRoleChanged,
  ];
  
  /// Create an alert from an audit log entry
  Future<void> createAlertFromAuditLog(AuditLogEntry log) async {
    // Determine severity based on action type
    final severity = _getSeverityForAction(log.actionType);
    
    // Only create alerts for HIGH or CRITICAL severity
    if (severity == AlertSeverity.low || severity == AlertSeverity.medium) {
      return;
    }
    
    try {
      final alert = AlertEntry(
        id: '',
        title: _getTitleForAction(log.actionType),
        message: log.actionDescription,
        severity: severity,
        timestamp: log.timestamp,
        sourceLogId: log.id,
      );
      
      // Save alert to Firestore
      final docRef = await _firestore.collection(_alertsCollection).add(alert.toJson());
      
      if (kDebugMode) {
        debugPrint('AlertService: Created ${severity.name} severity alert: ${alert.title}');
      }
      
      // Queue email notification for admin users
      if (severity == AlertSeverity.high || severity == AlertSeverity.critical) {
        await _queueEmailNotification(docRef.id, alert);
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AlertService: Error creating alert: $e');
      }
    }
  }
  
  /// Queue an email notification for admin users
  Future<void> _queueEmailNotification(String alertId, AlertEntry alert) async {
    try {
      // Get all active admin users
      final adminsSnapshot = await _firestore
          .collection('system_users')
          .where('role', isEqualTo: 'Administrator')
          .where('status', isEqualTo: 'Active')
          .get();
      
      if (adminsSnapshot.docs.isEmpty) {
        if (kDebugMode) {
          debugPrint('AlertService: No active admin users to notify');
        }
        return;
      }
      
      // Queue email for each admin
      for (final adminDoc in adminsSnapshot.docs) {
        final adminData = adminDoc.data();
        final email = adminData['email'] as String?;
        
        if (email == null || email.isEmpty) continue;
        
        await _firestore.collection(_emailQueueCollection).add({
          'to': email,
          'subject': '[ARTA CSS Alert] ${alert.severity.name.toUpperCase()}: ${alert.title}',
          'body': _buildEmailBody(alert, adminData['name'] ?? 'Admin'),
          'alertId': alertId,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'retries': 0,
        });
        
        if (kDebugMode) {
          debugPrint('AlertService: Queued email notification to $email');
        }
      }
      
      // Mark alert as email sent
      await _firestore.collection(_alertsCollection).doc(alertId).update({
        'emailSent': true,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AlertService: Error queueing email notification: $e');
      }
    }
  }
  
  String _buildEmailBody(AlertEntry alert, String adminName) {
    return '''
Dear $adminName,

A ${alert.severity.name.toUpperCase()} severity event has occurred in the ARTA Client Satisfaction Survey system.

Event: ${alert.title}
Details: ${alert.message}
Time: ${alert.timestamp.toLocal()}

Please review the audit logs in the admin dashboard for more details.

---
ARTA CSS Alert System
City Government of Valenzuela
''';
  }
  
  AlertSeverity _getSeverityForAction(AuditActionType actionType) {
    switch (actionType) {
      // Critical severity - immediate attention required
      case AuditActionType.userDeleted:
      case AuditActionType.feedbackDeleted:
        return AlertSeverity.critical;
      
      // High severity - security concern
      case AuditActionType.loginFailed:
      case AuditActionType.userStatusChanged:
      case AuditActionType.userRoleChanged:
        return AlertSeverity.high;
      
      // Medium severity - notable changes
      case AuditActionType.surveyConfigChanged:
      case AuditActionType.settingsChanged:
      case AuditActionType.userCreated:
      case AuditActionType.userUpdated:
        return AlertSeverity.medium;
      
      // Low severity - normal operations
      default:
        return AlertSeverity.low;
    }
  }
  
  String _getTitleForAction(AuditActionType actionType) {
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
      case AuditActionType.surveyConfigChanged:
        return 'Survey Configuration Changed';
      case AuditActionType.settingsChanged:
        return 'System Settings Changed';
      default:
        return 'System Event';
    }
  }
  
  /// Fetch alerts from Firestore
  Future<void> fetchAlerts({int limit = 50}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await _firestore
          .collection(_alertsCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      _alerts = snapshot.docs.map((doc) => AlertEntry.fromFirestore(doc)).toList();
      
      if (kDebugMode) {
        debugPrint('AlertService: Fetched ${_alerts.length} alerts');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AlertService: Error fetching alerts: $e');
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// Mark an alert as read
  Future<void> markAsRead(String alertId) async {
    try {
      await _firestore.collection(_alertsCollection).doc(alertId).update({
        'isRead': true,
      });
      
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index] = AlertEntry(
          id: _alerts[index].id,
          title: _alerts[index].title,
          message: _alerts[index].message,
          severity: _alerts[index].severity,
          timestamp: _alerts[index].timestamp,
          sourceLogId: _alerts[index].sourceLogId,
          isRead: true,
          emailSent: _alerts[index].emailSent,
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AlertService: Error marking alert as read: $e');
      }
    }
  }
  
  /// Mark all alerts as read
  Future<void> markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      for (final alert in unreadAlerts) {
        batch.update(
          _firestore.collection(_alertsCollection).doc(alert.id),
          {'isRead': true},
        );
      }
      await batch.commit();
      
      _alerts = _alerts.map((a) => AlertEntry(
        id: a.id,
        title: a.title,
        message: a.message,
        severity: a.severity,
        timestamp: a.timestamp,
        sourceLogId: a.sourceLogId,
        isRead: true,
        emailSent: a.emailSent,
      )).toList();
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AlertService: Error marking all alerts as read: $e');
      }
    }
  }
}
