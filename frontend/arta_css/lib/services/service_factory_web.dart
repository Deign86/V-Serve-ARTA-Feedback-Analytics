// Web implementation - uses HTTP API same as native
// Firebase packages removed for cross-platform compatibility

import 'feedback_service_http.dart';
import 'auth_services_http.dart';
import 'user_management_service_http.dart';
import 'audit_log_service_http.dart';

FeedbackServiceHttp createFeedbackService() => FeedbackServiceHttp();
AuthServiceHttp createAuthService() => AuthServiceHttp();
UserManagementServiceHttp createUserManagementService() => UserManagementServiceHttp();
AuditLogServiceHttp createAuditLogService() => AuditLogServiceHttp();
