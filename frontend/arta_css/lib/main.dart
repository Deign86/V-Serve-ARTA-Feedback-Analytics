import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'screens/user_side/landing_page.dart';
import 'screens/user_side/user_profile.dart';
import 'screens/user_side/citizen_charter.dart';
import 'screens/user_side/sqd.dart';
import 'screens/user_side/suggestions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await windowManager.ensureInitialized();
      
      WindowOptions windowOptions = const WindowOptions(
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
  } catch (e) {
    // Ignore errors on web platform
    // Use debugPrint instead of print to avoid production print lint
    debugPrint('Window manager not available: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'V-Serve',
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        '/profile': (context) => const UserProfileScreen(),
        '/citizenCharter': (context) => const CitizenCharterScreen(),
        '/sqd': (context) => const SQDScreen(),
        '/suggestions': (context) => const SuggestionsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}