// Native notification service for Windows/macOS/Linux
// Uses local_notifier package for system toast notifications

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

/// Native notification service for desktop platforms (Windows, macOS, Linux)
/// Uses system toast notifications via local_notifier package
class NativeNotificationService extends ChangeNotifier {
  static final NativeNotificationService _instance = NativeNotificationService._internal();
  factory NativeNotificationService() => _instance;
  NativeNotificationService._internal();

  static NativeNotificationService get instance => _instance;

  bool _isEnabled = true; // Desktop notifications enabled by default
  bool _isSupported = true; // Desktop always supports native notifications
  bool _isInitialized = false;
  String _permissionStatus = 'granted'; // Desktop doesn't need permission

  bool get isEnabled => _isEnabled;
  bool get isSupported => _isSupported;
  bool get isInitialized => _isInitialized;
  bool get hasPermission => true; // Desktop always has permission
  String get permissionStatus => _permissionStatus;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await localNotifier.setup(
        appName: 'V-Serve',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      _isInitialized = true;
      _isSupported = true;
      _permissionStatus = 'granted';

      if (kDebugMode) {
        debugPrint('NativeNotificationService: Initialized successfully for desktop');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NativeNotificationService: Error initializing: $e');
      }
      _isSupported = false;
      _permissionStatus = 'error';
    }
    
    notifyListeners();
  }

  /// Enable notifications for the current user
  Future<bool> enableNotifications(String userId, [String? email]) async {
    _isEnabled = true;
    notifyListeners();
    return true;
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
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isEnabled) {
      if (kDebugMode) {
        debugPrint('NativeNotificationService: Notifications disabled');
      }
      return;
    }

    try {
      final notification = LocalNotification(
        identifier: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
      );

      notification.onShow = () {
        if (kDebugMode) {
          debugPrint('NativeNotificationService: Notification shown - $title');
        }
      };

      notification.onClick = () {
        if (kDebugMode) {
          debugPrint('NativeNotificationService: Notification clicked - $title');
        }
        // Could add navigation logic here
      };

      notification.onClose = (reason) {
        if (kDebugMode) {
          debugPrint('NativeNotificationService: Notification closed - $title');
        }
      };

      await notification.show();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NativeNotificationService: Error showing notification: $e');
      }
    }
  }

  /// Show a custom notification
  Future<void> showCustomNotification({
    required String title,
    required String body,
  }) async {
    await showNotification(title: title, body: body);
  }

  /// Show a local notification (for testing)
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await showNotification(title: title, body: body);
  }
}
