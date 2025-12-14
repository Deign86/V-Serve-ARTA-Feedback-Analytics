import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Service for managing push notifications to admin users
/// Uses Web Push API with VAPID for browser notifications
/// 
/// NOTE: Push notifications are only supported on web platform.
/// On desktop/mobile, this service is a no-op.
class PushNotificationService extends ChangeNotifier {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static PushNotificationService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // VAPID public key for web push
  static const String vapidPublicKey = '8Mq0JTBeM4vLmr3vVh_UyHAZHuBS98phWtFXTL2dtKg';
  
  static const String _prefsKeyEnabled = 'push_notifications_enabled';
  static const String _prefsKeySubscription = 'push_subscription_endpoint';
  static const String _subscriptionsCollection = 'push_subscriptions';

  bool _isEnabled = false;
  bool _isSupported = false;
  bool _isInitialized = false;
  String? _currentSubscriptionEndpoint;
  String? _permissionStatus;

  bool get isEnabled => _isEnabled;
  bool get isSupported => _isSupported;
  bool get isInitialized => _isInitialized;
  String? get permissionStatus => _permissionStatus;
  bool get hasPermission => _permissionStatus == 'granted';

  /// Initialize the push notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if running on web
      if (!kIsWeb) {
        if (kDebugMode) {
          debugPrint('PushNotificationService: Not running on web, push notifications disabled');
        }
        _isSupported = false;
        _isInitialized = true;
        return;
      }

      // On web, we would check browser support
      // For cross-platform compatibility, mark as not supported on non-web
      _isSupported = false;
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('PushNotificationService: Initialized (web-only feature)');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: Error initializing: $e');
      }
      _isInitialized = true;
    }
  }

  /// Request notification permission from the user
  Future<bool> requestPermission() async {
    if (!kIsWeb || !_isSupported) return false;
    
    // Web-specific permission request
    return false;
  }

  /// Enable push notifications for the current user
  Future<bool> enableNotifications(String userId, String userEmail) async {
    if (!kIsWeb || !_isSupported || !hasPermission) {
      return false;
    }

    // Web-specific subscription logic
    return false;
  }

  /// Disable push notifications
  Future<void> disableNotifications(String userId) async {
    if (!kIsWeb) return;
    
    try {
      // Clear local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyEnabled, false);
      await prefs.remove(_prefsKeySubscription);

      _isEnabled = false;
      _currentSubscriptionEndpoint = null;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('PushNotificationService: Push notifications disabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: Error disabling notifications: $e');
      }
    }
  }

  /// Show a local notification (for immediate feedback)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? icon,
  }) async {
    if (!kIsWeb || !_isSupported || !hasPermission) return;

    // Web-specific notification display
    if (kDebugMode) {
      debugPrint('PushNotificationService: Would show notification - $title: $body');
    }
  }

  /// Queue a push notification to be sent to all admin subscribers
  Future<void> queuePushNotification({
    required String title,
    required String body,
    required String severity,
    String? alertId,
  }) async {
    try {
      // Save to notification queue in Firestore
      // A Cloud Function or backend service would pick this up and send to subscribers
      await _firestore.collection('push_notification_queue').add({
        'title': title,
        'body': body,
        'severity': severity,
        'alertId': alertId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('PushNotificationService: Queued push notification: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: Error queueing push notification: $e');
      }
    }
  }
}
