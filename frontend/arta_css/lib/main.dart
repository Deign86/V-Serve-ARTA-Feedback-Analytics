import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/offline_queue.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/user_side/landing_page.dart';
import 'screens/user_side/user_profile.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_services.dart';
import 'services/feedback_service.dart';
import 'services/survey_config_service.dart';
import 'screens/role_based_login_screen.dart';
import 'screens/admin/role_based_dashboard.dart';

// Conditional import for window_manager (desktop only)
import 'platform/window_helper_stub.dart'
    if (dart.library.io) 'platform/window_helper_native.dart' as window_helper;

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
    // Initialize window manager for desktop platforms only
    if (!kIsWeb) {
      await window_helper.initializeWindow();
    }
  } catch (e) {
    debugPrint('Window manager not available: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FeedbackService()),
        ChangeNotifierProvider(create: (_) {
          final configService = SurveyConfigService();
          configService.loadConfig(); // Load saved configuration
          return configService;
        }),
      ],
      child: const MyApp(),
    ),
  );
}

// Route observer to track navigation and handle security
class AuthRouteObserver extends NavigatorObserver {
  final AuthService authService;
  
  AuthRouteObserver(this.authService);
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _handleRouteChange(route, previousRoute);
    super.didPush(route, previousRoute);
  }
  
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // When popping from admin to public, log out
    if (previousRoute != null) {
      _handleRouteChange(previousRoute, route);
    }
    super.didPop(route, previousRoute);
  }
  
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _handleRouteChange(newRoute, oldRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
  
  void _handleRouteChange(Route<dynamic> currentRoute, Route<dynamic>? previousRoute) {
    final currentRouteName = currentRoute.settings.name ?? '';
    final previousRouteName = previousRoute?.settings.name ?? '';
    
    // If navigating FROM admin area TO public area, force logout
    final wasInAdmin = previousRouteName.startsWith('/admin') || 
                       previousRouteName == '/dashboard';
    final nowInPublic = !currentRouteName.startsWith('/admin') && 
                        currentRouteName != '/dashboard' &&
                        currentRouteName != '/login';
    
    if (wasInAdmin && nowInPublic && authService.isAuthenticated) {
      debugPrint('Security: Logging out user - navigated from admin to public area');
      authService.logout();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    
    return MaterialApp(
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: true,
        physics: const BouncingScrollPhysics(),
      ),
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      title: 'V-Serve',
      initialRoute: '/', // Public survey is the default landing page
      navigatorObservers: [AuthRouteObserver(authService)],
      onGenerateRoute: (settings) => _generateRoute(settings, authService),
      debugShowCheckedModeBanner: false,
    );
  }
  
  Route<dynamic>? _generateRoute(RouteSettings settings, AuthService authService) {
    final routeName = settings.name ?? '/';
    
    // Define which routes require authentication
    final protectedRoutes = [
      '/admin/dashboard',
      '/dashboard',
    ];
    
    // Check if this is a protected route
    final isProtectedRoute = protectedRoutes.contains(routeName);
    
    // If trying to access protected route without authentication, redirect to login
    if (isProtectedRoute && !authService.isAuthenticated) {
      debugPrint('Security: Blocked unauthenticated access to $routeName - redirecting to login');
      return MaterialPageRoute(
        builder: (context) => const RoleBasedLoginScreen(),
        settings: const RouteSettings(name: '/admin/login'),
      );
    }
    
    // Route mapping
    switch (routeName) {
      // Public routes - accessible to everyone (survey/feedback)
      case '/':
        return MaterialPageRoute(
          builder: (context) => const LandingScreen(),
          settings: settings,
        );
      case '/profile':
        return MaterialPageRoute(
          builder: (context) => const UserProfileScreen(),
          settings: settings,
        );
        
      // Admin routes
      case '/admin':
      case '/admin/login':
      case '/login':
        return MaterialPageRoute(
          builder: (context) => const RoleBasedLoginScreen(),
          settings: settings,
        );
      case '/admin/dashboard':
      case '/dashboard':
        // Double-check authentication (belt and suspenders)
        if (!authService.isAuthenticated) {
          return MaterialPageRoute(
            builder: (context) => const RoleBasedLoginScreen(),
            settings: const RouteSettings(name: '/admin/login'),
          );
        }
        return MaterialPageRoute(
          builder: (context) => const AuthGuard(child: DashboardScreen()),
          settings: settings,
        );
        
      // Unknown route - redirect to landing
      default:
        return MaterialPageRoute(
          builder: (context) => const LandingScreen(),
          settings: const RouteSettings(name: '/'),
        );
    }
  }
}

// Auth Guard widget - continuously checks authentication status
class AuthGuard extends StatelessWidget {
  final Widget child;
  
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // If not authenticated, redirect to login immediately
        if (!authService.isAuthenticated) {
          // Schedule navigation after build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/admin/login',
              (route) => false,
            );
          });
          
          // Show loading while redirecting
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Session expired. Redirecting to login...'),
                ],
              ),
            ),
          );
        }
        
        // User is authenticated, show the protected content
        return child;
      },
    );
  }
}
