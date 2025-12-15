import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

// Firebase messaging import for Android
import 'package:firebase_messaging/firebase_messaging.dart' as fbm;

// Windows notification package (used only when Platform.isWindows)
import 'package:windows_notification/windows_notification.dart' as win_notif;

class NotificationService {
  static final _uuid = Uuid();
  static Timer? _pollTimer;
  static DateTime? _lastAlertSeen;

  static Future<void> init() async {
    if (kDebugMode) debugPrint('NotificationService(io): init');

    if (Platform.isAndroid) {
      try {
        await fbm.FirebaseMessaging.instance.requestPermission();
        if (kDebugMode) debugPrint('Android messaging permission requested');
      } catch (e) {
        if (kDebugMode) debugPrint('NotificationService(io) android init error: $e');
      }
    }

    if (Platform.isWindows) {
      // Ensure a persistent device id exists
      final prefs = await SharedPreferences.getInstance();
      var deviceId = prefs.getString('device_token');
      if (deviceId == null) {
        deviceId = _uuid.v4();
        await prefs.setString('device_token', deviceId);
        if (kDebugMode) debugPrint('Generated new Windows device id: $deviceId');
      }

      // Register device with backend (best-effort)
      try {
        final client = ApiClient();
        await client.post('/api/register-token', body: {
          'deviceId': deviceId,
          'platform': 'windows',
          'token': deviceId,
        });
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to register windows device token: $e');
      }

      // Start polling alerts every 30 seconds
      _startPollingAlerts();
    }
  }

  static Future<String?> getToken() async {
    if (Platform.isAndroid) {
      try {
        final token = await fbm.FirebaseMessaging.instance.getToken();
        return token;
      } catch (e) {
        if (kDebugMode) debugPrint('NotificationService(io) android getToken error: $e');
        return null;
      }
    }

    if (Platform.isWindows) {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString('device_token');
      if (id == null) {
        id = _uuid.v4();
        await prefs.setString('device_token', id);
      }
      return id;
    }

    return null;
  }

  static Future<void> handleForegroundMessage(Map<String, dynamic> message) async {
    if (Platform.isWindows) {
      try {
        await _showWindowsToast(
          title: message['title'] ?? 'Notification',
          body: message['body'] ?? '',
        );
      } catch (e) {
        if (kDebugMode) debugPrint('NotificationService(io) windows show error: $e');
      }
    } else if (Platform.isAndroid) {
      if (kDebugMode) debugPrint('NotificationService(io) android foreground: $message');
    }
  }

  static Future<void> _showWindowsToast({required String title, required String body}) async {
    try {
      // Using windows_notification package to show a toast
      await win_notif.WindowsNotification.show(
        title: title,
        body: body,
        // Optionally set icon and actions here
      );
    } catch (e) {
      if (kDebugMode) debugPrint('WindowsNotification show error: $e');
    }
  }

  static void _startPollingAlerts() {
    // Avoid multiple timers
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _fetchAndShowAlerts();
    });
  }

  static Future<void> _fetchAndShowAlerts() async {
    try {
      final client = ApiClient();
      final resp = await client.get('/api/alerts');
      if (!resp.isSuccess || resp.data == null) return;

      final items = resp.data!['items'] as List<dynamic>? ?? [];
      for (final it in items) {
        final created = DateTime.tryParse(it['createdAt'] ?? '') ?? DateTime.now();
        if (_lastAlertSeen != null && created.isBefore(_lastAlertSeen!)) continue;
        final title = it['title'] ?? 'Alert';
        final body = it['body'] ?? '';
        await _showWindowsToast(title: title, body: body);
        if (_lastAlertSeen == null || created.isAfter(_lastAlertSeen!)) _lastAlertSeen = created;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Fetch alerts error: $e');
    }
  }
}

// Background handler helper - needed for Android background messages (no-op here)
Future<void> FirebaseMessagingBackgroundHandler(RemoteMessage? message) async {
  if (kDebugMode) debugPrint('Background message received: ${message?.messageId}');
}
