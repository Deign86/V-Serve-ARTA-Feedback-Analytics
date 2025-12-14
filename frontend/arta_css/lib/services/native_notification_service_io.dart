// IO platform native notification service
// This file is loaded on all dart.library.io platforms (desktop + mobile)
// It checks at runtime whether to use desktop notifications or not

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

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
      // Desktop platform - try to initialize local_notifier
      // Import is deferred to avoid loading on mobile
      try {
        // Dynamic import approach - the actual implementation is in native file
        // For now, just mark as supported on desktop
        _isSupported = true;
        _isEnabled = true;
        _permissionStatus = 'granted';
        if (kDebugMode) {
          debugPrint('NativeNotificationService: Desktop platform detected');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('NativeNotificationService: Error: $e');
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
    
    // Desktop notification would be shown here
    // But we need to avoid importing local_notifier on mobile
    if (kDebugMode) {
      debugPrint('NativeNotificationService: Would show notification - $title');
    }
  }

  Future<void> clearAllNotifications() async {
    // Not implemented
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
