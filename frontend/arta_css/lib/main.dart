import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/offline_queue.dart';
import 'services/cache_service.dart';
import 'widgets/global_offline_indicator.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'screens/splash_screen.dart';

import 'screens/user_side/landing_page.dart';
import 'screens/user_side/user_profile.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_services.dart';
import 'services/feedback_service.dart';
import 'services/survey_config_service.dart';
import 'services/survey_questions_service.dart';
import 'services/user_management_service.dart';
import 'services/survey_provider.dart';
import 'services/audit_log_service.dart';
import 'screens/role_based_login_screen.dart';
import 'screens/admin/role_based_dashboard.dart';
import 'utils/app_transitions.dart';

// Conditional import for window_manager (desktop only)
import 'platform/window_helper_stub.dart'
    if (dart.library.io) 'platform/window_helper_native.dart' as window_helper;

// Conditional import for web URL strategy
import 'platform/url_strategy_stub.dart'
    if (dart.library.js_interop) 'platform/url_strategy_web.dart' as url_strategy;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set URL strategy for web (removes # from URLs and enables proper history handling)
  url_strategy.configureUrlStrategy();

  if (kDebugMode) debugPrint('ARTAV_LOG: App Main Starting...');

  try {
    if (kDebugMode) debugPrint('ARTAV_LOG: Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 3), onTimeout: () {
      if (kDebugMode) debugPrint('ARTAV_LOG: Firebase init timed out - continuing without Firebase');
      return Firebase.app(); // Return dummy/incomplete app or just continue
    });
    if (kDebugMode) debugPrint('ARTAV_LOG: Firebase initialized with generated options');
    
    try {
      final flushed = await OfflineQueue.flush().timeout(const Duration(seconds: 2), onTimeout: () => 0);
      if (flushed > 0 && kDebugMode) debugPrint('ARTAV_LOG: Flushed $flushed pending feedbacks');
    } catch (e) {
      if (kDebugMode) debugPrint('ARTAV_LOG: Failed flushing offline queue: $e');
    }
  } catch (e) {
    if (kDebugMode) debugPrint('ARTAV_LOG: Firebase initializeApp failed: $e');
  }

  try {
    // Initialize window manager for desktop platforms only
    if (!kIsWeb) {
      await window_helper.initializeWindow();
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Window manager not available: $e');
  }

  // Initialize cache service and warmup
  final cacheService = CacheService.instance;
  try {
    if (kDebugMode) debugPrint('Starting cache warmup...');
    await cacheService.warmupCache().timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        if (kDebugMode) debugPrint('Cache warmup timed out - continuing startup');
      },
    );
  } catch (e) {
    if (kDebugMode) debugPrint('Cache warmup failed: $e');
  }
  if (kDebugMode) debugPrint('CacheService initialized');

  // Initialize offline queue service
  final offlineQueueService = OfflineQueueService.instance;
  if (kDebugMode) debugPrint('OfflineQueueService initialized');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: cacheService),
        ChangeNotifierProvider.value(value: offlineQueueService),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FeedbackService()),
        ChangeNotifierProvider(create: (_) {
          final configService = SurveyConfigService();
          configService.loadConfig(); // Load saved configuration
          return configService;
        }),
        ChangeNotifierProvider(create: (_) {
          final questionsService = SurveyQuestionsService();
          questionsService.loadQuestions(); // Load saved questions
          return questionsService;
        }),
        ChangeNotifierProvider(create: (_) => UserManagementService()),
        ChangeNotifierProvider(create: (_) => SurveyProvider()),
        ChangeNotifierProvider(create: (_) => AuditLogService()),
      ],
      child: const MyApp(),
    ),
  );
}

// Route observer to track navigation and handle security
// This implementation properly ignores dialogs/modals to prevent unintended logouts
class AuthRouteObserver extends NavigatorObserver {
  final AuthService authService;
  
  // Track the last known "real" page route (not dialogs/modals)
  String? _lastPageRoute;
  
  AuthRouteObserver(this.authService);
  
  // Helper to check if a route is a dialog/modal overlay
  // Dialogs use DialogRoute, ModalBottomSheetRoute, PopupRoute, etc.
  bool _isOverlayRoute(Route<dynamic>? route) {
    if (route == null) return true;
    
    // Check by route type - these are overlay routes that should be ignored
    if (route is PopupRoute) return true;
    if (route is DialogRoute) return true;
    
    // Check by route name - null/empty names are typically overlays
    final name = route.settings.name;
    if (name == null || name.isEmpty) return true;
    
    // RawDialogRoute and similar don't always have null names
    // but they have the 'isFullscreenDialog' property
    if (route is PageRoute && route.fullscreenDialog) {
      // Fullscreen dialogs are still "real" pages in our context
      return false;
    }
    
    return false;
  }
  
