import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'api_service.dart';
import 'native_notification_service_native.dart';

// Firebase messaging functions - uses stub on desktop, real impl on Android/iOS
import 'firebase_messaging_desktop.dart' as fbm_service;

// (desktop notifications use LocalNotifier via native wrapper)

class NotificationService {
  static final _uuid = Uuid();
  static Timer? _pollTimer;
  static DateTime? _lastAlertSeen;

  static Future<void> init() async {
    if (kDebugMode) debugPrint('NotificationService(io): init');

    if (Platform.isAndroid) {
      try {
        await fbm_service.requestFirebaseMessagingPermission();
        if (kDebugMode) debugPrint('Android messaging permission requested');
      } catch (e) {
        if (kDebugMode) debugPrint('NotificationService(io) android init error: $e');
      }
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        await NativeNotificationService.instance.initialize();
      } catch (e) {
        if (kDebugMode) debugPrint('Native notification init error: $e');
      }

      // Ensure a persistent device id exists
      final prefs = await SharedPreferences.getInstance();
      var deviceId = prefs.getString('device_token');
      if (deviceId == null) {
        deviceId = _uuid.v4();
        await prefs.setString('device_token', deviceId);
        if (kDebugMode) debugPrint('Generated new desktop device id: $deviceId');
      }

      // Register device with backend (best-effort)
      try {
        await ApiService.registerDeviceToken(deviceId: deviceId, platform: 'desktop', token: deviceId);
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to register desktop device token: $e');
      }

      // Start polling alerts every 30 seconds
      _startPollingAlerts();
    }
  }

  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      try {
        return await fbm_service.requestFirebaseMessagingPermission();
      } catch (e) {
        if (kDebugMode) debugPrint('requestPermission android error: $e');
        return false;
      }
    }

    // Desktop and other platforms consider permission granted by default
    return true;
  }

  static Future<String?> getToken() async {
    if (Platform.isAndroid) {
      try {
        final token = await fbm_service.getFirebaseMessagingToken();
        return token;
      } catch (e) {
        if (kDebugMode) debugPrint('NotificationService(io) android getToken error: $e');
        return null;
      }
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
    final title = message['title'] ?? 'Notification';
    final body = message['body'] ?? '';

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        await NativeNotificationService.instance.showNotification(title: title, body: body);
      } catch (e) {
        if (kDebugMode) debugPrint('NotificationService(io) desktop show error: $e');
      }
    } else if (Platform.isAndroid) {
      if (kDebugMode) debugPrint('NotificationService(io) android foreground: $message');
    }
  }

  static void _startPollingAlerts() {
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
        await NativeNotificationService.instance.showNotification(title: title, body: body);
        if (_lastAlertSeen == null || created.isAfter(_lastAlertSeen!)) _lastAlertSeen = created;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Fetch alerts error: $e');
    }
  }
}

/// Background handler for Android messages - re-export from conditional import
final firebaseMessagingBackgroundHandler = fbm_service.firebaseMessagingBackgroundHandler;
