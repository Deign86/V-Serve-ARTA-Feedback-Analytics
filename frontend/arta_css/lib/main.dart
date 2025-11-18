import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/offline_queue.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'screens/user_side/landing_page.dart';
import 'screens/user_side/user_profile.dart';

// Added imports for new Feature
import 'package:provider/provider.dart';
import 'services/auth_services.dart';
import 'models/user_model.dart'; // adjust if your user model path is different
import 'screens/role_based_login_screen.dart'; // adjust file name if needed
import 'screens/role_based_dashboard.dart'; // new dashboard screen

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
  ChangeNotifierProvider(
    create: (_) {
      final auth = AuthService();
      auth.autoLogin(UserRole.administrator); // <- Force admin login
      return auth;
    },
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
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/landing': (context) => const LandingScreen(),
        '/profile': (context) => const UserProfileScreen(),
        '/login': (context) => const RoleBasedLoginScreen(),
        '/dashboard': (context) => const SurveyManagementApp(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

/* =========================================================
   New Survey Management / Role Based System Integrated Here
   ========================================================= */

// Auth wrapper to check authentication status
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isAuthenticated) {
          return const SurveyManagementApp();
        }
        return const RoleBasedLoginScreen();
      },
    );
  }
}

