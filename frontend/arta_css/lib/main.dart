import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/offline_queue.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'screens/user_side/landing_page.dart';
import 'screens/user_side/user_profile.dart';
import 'screens/user_side/citizen_charter.dart';
import 'screens/user_side/sqd.dart';
import 'screens/user_side/suggestions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for client-side Firestore usage.
  // If you use the FlutterFire CLI, it will generate `firebase_options.dart` and you can
  // initialize with explicit options. This call attempts a default initialization which
  // works if platform config files (google-services.json / GoogleService-Info.plist) are present
  // or when using firebase_options.dart. If initialization fails, the app will continue but
  // Firestore writes will return an error.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized with generated options');
    // Attempt to flush any pending offline submissions
    try {
      final flushed = await OfflineQueue.flush();
      if (flushed > 0) debugPrint('Flushed $flushed pending feedbacks');
    } catch (e) {
      debugPrint('Failed flushing offline queue: $e');
    }
  } catch (e) {
    debugPrint('Firebase initializeApp failed: $e');
  }
  
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