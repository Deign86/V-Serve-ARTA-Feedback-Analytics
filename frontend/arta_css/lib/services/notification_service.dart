// Cross-platform notification service facade
export 'notification_service_stub.dart'
  if (dart.library.io) 'notification_service_io.dart'
  if (dart.library.js) 'notification_service_web.dart';
