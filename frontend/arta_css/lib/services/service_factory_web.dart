// Web implementation - currently uses HTTP API same as native
// Firebase packages removed due to Windows native build issues
// When building web-only, you can restore Firebase for real-time

import 'feedback_service.dart';
import 'feedback_service_http.dart';
import 'auth_services.dart';
import 'auth_services_http.dart';
import 'user_management_service_http.dart';
import 'audit_log_service_http.dart';

// Using HTTP services for all platforms for now
// To enable Firebase on web-only, uncomment firebase deps in pubspec.yaml
// and import the Firebase service files here instead

FeedbackService createFeedbackService() => FeedbackServiceHttp();
AuthService createAuthService() => AuthServiceHttp();
UserManagementServiceHttp createUserManagementService() => UserManagementServiceHttp();
AuditLogServiceHttp createAuditLogService() => AuditLogServiceHttp();
