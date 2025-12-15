/// Stub implementation for FirebaseMessaging on unsupported platforms (Windows/Linux/macOS)
/// This provides a no-op implementation so the code compiles without Firebase.

class RemoteMessage {
  final String? messageId;
  final Map<String, dynamic>? data;
  final RemoteNotification? notification;

  RemoteMessage({this.messageId, this.data, this.notification});
}

class RemoteNotification {
  final String? title;
  final String? body;

  RemoteNotification({this.title, this.body});
}

class NotificationSettings {
  final AuthorizationStatus authorizationStatus;
  NotificationSettings({required this.authorizationStatus});
}

enum AuthorizationStatus {
  authorized,
  denied,
  notDetermined,
  provisional,
}

class FirebaseMessaging {
  static FirebaseMessaging get instance => FirebaseMessaging._();
  FirebaseMessaging._();

  /// Stub for onBackgroundMessage - does nothing on desktop platforms
  static void onBackgroundMessage(Future<void> Function(RemoteMessage) handler) {
    // No-op on desktop - Firebase Messaging is not available
  }

  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  }) async {
    return NotificationSettings(authorizationStatus: AuthorizationStatus.denied);
  }

  Future<String?> getToken({String? vapidKey}) async {
    return null; // No FCM token on desktop
  }

  Stream<RemoteMessage> get onMessage => const Stream.empty();
  Stream<RemoteMessage> get onMessageOpenedApp => const Stream.empty();

  Future<RemoteMessage?> getInitialMessage() async => null;
}
