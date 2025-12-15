import 'dart:async';
import 'package:flutter/foundation.dart';
import 'push_notification_js_web.dart' as jsweb;
import 'api_config.dart';

class PushNotificationService extends ChangeNotifier {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static PushNotificationService get instance => _instance;

  bool _isSupported = false;
  bool _isInitialized = false;
  bool _isEnabled = false;
  String? _permissionStatus;

  bool get isSupported => _isSupported;
  bool get isInitialized => _isInitialized;
  bool get isEnabled => _isEnabled;
  String? get permissionStatus => _permissionStatus;
  bool get hasPermission => _permissionStatus == 'granted';

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isSupported = jsweb.jsCheckNotificationSupport();
    _permissionStatus = jsweb.jsGetPermission();
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> requestPermission() async {
    final result = await jsweb.jsRequestPermission();
    _permissionStatus = result;
    notifyListeners();
    return result == 'granted';
  }

  /// Enable notifications for given user (will register SW, subscribe and POST to backend)
  Future<bool> enableNotifications(String userId, String userEmail) async {
    if (!kIsWeb) return false;
    try {
      if (_permissionStatus != 'granted') {
        final granted = await requestPermission();
        if (!granted) return false;
      }

      final baseUrl = await ApiConfig.getBaseUrl();

      // Get VAPID public key from backend
      final client = ApiClient();
      final resp = await client.get('/push/vapidPublicKey');
      String? publicKey;
      if (resp.isSuccess) {
        publicKey = resp.data?['publicKey'] as String?;
      }

      final ok = await jsweb.jsSubscribeAndSend(baseUrl, userId, userEmail, publicKey ?? '');
      if (ok) {
        _isEnabled = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('enableNotifications error: $e');
      return false;
    }
  }

  Future<void> disableNotifications(String userId) async {
    try {
      final client = ApiClient();
      await client.post('/push/unsubscribe', body: { 'userId': userId });
      _isEnabled = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('disableNotifications error: $e');
    }
  }

  Future<void> showLocalNotification({required String title, required String body, String? icon}) async {
    jsweb.jsShowNotification(title, body, icon ?? '');
  }

}
