// Platform-selecting export: use the web implementation when compiled for web,
// otherwise use the non-web (no-op) implementation.
export 'push_notification_service_nonweb.dart'
  if (dart.library.html) 'push_notification_service_web.dart';
