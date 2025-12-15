import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
// No extra dependencies required here

class NotificationService {
  static final FirebaseMessaging _fm = FirebaseMessaging.instance;

  /// Initialize Firebase Messaging for web
  static Future<void> init() async {
    try {
      // Firebase initialization should be done in main.dart; we attempt safe init if needed
      if (Firebase.apps.isEmpty) {
        if (kDebugMode) debugPrint('NotificationService(web): Firebase apps empty - skipping init here');
      }

      // Request permission if not granted
      final status = await _fm.requestPermission(alert: true, badge: true, sound: true);
      if (kDebugMode) debugPrint('NotificationService(web): permission=${status.authorizationStatus}');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) debugPrint('FM onMessage: ${message.notification?.title}');
      });

      // Background messages handled by service worker
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService(web) init error: $e');
    }
  }

  /// Get FCM token (web requires vapid key when requesting token directly)
  static Future<String?> getToken({String? vapidKey}) async {
    try {
      final token = await _fm.getToken(vapidKey: vapidKey);
      return token;
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService(web) getToken error: $e');
      return null;
    }
  }

  static Future<void> handleForegroundMessage(Map<String, dynamic> message) async {
    // Optionally show an in-app banner
    if (kDebugMode) debugPrint('NotificationService(web) foreground message: $message');
  }

  static Future<bool> requestPermission() async {
    final status = await _fm.requestPermission(alert: true, badge: true, sound: true);
    return status.authorizationStatus == AuthorizationStatus.authorized ||
        status.authorizationStatus == AuthorizationStatus.provisional;
  }
}
