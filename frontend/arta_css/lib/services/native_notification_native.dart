// Native implementation for Windows/macOS/Linux notifications

import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

bool _isInitialized = false;

Future<void> initialize() async {
  if (_isInitialized) return;
  
  try {
    await localNotifier.setup(
      appName: 'ARTA CSS',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
    _isInitialized = true;
    
    if (kDebugMode) {
      debugPrint('NativeNotifier: Initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('NativeNotifier: Error initializing: $e');
    }
  }
}

Future<void> showNotification({
  required String title,
  required String body,
  required String id,
}) async {
  if (!_isInitialized) {
    await initialize();
  }
  
  try {
    final notification = LocalNotification(
      identifier: id,
      title: title,
      body: body,
    );
    
    // Add click handler
    notification.onShow = () {
      if (kDebugMode) {
        debugPrint('NativeNotifier: Notification shown - $title');
      }
    };
    
    notification.onClick = () {
      if (kDebugMode) {
        debugPrint('NativeNotifier: Notification clicked - $title');
      }
      // You could add navigation logic here
    };
    
    notification.onClose = (reason) {
      if (kDebugMode) {
        debugPrint('NativeNotifier: Notification closed - $title (reason: $reason)');
      }
    };
    
    await notification.show();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('NativeNotifier: Error showing notification: $e');
    }
  }
}
