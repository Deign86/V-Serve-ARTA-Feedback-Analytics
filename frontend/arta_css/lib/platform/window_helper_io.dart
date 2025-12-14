// IO platform window helper
// This file is loaded on all dart.library.io platforms (desktop + mobile)
// It checks at runtime whether to use window_manager (desktop only)

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Initialize window - only does something on desktop platforms
Future<void> initializeWindow() async {
  // Only initialize on desktop platforms
  final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  
  if (!isDesktop) {
    // Mobile platform - no window management needed
    if (kDebugMode) {
      debugPrint('Window helper: Mobile platform - skipping window initialization');
    }
    return;
  }
  
  // Desktop platform - but we can't import window_manager here directly
  // because it would still be loaded on mobile at compile time
  // The actual desktop window initialization is handled separately
  if (kDebugMode) {
    debugPrint('Window helper: Desktop platform detected');
  }
}
