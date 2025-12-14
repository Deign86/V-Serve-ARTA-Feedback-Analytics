// Service factory for creating service implementations
// All platforms use HTTP API for consistency

import 'feedback_service_http.dart';
import 'auth_services_http.dart';
import 'user_management_service_http.dart';
import 'audit_log_service_http.dart';

/// Factory for creating service implementations
/// All platforms use HTTP services for consistency
class ServiceFactory {
  /// Create FeedbackService
  static FeedbackServiceHttp createFeedbackService() {
    return FeedbackServiceHttp();
  }

  /// Create AuthService
  static AuthServiceHttp createAuthService() {
    return AuthServiceHttp();
  }

  /// Create UserManagementService
  static UserManagementServiceHttp createUserManagementService() {
    return UserManagementServiceHttp();
  }

  /// Create AuditLogService
  static AuditLogServiceHttp createAuditLogService() {
    return AuditLogServiceHttp();
  }
}
