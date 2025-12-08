// Native implementation for desktop window management

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:window_manager/window_manager.dart';

Future<void> initializeWindow() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1920, 1080),
      minimumSize: Size(1920, 1080),
      maximumSize: Size(1920, 1080),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
