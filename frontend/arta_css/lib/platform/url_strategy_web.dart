// Web-specific URL strategy implementation
// This file is used when compiling for web platform
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Configure URL strategy for web platform
/// Uses PathUrlStrategy to remove the # from URLs (cleaner URLs)
/// This also enables proper browser history handling
void configureUrlStrategy() {
  // Use path-based URLs instead of hash-based (e.g., /admin instead of /#/admin)
  // This provides cleaner URLs and better integration with browser history
  usePathUrlStrategy();
}
