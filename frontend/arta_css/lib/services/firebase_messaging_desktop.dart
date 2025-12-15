/// Stub Firebase Messaging service for desktop platforms (Windows/Linux/macOS)
/// Provides no-op implementations since desktop uses polling-based notifications.

/// Request notification permission - always returns true on desktop (uses native system notifications)
Future<bool> requestFirebaseMessagingPermission() async {
  return true;
}

/// Get FCM token - returns null on desktop (uses device_token from SharedPreferences instead)
Future<String?> getFirebaseMessagingToken() async {
  return null;
}

/// Background message handler stub - does nothing on desktop
Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {
  // No-op on desktop
}
