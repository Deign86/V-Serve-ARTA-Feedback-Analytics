import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/offline_queue.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'screens/user_side/landing_page.dart';
import 'screens/user_side/user_profile.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_services.dart';
import 'services/feedback_service.dart';
import 'screens/role_based_login_screen.dart';
import 'screens/admin/role_based_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized with generated options');
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
    debugPrint('Window manager not available: $e');
  }

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
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      title: 'V-Serve',
      initialRoute: '/', // Public survey is the default landing page
      routes: {
        // Public routes - accessible to everyone (survey/feedback)
        '/': (context) => const LandingScreen(),
        '/profile': (context) => const UserProfileScreen(),
        
        // Admin routes - accessible via specialized link
        '/admin': (context) => const RoleBasedLoginScreen(),
        '/admin/login': (context) => const RoleBasedLoginScreen(),
        '/admin/dashboard': (context) => const DashboardScreen(),
        
        // Legacy routes (for backward compatibility)
        '/login': (context) => const RoleBasedLoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