  // Helper to check if a route is an admin route
  bool _isAdminRoute(String? routeName) {
    if (routeName == null) return false;
    return routeName.startsWith('/admin') || routeName == '/dashboard';
  }
  
  // Helper to check if a route is a public survey route
  bool _isPublicRoute(String? routeName) {
    if (routeName == null) return false;
    const publicRoutes = ['/', '/profile', '/citizenCharter', '/sqd', '/suggestions'];
    return publicRoutes.contains(routeName);
  }
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    
    // Ignore overlay routes (dialogs, modals, popups)
    if (_isOverlayRoute(route)) {
      if (kDebugMode) debugPrint('RouteObserver: Ignoring overlay push: ${route.runtimeType}');
      return;
    }
    
    _handlePageNavigation(route.settings.name, _lastPageRoute);
    _lastPageRoute = route.settings.name;
  }
  
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    
    // Ignore overlay routes being dismissed
    if (_isOverlayRoute(route)) {
      if (kDebugMode) debugPrint('RouteObserver: Ignoring overlay pop: ${route.runtimeType}');
      return;
    }
    
    // When a real page is popped, check if we're going back to a public route
    final previousRouteName = previousRoute?.settings.name;
    if (!_isOverlayRoute(previousRoute)) {
      _handlePageNavigation(previousRouteName, route.settings.name);
      _lastPageRoute = previousRouteName;
    }
  }
  
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    
    // Ignore overlay replacements
    if (_isOverlayRoute(newRoute)) return;
    
    _handlePageNavigation(newRoute?.settings.name, oldRoute?.settings.name);
    _lastPageRoute = newRoute?.settings.name;
  }
  
  void _handlePageNavigation(String? toRoute, String? fromRoute) {
    // Security check: if navigating FROM admin TO public while authenticated, logout
    if (_isAdminRoute(fromRoute) && _isPublicRoute(toRoute) && authService.isAuthenticated) {
      if (kDebugMode) debugPrint('Security: User navigated from admin ($fromRoute) to public ($toRoute) - logging out');
      authService.logout();
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Wire up audit logging services after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuditLogging();
    });
  }
  
  /// Initialize audit logging by connecting all services to the audit log service
  void _initializeAuditLogging() {
    try {
      final auditLogService = context.read<AuditLogService>();
      final authService = context.read<AuthService>();
      final userManagementService = context.read<UserManagementService>();
      final surveyConfigService = context.read<SurveyConfigService>();
      
      // Connect audit service to auth service
      authService.setAuditService(auditLogService);
      
      // Connect audit service to user management (will get current user from auth when needed)
      userManagementService.setAuditService(auditLogService, authService.currentUser);
      
      // Connect audit service to survey config
      surveyConfigService.setAuditService(auditLogService, authService.currentUser);
      
      // Listen for auth changes to update the actor in services
      authService.addListener(() {
        userManagementService.setAuditService(auditLogService, authService.currentUser);
        surveyConfigService.setAuditService(auditLogService, authService.currentUser);
      });
      
      if (kDebugMode) debugPrint('AuditLogging: Services initialized and connected');
    } catch (e) {
      if (kDebugMode) debugPrint('AuditLogging: Failed to initialize - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to properly listen to AuthService changes
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return GlobalOfflineIndicator(
          child: MaterialApp(
            scrollBehavior: const SmoothScrollBehavior(),
          theme: ThemeData(
            textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: GenericPageTransitionsBuilder(),
                TargetPlatform.iOS: GenericPageTransitionsBuilder(),
                TargetPlatform.windows: GenericPageTransitionsBuilder(),
                TargetPlatform.macOS: GenericPageTransitionsBuilder(),
                TargetPlatform.linux: GenericPageTransitionsBuilder(),
              },
            ),
          ),
          title: 'V-Serve',
          initialRoute: '/', // Public survey is the default landing page
          navigatorObservers: [AuthRouteObserver(authService)],
          onGenerateRoute: (settings) => _generateRoute(settings, authService),
          debugShowCheckedModeBanner: false,
          ),
        );
      },
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
      if (kDebugMode) debugPrint('Security: Blocked unauthenticated access to $routeName - redirecting to login');
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
          builder: (context) => const SplashScreen(nextScreen: LandingScreen()),
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

// Auth Guard widget - protects admin routes with continuous authentication check
// Uses StatefulWidget to properly track mounted state and avoid redirect loops
class AuthGuard extends StatefulWidget {
  final Widget child;
  
  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isRedirecting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // If not authenticated and not already redirecting, schedule redirect
        if (!authService.isAuthenticated && !_isRedirecting) {
          _isRedirecting = true;
          
          // Schedule navigation after build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/admin/login',
                (route) => false,
              );
            }
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
        return widget.child;
      },
    );
  }
}
