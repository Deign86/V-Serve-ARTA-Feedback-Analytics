import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional import for native notifications
import 'native_notification_stub.dart'
    if (dart.library.io) 'native_notification_native.dart' as native_notifier;

/// Service for managing native desktop notifications (Windows/macOS/Linux)
/// Complements PushNotificationService for non-web platforms
class NativeNotificationService extends ChangeNotifier {
  static final NativeNotificationService _instance = NativeNotificationService._internal();
  factory NativeNotificationService() => _instance;
  NativeNotificationService._internal();

  static NativeNotificationService get instance => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static const String _prefsKeyEnabled = 'native_notifications_enabled';
  static const String _prefsKeyLastCheck = 'native_notifications_last_check';
  static const String _alertsCollection = 'alerts';
  
  // Polling interval for checking new feedback/alerts
  static const Duration _pollingInterval = Duration(minutes: 2);

  bool _isEnabled = false;
  bool _isSupported = false;
  bool _isInitialized = false;
  Timer? _pollingTimer;
  String? _currentUserId;
  
  StreamSubscription? _alertsSubscription;

  bool get isEnabled => _isEnabled;
  bool get isSupported => _isSupported;
  bool get isInitialized => _isInitialized;

  /// Initialize the native notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Only supported on desktop platforms
      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint('NativeNotificationService: Running on web, using PushNotificationService instead');
        }
        _isSupported = false;
        _isInitialized = true;
        return;
      }

      // Check if we're on a supported desktop platform
      _isSupported = defaultTargetPlatform == TargetPlatform.windows ||
                     defaultTargetPlatform == TargetPlatform.macOS ||
                     defaultTargetPlatform == TargetPlatform.linux;

      if (!_isSupported) {
        if (kDebugMode) {
          debugPrint('NativeNotificationService: Platform not supported');
        }
        _isInitialized = true;
        return;
      }

      // Initialize the native notifier
      await native_notifier.initialize();

      // Load saved preferences
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_prefsKeyEnabled) ?? false;

      if (kDebugMode) {
        debugPrint('NativeNotificationService: Initialized - enabled: $_isEnabled');
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NativeNotificationService: Error initializing: $e');
      }
      _isInitialized = true;
    }
  }

  /// Enable notifications for the current user
  Future<bool> enableNotifications(String userId) async {
    if (!_isSupported) return false;

    try {
      _currentUserId = userId;
      _isEnabled = true;

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyEnabled, true);

      // Start listening for alerts
      _startAlertListener(userId);
      
      // Start polling for new feedback
      _startPolling();

      if (kDebugMode) {
        debugPrint('NativeNotificationService: Notifications enabled for user $userId');
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NativeNotificationService: Error enabling notifications: $e');
      }
      return false;
    }
  }

  /// Disable notifications
  Future<void> disableNotifications() async {
    _isEnabled = false;
    _currentUserId = null;
    
    _stopPolling();
    _alertsSubscription?.cancel();
    _alertsSubscription = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyEnabled, false);

    if (kDebugMode) {
      debugPrint('NativeNotificationService: Notifications disabled');
    }

    notifyListeners();
  }

  /// Start listening for real-time alerts from Firestore
  void _startAlertListener(String userId) {
    _alertsSubscription?.cancel();
    
    _alertsSubscription = _firestore
        .collection(_alertsCollection)
        .where('recipientId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null) {
                _showNotification(
                  title: data['title'] ?? 'New Alert',
                  body: data['message'] ?? '',
                  id: change.doc.id,
                );
              }
            }
          }
        }, onError: (e) {
          if (kDebugMode) {
            debugPrint('NativeNotificationService: Error listening to alerts: $e');
          }
        });
  }

  /// Start polling for new feedback submissions
  void _startPolling() {
    _stopPolling();
    
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _checkForNewFeedback();
    });
  }

  /// Stop polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Check for new feedback submissions
  Future<void> _checkForNewFeedback() async {
    if (!_isEnabled || _currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckStr = prefs.getString(_prefsKeyLastCheck);
      final lastCheck = lastCheckStr != null 
          ? DateTime.parse(lastCheckStr) 
          : DateTime.now().subtract(const Duration(hours: 1));

      // Query for new feedback since last check
      final query = await _firestore
          .collection('feedbacks')
          .where('submittedAt', isGreaterThan: Timestamp.fromDate(lastCheck))
          .limit(5)
          .get();

      if (query.docs.isNotEmpty) {
        final count = query.docs.length;
        _showNotification(
          title: 'New Feedback Received',
          body: count == 1 
              ? '1 new survey response submitted'
              : '$count new survey responses submitted',
          id: 'feedback-${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Update last check time
      await prefs.setString(_prefsKeyLastCheck, DateTime.now().toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NativeNotificationService: Error checking for new feedback: $e');
      }
    }
  }

  /// Show a native notification
  Future<void> _showNotification({
    required String title,
    required String body,
    required String id,
  }) async {
    if (!_isEnabled || !_isSupported) return;

    try {
      await native_notifier.showNotification(
        title: title,
        body: body,
        id: id,
      );
      
      if (kDebugMode) {
        debugPrint('NativeNotificationService: Showed notification - $title');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NativeNotificationService: Error showing notification: $e');
      }
    }
  }

  /// Show a custom notification (can be called externally)
  Future<void> showCustomNotification({
    required String title,
    required String body,
  }) async {
    await _showNotification(
      title: title,
      body: body,
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Dispose resources
  @override
  void dispose() {
    _stopPolling();
    _alertsSubscription?.cancel();
    super.dispose();
  }
}
