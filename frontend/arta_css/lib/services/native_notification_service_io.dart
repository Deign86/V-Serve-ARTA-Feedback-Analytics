// IO platform native notification service
// This file is loaded on all dart.library.io platforms (desktop + mobile)
// On desktop: Uses local_notifier for system toast notifications
// On mobile: Returns unsupported (use PushNotificationService instead)

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

/// Native notification service for IO platforms
/// On desktop (Windows/macOS/Linux): Uses local_notifier for system notifications  
/// On mobile (Android/iOS): Returns unsupported (use PushNotificationService instead)
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
  bool get hasPermission => _isSupported;
  String get permissionStatus => _permissionStatus;
  
  /// Check if current platform is desktop
  static bool get _isDesktop {
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (_isDesktop) {
      // Desktop platform - initialize local_notifier
      try {
        await localNotifier.setup(
          appName: 'V-Serve',
          shortcutPolicy: ShortcutPolicy.requireCreate,
        );
        _isSupported = true;
        _isEnabled = true;
        _permissionStatus = 'granted';
        if (kDebugMode) {
          debugPrint('NativeNotificationService: Initialized for desktop with local_notifier');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('NativeNotificationService: Error initializing local_notifier: $e');
        }
        _isSupported = false;
        _permissionStatus = 'error';
      }
    } else {
      // Mobile platform - native desktop notifications not supported
      _isSupported = false;
      _permissionStatus = 'unsupported';
      if (kDebugMode) {
        debugPrint('NativeNotificationService: Mobile platform - use push notifications');
      }
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> enableNotifications(String userId, [String? email]) async {
    if (!_isSupported) return false;
    _isEnabled = true;
    notifyListeners();
    return true;
  }

  Future<void> disableNotifications([String? userId]) async {
    _isEnabled = false;
    notifyListeners();
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isEnabled || !_isSupported) return;

    // On mobile, this is a no-op
    if (!_isDesktop) return;
    
    // Desktop notification using local_notifier
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
      };

      notification.onClose = (reason) {
        if (kDebugMode) {
          debugPrint('NativeNotificationService: Notification closed - $title (reason: $reason)');
        }
      };

      await notification.show();
      
      if (kDebugMode) {
        debugPrint('NativeNotificationService: Notification sent - $title');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NativeNotificationService: Error showing notification: $e');
      }
    }
  }

  Future<void> clearAllNotifications() async {
    // Not implemented - local_notifier doesn't have a clear all method
  }

  Future<bool> requestPermission() async {
    if (_isDesktop) return true;
    return false;
  }

  /// Show a local notification (for testing/admin)
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await showNotification(title: title, body: body);
  }

  /// Show a custom notification
  Future<void> showCustomNotification({
    required String title,
    required String body,
  }) async {
    await showNotification(title: title, body: body);
  }
}
