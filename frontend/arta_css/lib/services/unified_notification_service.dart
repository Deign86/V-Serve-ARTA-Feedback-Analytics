import 'dart:async';
import 'package:flutter/foundation.dart';
import 'push_notification_service_stub.dart';
// Native notifications: stub for web, native implementation for desktop
import 'native_notification_service_stub.dart'
    if (dart.library.io) 'native_notification_service_native.dart';

/// Unified notification service that automatically uses the right implementation
/// 
/// On Web: Uses PushNotificationService (Web Push API)
/// On Desktop: Uses NativeNotificationService (Windows Toast / macOS / Linux)
class UnifiedNotificationService extends ChangeNotifier {
  static final UnifiedNotificationService _instance = UnifiedNotificationService._internal();
  factory UnifiedNotificationService() => _instance;
  UnifiedNotificationService._internal();

  static UnifiedNotificationService get instance => _instance;

  final PushNotificationService _webService = PushNotificationService.instance;
  final NativeNotificationService _nativeService = NativeNotificationService.instance;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  
  /// Check if notifications are supported on this platform
  bool get isSupported => kIsWeb ? _webService.isSupported : _nativeService.isSupported;
  
  /// Check if notifications are enabled
  bool get isEnabled => kIsWeb ? _webService.isEnabled : _nativeService.isEnabled;
  
  /// Get the current platform type
  String get platformType => kIsWeb ? 'web' : 'desktop';

  /// Initialize the appropriate notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        await _webService.initialize();
      } else {
        await _nativeService.initialize();
      }

      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('UnifiedNotificationService: Initialized for $platformType platform');
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UnifiedNotificationService: Error initializing: $e');
      }
      _isInitialized = true;
    }
  }

  /// Enable notifications for the current user
  /// 
  /// [userId] - The user's ID
  /// [userEmail] - The user's email (required for web push)
  Future<bool> enableNotifications(String userId, {String? userEmail}) async {
    if (!isSupported) return false;

    try {
      if (kIsWeb) {
        if (userEmail == null) {
          if (kDebugMode) {
            debugPrint('UnifiedNotificationService: Email required for web push');
          }
          return false;
        }
        return await _webService.enableNotifications(userId, userEmail);
      } else {
        return await _nativeService.enableNotifications(userId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UnifiedNotificationService: Error enabling notifications: $e');
      }
      return false;
    }
  }

  /// Disable notifications
  /// 
  /// [userId] is required for web push to remove the subscription
  Future<void> disableNotifications({String? userId}) async {
    if (kIsWeb) {
      if (userId != null) {
        await _webService.disableNotifications(userId);
      }
    } else {
      await _nativeService.disableNotifications();
    }
    notifyListeners();
  }

  /// Show a custom notification (desktop only)
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (!kIsWeb && _nativeService.isEnabled) {
      await _nativeService.showCustomNotification(title: title, body: body);
    }
  }

  /// Request permission (web only)
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      return await _webService.requestPermission();
    }
    // Desktop doesn't need explicit permission
    return true;
  }

  /// Check if permission is granted
  bool get hasPermission {
    if (kIsWeb) {
      return _webService.hasPermission;
    }
    // Desktop doesn't need explicit permission
    return true;
  }
}
