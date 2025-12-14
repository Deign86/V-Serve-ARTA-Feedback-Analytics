// Stub implementation for non-web platforms

String getCurrentHost() => 'non-web-platform';

Future<String?> executeRecaptcha(String action) async => 'non-web-platform';

void showRecaptchaBadge() {
  // No-op on non-web platforms
}

void hideRecaptchaBadge() {
  // No-op on non-web platforms
}
