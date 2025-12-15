/// Stub implementation for platforms that don't support Firebase (Windows/Linux/macOS)
/// This file is used when compiling for desktop platforms.

class FirebaseApp {
  final String name;
  FirebaseApp._({required this.name});
}

class Firebase {
  static Future<FirebaseApp> initializeApp({
    String? name,
    dynamic options,
  }) async {
    // No-op on desktop platforms - Firebase is not supported
    return FirebaseApp._(name: name ?? '[DEFAULT]');
  }
}

class FirebaseOptions {
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? authDomain;
  final String? storageBucket;
  final String? measurementId;

  const FirebaseOptions({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.authDomain,
    this.storageBucket,
    this.measurementId,
  });
}
