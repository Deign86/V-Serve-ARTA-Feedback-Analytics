// Platform selector for native notification service
// Routes to the correct implementation based on platform

export 'native_notification_service_stub.dart' // Default (web)
    if (dart.library.io) 'native_notification_service_io.dart'; // Native platforms
