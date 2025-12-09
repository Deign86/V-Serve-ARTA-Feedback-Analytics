import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:window_manager/window_manager.dart'; // Commented out for Web
// import 'dart:io' show Platform; // Commented out for Web (Crashes Web Apps)

// Configuration & Services
import 'firebase_options.dart';
import 'services/offline_queue.dart';
import 'services/auth_services.dart';
import 'services/feedback_service.dart';

// User Side Screens
import 'screens/user_side/landing_page.dart';
import 'screens/user_side/user_profile.dart';

// Admin/Auth Side Screens
import 'screens/role_based_login_screen.dart';
import 'screens/role_based_dashboard.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
    
    try {
      final flushed = await OfflineQueue.flush();
      if (flushed > 0) debugPrint('Flushed $flushed pending feedbacks');
    } catch (e) {
      debugPrint('Failed flushing offline queue: $e');
    }
  } catch (e) {
    debugPrint('Firebase initializeApp failed: $e');
  }

  // 2. Window Manager (DESKTOP ONLY - Commented out for Web)
  /* 
  try {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await windowManager.ensureInitialized();

      WindowOptions windowOptions = const WindowOptions(
        size: Size(1920, 1080),
        minimumSize: Size(1280, 720),
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
    debugPrint('Window manager not available: $e');
  }
  */

  // 3. Run App with Providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FeedbackService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'V-Serve',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        primarySwatch: Colors.blue,
      ),
      
      // Default route
      initialRoute: '/', 
      
      routes: {
        // --- Public User Routes ---
        '/': (context) => const LandingScreen(),
        '/profile': (context) => const UserProfileScreen(),
        
        // --- Admin/Auth Routes ---
        '/login': (context) => const RoleBasedLoginScreen(),
        '/dashboard': (context) => const DashboardScreen(), 
      },
    );
  }
}