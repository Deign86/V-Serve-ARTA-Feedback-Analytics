import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform initialization helper
/// Determines platform-specific behavior for Firebase and backend services
class PlatformInit {
  PlatformInit._();
  
  /// Whether to skip Firebase initialization (Windows desktop)
  /// Note: Firebase now supports Windows, so we initialize Firebase on all platforms
  static bool get skipFirebaseInit => false;
  
  /// Whether to use HTTP backend instead of native Firebase
  /// We use native Firebase on all platforms now
  static bool get useHttpBackend => false;
  
  /// Check if running on Windows desktop
  static bool get isWindows {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows;
    } catch (_) {
      return false;
    }
  }
  
  /// Check if running on desktop (Windows, macOS, Linux)
  static bool get isDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }
  
  /// Check if running on mobile (iOS, Android)
  static bool get isMobile {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }
}
