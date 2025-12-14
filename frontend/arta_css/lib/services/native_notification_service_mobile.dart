// Mobile notification service stub for Android/iOS
// Mobile platforms use push notifications instead of native desktop notifications

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Mobile stub for NativeNotificationService
/// On mobile platforms, use PushNotificationService for notifications instead
class NativeNotificationService extends ChangeNotifier {
  static final NativeNotificationService _instance = NativeNotificationService._internal();
  factory NativeNotificationService() => _instance;
  NativeNotificationService._internal();

  static NativeNotificationService get instance => _instance;

  bool _isEnabled = false;
  bool _isSupported = false;
  bool _isInitialized = false;
  String _permissionStatus = 'unsupported';

  bool get isEnabled => _isEnabled;
  bool get isSupported => _isSupported;
  bool get isInitialized => _isInitialized;
  bool get hasPermission => false;
  String get permissionStatus => _permissionStatus;

  Future<void> initialize() async {
    // On mobile, native desktop notifications are not supported
    // Use push notifications via PushNotificationService instead
    _isSupported = false;
    _isInitialized = true;
    _permissionStatus = 'unsupported';
    if (kDebugMode) {
      debugPrint('NativeNotificationService: Mobile platform - use push notifications instead');
    }
    notifyListeners();
  }

  /// Enable notifications for the current user
  Future<bool> enableNotifications(String userId, [String? email]) async {
    // Not supported on mobile - use PushNotificationService
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
    // Not supported on mobile - use PushNotificationService instead
    if (kDebugMode) {
      debugPrint('NativeNotificationService: Not supported on mobile');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    // Not supported on mobile
  }

  /// Request permission for notifications (always false on mobile for this service)
  Future<bool> requestPermission() async {
    return false;
  }
}
