import 'dart:async';

class NotificationService {
  /// Fallback stub - does nothing but keeps API stable
  static Future<void> init() async {}
  static Future<String?> getToken() async => null;
  static Future<void> handleForegroundMessage(Map<String, dynamic> message) async {}
  static Future<bool> requestPermission() async => true;
}
