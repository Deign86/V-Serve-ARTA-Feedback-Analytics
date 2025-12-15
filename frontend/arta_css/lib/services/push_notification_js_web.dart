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

/// Subscribe the browser to PushManager and POST the subscription to backend
Future<bool> jsSubscribeAndSend(String baseUrl, String userId, String email, String publicKey) async {
  if (!kIsWeb) return false;
  try {
    final escapedBase = baseUrl.replaceAll("'", "\\'");
    final escapedUser = (userId ?? '').replaceAll("'", "\\'");
    final escapedEmail = (email ?? '').replaceAll("'", "\\'");
    final escapedKey = (publicKey ?? '').replaceAll("'", "\\'");

    _jsEval('''(async () => {
      function urlBase64ToUint8Array(base64String) {
        const padding = '='.repeat((4 - base64String.length % 4) % 4);
        const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
        const rawData = atob(base64);
        const outputArray = new Uint8Array(rawData.length);
        for (let i = 0; i < rawData.length; ++i) {
          outputArray[i] = rawData.charCodeAt(i);
        }
        return outputArray;
      }

      try {
        if (!('serviceWorker' in navigator)) return;
        const reg = await navigator.serviceWorker.register('/sw_push.js');
        const existing = await reg.pushManager.getSubscription();
        if (existing) {
          try {
            await fetch('${escapedBase}/push/subscribe', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ userId: '${escapedUser}', email: '${escapedEmail}', subscription: existing.toJSON() })
            });
            return;
          } catch (e) { console.error('post existing sub', e); }
        }

        const applicationServerKey = urlBase64ToUint8Array('${escapedKey}');
        const sub = await reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey });
        try {
          await fetch('${escapedBase}/push/subscribe', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ userId: '${escapedUser}', email: '${escapedEmail}', subscription: sub.toJSON() })
          });
        } catch (e) { console.error('post new sub', e); }
      } catch (err) {
        console.error('subscribe flow error', err);
      }
    })();
    ''');

    return true;
  } catch (e) {
    if (kDebugMode) debugPrint('jsSubscribeAndSend error: $e');
    return false;
  }
}
