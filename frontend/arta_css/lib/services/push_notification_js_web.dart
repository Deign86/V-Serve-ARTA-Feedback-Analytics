// Web implementation using dart:js_interop

import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('Notification')
external JSObject? get _notification;

bool jsCheckNotificationSupport() {
  if (!kIsWeb) return false;
  try {
    return _notification != null;
  } catch (e) {
    return false;
  }
}

@JS('Notification.permission')
external String get _jsPermission;

String jsGetPermission() {
  if (!kIsWeb) return 'unsupported';
  try {
    return _jsPermission;
  } catch (e) {
    return 'unsupported';
  }
}

@JS('Notification.requestPermission')
external JSPromise<JSString> _jsRequestPermissionNative();

Future<String> jsRequestPermission() async {
  if (!kIsWeb) return 'unsupported';
  try {
    final result = await _jsRequestPermissionNative().toDart;
    return result.toDart;
  } catch (e) {
    return 'denied';
  }
}

@JS('eval')
external void _jsEval(String code);

void jsShowNotification(String title, String body, String icon) {
  if (!kIsWeb) return;
  try {
    // Use eval to create notification - simplest cross-browser approach
    final escapedTitle = title.replaceAll("'", "\\'").replaceAll('\n', '\\n');
    final escapedBody = body.replaceAll("'", "\\'").replaceAll('\n', '\\n');
    final escapedIcon = icon.replaceAll("'", "\\'");
    
    _jsEval('''
      new Notification('$escapedTitle', {
        body: '$escapedBody',
        icon: '$escapedIcon',
        tag: 'arta-alert-${DateTime.now().millisecondsSinceEpoch}',
        requireInteraction: true
      });
    ''');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error creating notification: $e');
    }
  }
}
