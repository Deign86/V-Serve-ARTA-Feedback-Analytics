// Stub implementation for non-web platforms
// These functions should never be called on native platforms

import 'feedback_service_stub.dart';
import 'feedback_service_http.dart';
import 'auth_services_stub.dart';
import 'auth_services_http.dart';
import 'user_management_service_http.dart';
import 'audit_log_service_http.dart';

FeedbackService createFeedbackService() => FeedbackServiceHttp();
AuthService createAuthService() => AuthServiceHttp();
UserManagementServiceHttp createUserManagementService() => UserManagementServiceHttp();
AuditLogServiceHttp createAuditLogService() => AuditLogServiceHttp();
