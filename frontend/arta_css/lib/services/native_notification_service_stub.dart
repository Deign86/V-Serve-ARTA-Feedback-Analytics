// Stub for native_notification_service.dart - used on platforms where Firebase is not available
// This allows the code to compile without firebase dependencies

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Stub NativeNotificationService for platforms without native notification support
class NativeNotificationService extends ChangeNotifier {
  static final NativeNotificationService _instance = NativeNotificationService._internal();
  factory NativeNotificationService() => _instance;
  NativeNotificationService._internal();

  static NativeNotificationService get instance => _instance;

  bool _isEnabled = false;
  bool _isSupported = false;
  bool _isInitialized = false;

  bool get isEnabled => _isEnabled;
  bool get isSupported => _isSupported;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isSupported = false;
    _isInitialized = true;
    if (kDebugMode) {
      debugPrint('NativeNotificationService: Stub initialized (Firebase not available)');
    }
    notifyListeners();
  }

  /// Enable notifications for the current user
  Future<bool> enableNotifications(String userId) async {
    // Not supported without Firebase
    return false;
  }

  /// Disable notifications
  Future<void> disableNotifications() async {
    _isEnabled = false;
  }

  /// Show a notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Not supported without Firebase
  }

  /// Show a custom notification (can be called externally)
  Future<void> showCustomNotification({
    required String title,
    required String body,
  }) async {
    // Not supported without Firebase
    if (kDebugMode) {
      debugPrint('NativeNotificationService: showCustomNotification not supported (stub)');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
