// Service factory for creating platform-specific service implementations
// Web uses Firebase SDK for real-time, Native uses HTTP API

import 'package:flutter/foundation.dart' show kIsWeb;
import 'feedback_service.dart';
import 'feedback_service_http.dart';
import 'auth_services.dart';
import 'auth_services_http.dart';
import 'user_management_service_http.dart';
import 'audit_log_service_http.dart';

// Conditional imports for Firebase services (web only)
import 'service_factory_stub.dart'
    if (dart.library.js_interop) 'service_factory_web.dart' as platform;

/// Factory for creating platform-appropriate service implementations
class ServiceFactory {
  /// Create FeedbackService - Firebase on web, HTTP on native
  static FeedbackService createFeedbackService() {
    if (kIsWeb) {
      return platform.createFeedbackService();
    }
    return FeedbackServiceHttp();
  }

  /// Create AuthService - Firebase on web, HTTP on native
  static AuthService createAuthService() {
    if (kIsWeb) {
      return platform.createAuthService();
    }
    return AuthServiceHttp();
  }

  /// Create UserManagementService - Firebase on web, HTTP on native
  static UserManagementServiceHttp createUserManagementService() {
    if (kIsWeb) {
      return platform.createUserManagementService();
    }
    return UserManagementServiceHttp();
  }

  /// Create AuditLogService - Firebase on web, HTTP on native
  static AuditLogServiceHttp createAuditLogService() {
    if (kIsWeb) {
      return platform.createAuditLogService();
    }
    return AuditLogServiceHttp();
  }
}
