import 'package:flutter/foundation.dart';

/// Centralized logging utility that controls when logs appear
/// 
/// Rules:
/// - Production (web release build): No logs at all
/// - Localhost/Development (debug mode): Logs enabled
/// - User-facing screens: Never show logs (handled by configureLogging)
class AppLogger {
  // Singleton instance
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();
  
  /// Whether we're running on production (release build on web)
  static bool get isProduction {
    // Release builds have kDebugMode = false
    // This covers production deployments on Vercel
    return !kDebugMode;
  }
  
  /// Whether logging is enabled at all
  /// Only enabled in debug mode (localhost/development)
  static bool get isLoggingEnabled {
    // NEVER log in production (release mode)
    // Only log in debug mode
    return kDebugMode;
  }
  
  /// Log a system/admin message (only in development)
  static void system(String message) {
    if (isLoggingEnabled) {
      debugPrint('ARTAV_LOG: $message');
    }
  }
  
  /// Log an error (only in development)
  static void error(String message, [Object? error]) {
    if (isLoggingEnabled) {
      if (error != null) {
        debugPrint('ARTAV_ERROR: $message - $error');
      } else {
        debugPrint('ARTAV_ERROR: $message');
      }
    }
  }
  
  /// Log a warning (only in development)
  static void warning(String message) {
    if (isLoggingEnabled) {
      debugPrint('ARTAV_WARN: $message');
    }
  }
  
  /// Log debug info (only in development)
  static void debug(String message) {
    if (isLoggingEnabled) {
      debugPrint('ARTAV_DEBUG: $message');
    }
  }
  
  /// Log service/cache operations (only in development)
  static void service(String serviceName, String message) {
    if (isLoggingEnabled) {
      debugPrint('$serviceName: $message');
    }
  }
  
  /// Log audit events (only in development, never on user side)
  static void audit(String action, String details) {
    if (isLoggingEnabled) {
      debugPrint('AuditLogService: Logged action - $action: $details');
    }
  }
}

/// Override debugPrint for the entire app to respect production mode
/// This is called once during app initialization
void configureLogging() {
  if (!kDebugMode) {
    // In production (release mode), make debugPrint a no-op
    // This silences ALL logs across the entire app
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
}
