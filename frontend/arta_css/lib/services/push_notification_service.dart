import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Web-specific imports for push notifications
import 'dart:js_interop';

/// Service for managing push notifications to admin users
/// Uses Web Push API with VAPID for browser notifications
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

      // Check browser support for notifications
      _isSupported = await _checkBrowserSupport();
      
      if (!_isSupported) {
        if (kDebugMode) {
          debugPrint('PushNotificationService: Browser does not support push notifications');
        }
        _isInitialized = true;
        return;
      }

      // Load saved preferences
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_prefsKeyEnabled) ?? false;
      _currentSubscriptionEndpoint = prefs.getString(_prefsKeySubscription);

      // Check current permission status
      _permissionStatus = await _getNotificationPermission();

      if (kDebugMode) {
        debugPrint('PushNotificationService: Initialized - enabled: $_isEnabled, permission: $_permissionStatus');
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: Error initializing: $e');
      }
      _isInitialized = true;
    }
  }

  /// Check if browser supports notifications
  Future<bool> _checkBrowserSupport() async {
    try {
      // Use JS interop to check for Notification API
      final result = _jsCheckNotificationSupport();
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Get current notification permission status
  Future<String> _getNotificationPermission() async {
    try {
      return _jsGetPermission();
    } catch (e) {
      return 'unsupported';
    }
  }

  /// Request notification permission from the user
  Future<bool> requestPermission() async {
    if (!_isSupported) return false;

    try {
      final result = await _jsRequestPermission();
      _permissionStatus = result;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('PushNotificationService: Permission request result: $result');
      }
      
      return result == 'granted';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: Error requesting permission: $e');
      }
      return false;
    }
  }

  /// Enable push notifications for the current user
  Future<bool> enableNotifications(String userId, String userEmail) async {
    if (!_isSupported || !hasPermission) {
      // Try to request permission first
      final granted = await requestPermission();
      if (!granted) return false;
    }

    try {
      // Subscribe to push notifications
      final subscription = await _subscribeToNotifications();
      
      if (subscription == null) {
        if (kDebugMode) {
          debugPrint('PushNotificationService: Failed to create subscription');
        }
        return false;
      }

      // Save subscription to Firestore
      await _saveSubscription(userId, userEmail, subscription);

      // Save preference locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyEnabled, true);
      await prefs.setString(_prefsKeySubscription, subscription['endpoint'] ?? '');

      _isEnabled = true;
      _currentSubscriptionEndpoint = subscription['endpoint'];
      notifyListeners();

      if (kDebugMode) {
        debugPrint('PushNotificationService: Push notifications enabled for $userEmail');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: Error enabling notifications: $e');
      }
      return false;
    }
  }

  /// Disable push notifications
  Future<void> disableNotifications(String userId) async {
    try {
      // Remove subscription from Firestore
      if (_currentSubscriptionEndpoint != null) {
        final querySnapshot = await _firestore
            .collection(_subscriptionsCollection)
            .where('userId', isEqualTo: userId)
            .where('endpoint', isEqualTo: _currentSubscriptionEndpoint)
            .get();

        for (final doc in querySnapshot.docs) {
          await doc.reference.delete();
        }
      }

      // Unsubscribe from push
      await _unsubscribeFromNotifications();

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

  /// Save subscription to Firestore
  Future<void> _saveSubscription(String userId, String userEmail, Map<String, dynamic> subscription) async {
    try {
      // Check if subscription already exists
      final existing = await _firestore
          .collection(_subscriptionsCollection)
          .where('userId', isEqualTo: userId)
          .where('endpoint', isEqualTo: subscription['endpoint'])
          .get();

      if (existing.docs.isNotEmpty) {
        // Update existing subscription
        await existing.docs.first.reference.update({
          'keys': subscription['keys'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new subscription
        await _firestore.collection(_subscriptionsCollection).add({
          'userId': userId,
          'userEmail': userEmail,
          'endpoint': subscription['endpoint'],
          'keys': subscription['keys'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: Error saving subscription: $e');
      }
      rethrow;
    }
  }

  /// Show a local notification (for immediate feedback)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? icon,
  }) async {
    if (!_isSupported || !hasPermission) return;

    try {
      _jsShowNotification(title, body, icon ?? '/favicon.jpg');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: Error showing notification: $e');
      }
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

  // JS Interop methods for web push notifications
  Future<Map<String, dynamic>?> _subscribeToNotifications() async {
    try {
      // For now, we'll use the Notification API directly
      // Full Web Push with service workers would require more setup
      return {
        'endpoint': 'browser-notification-${DateTime.now().millisecondsSinceEpoch}',
        'keys': {'vapid': vapidPublicKey},
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> _unsubscribeFromNotifications() async {
    // Cleanup logic for unsubscribing
  }
}

// JS interop functions
@JS('Notification')
external JSObject? get _notification;

bool _jsCheckNotificationSupport() {
  if (!kIsWeb) return false;
  try {
    return _notification != null;
  } catch (e) {
    return false;
  }
}

@JS('Notification.permission')
external String get _jsPermission;

String _jsGetPermission() {
  if (!kIsWeb) return 'unsupported';
  try {
    return _jsPermission;
  } catch (e) {
    return 'unsupported';
  }
}

@JS('Notification.requestPermission')
external JSPromise<JSString> _jsRequestPermissionNative();

Future<String> _jsRequestPermission() async {
  if (!kIsWeb) return 'unsupported';
  try {
    final result = await _jsRequestPermissionNative().toDart;
    return result.toDart;
  } catch (e) {
    return 'denied';
  }
}

void _jsShowNotification(String title, String body, String icon) {
  if (!kIsWeb) return;
  try {
    _createNotification(title, body, icon);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error creating notification: $e');
    }
  }
}

@JS('eval')
external void _jsEval(String code);

void _createNotification(String title, String body, String icon) {
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
}
