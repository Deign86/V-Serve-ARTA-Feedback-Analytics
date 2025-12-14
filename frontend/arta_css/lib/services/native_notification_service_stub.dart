// Stub for native_notification_service.dart - used on web platform
// Desktop platforms use the native implementation

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Stub NativeNotificationService for web platform
/// Desktop uses native_notification_native.dart via conditional import
class NativeNotificationService extends ChangeNotifier {
  static final NativeNotificationService _instance = NativeNotificationService._internal();
  factory NativeNotificationService() => _instance;
  NativeNotificationService._internal();

  static NativeNotificationService get instance => _instance;

  bool _isEnabled = false;
  bool _isSupported = false;
  bool _isInitialized = false;
  String _permissionStatus = 'unknown';

  bool get isEnabled => _isEnabled;
  bool get isSupported => _isSupported;
  bool get isInitialized => _isInitialized;
  bool get hasPermission => _isSupported; // Desktop always has permission
  String get permissionStatus => _permissionStatus;

  Future<void> initialize() async {
    // On web, native notifications are not supported (use push notifications instead)
    _isSupported = false;
    _isInitialized = true;
    _permissionStatus = 'unsupported';
    if (kDebugMode) {
      debugPrint('NativeNotificationService: Stub initialized (web platform - use push notifications)');
    }
    notifyListeners();
  }

  /// Enable notifications for the current user
  Future<bool> enableNotifications(String userId, [String? email]) async {
    // Not supported on web
    return false;
  }

  /// Disable notifications
  Future<void> disableNotifications([String? userId]) async {
    _isEnabled = false;
    notifyListeners();
  }

  /// Show a notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Not supported on web - use PushNotificationService instead
    if (kDebugMode) {
      debugPrint('NativeNotificationService: Not supported on web');
    }
  }

  /// Show a custom notification
  Future<void> showCustomNotification({
    required String title,
    required String body,
  }) async {
    // Not supported on web
    if (kDebugMode) {
      debugPrint('NativeNotificationService: showCustomNotification not supported on web');
    }
  }

  /// Show a local notification (for testing)
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await showNotification(title: title, body: body);
  }
}
