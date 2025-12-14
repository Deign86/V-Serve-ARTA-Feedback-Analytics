// Stub for push_notification_service.dart - used on platforms where Firebase is not available
// This allows the code to compile without firebase dependencies

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Stub PushNotificationService for native desktop platforms
/// Push notifications are web-only, so this is a no-op on native platforms
class PushNotificationService extends ChangeNotifier {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static PushNotificationService get instance => _instance;

  bool _isEnabled = false;
  bool _isSupported = false;
  bool _isInitialized = false;
  String? _permissionStatus;

  bool get isEnabled => _isEnabled;
  bool get isSupported => _isSupported;
  bool get isInitialized => _isInitialized;
  String? get permissionStatus => _permissionStatus;
  bool get hasPermission => false;

  Future<void> initialize() async {
    _isSupported = false;
    _isInitialized = true;
    if (kDebugMode) {
      debugPrint('PushNotificationService: Not supported on native desktop platforms');
    }
    notifyListeners();
  }

  Future<bool> requestPermission() async => false;

  /// Enable push notifications for the current user
  Future<bool> enableNotifications(String userId, String userEmail) async {
    // Not supported on native platforms
    return false;
  }

  /// Disable push notifications
  Future<void> disableNotifications(String userId) async {
    // Not supported on native platforms
  }

  /// Show a local notification (for immediate feedback)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? icon,
  }) async {
    // Not supported on native platforms
    if (kDebugMode) {
      debugPrint('PushNotificationService: showLocalNotification not supported on native platforms');
    }
  }

  /// Queue a push notification
  Future<void> queuePushNotification({
    required String title,
    required String body,
    required String severity,
    String? alertId,
  }) async {
    // Not supported on native platforms
  }

  @override
  void dispose() {
    super.dispose();
  }
}
