// Stub implementation for non-web platforms

bool jsCheckNotificationSupport() => false;

String jsGetPermission() => 'unsupported';

Future<String> jsRequestPermission() async => 'unsupported';

void jsShowNotification(String title, String body, String icon) {
  // No-op on non-web platforms
}
