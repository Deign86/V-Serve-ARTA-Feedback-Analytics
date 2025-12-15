import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_config.dart';

class ApiService {
  /// Register device token with backend
  /// body: { deviceId, platform, token }
  static Future<bool> registerDeviceToken({required String deviceId, required String platform, required String token}) async {
    try {
      final client = ApiClient();
      final resp = await client.post('/api/register-token', body: {
        'deviceId': deviceId,
        'platform': platform,
        'token': token,
      });
      return resp.isSuccess;
    } catch (e) {
      if (kDebugMode) debugPrint('ApiService.registerDeviceToken error: $e');
      return false;
    }
  }

  /// Unregister device token from backend (disable push notifications)
  /// body: { userId }
  static Future<bool> unregisterDeviceToken({required String userId}) async {
    try {
      final client = ApiClient();
      final resp = await client.post('/push/unsubscribe', body: {
        'userId': userId,
      });
      return resp.isSuccess;
    } catch (e) {
      if (kDebugMode) debugPrint('ApiService.unregisterDeviceToken error: $e');
      return false;
    }
  }
}
