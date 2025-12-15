import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'services/cache_service.dart';
import 'widgets/global_offline_indicator.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, defaultTargetPlatform, TargetPlatform;
import 'screens/splash_screen.dart';

import 'screens/user_side/landing_page.dart';
import 'screens/user_side/user_profile.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// HTTP services (work on all platforms - no Firebase dependency)
import 'services/auth_services_http.dart';
import 'services/feedback_service_http.dart';
import 'services/user_management_service_http.dart';
import 'services/audit_log_service_http.dart';

// Notification services - conditional imports for platform support
import 'services/push_notification_service_stub.dart' as push_notif;
// Native notifications: stub for web, IO implementation for native (handles mobile vs desktop internally)
import 'services/native_notification_service_stub.dart'
    if (dart.library.io) 'services/native_notification_service_io.dart' as native_notif;

// Non-Firebase services (work on all platforms)
import 'services/survey_config_service.dart';
import 'services/survey_questions_service.dart';
import 'services/survey_provider.dart';
import 'services/unified_notification_service.dart';
import 'services/bot_protection_service.dart';

import 'screens/role_based_login_screen.dart';
import 'screens/admin/role_based_dashboard.dart';
import 'utils/app_transitions.dart';
import 'utils/app_logger.dart';

// Offline queue (HTTP-based, works on all platforms)
import 'services/offline_queue_http.dart';

// Conditional import for window_manager (desktop only)
import 'platform/window_helper_stub.dart'
    if (dart.library.io) 'platform/window_helper_io.dart' as window_helper;

// Conditional import for web URL strategy
import 'platform/url_strategy_stub.dart'
  if (dart.library.js_interop) 'platform/url_strategy_web.dart' as url_strategy;

import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure logging - disables all logs in production
  configureLogging();
  
  // Set URL strategy for web (removes # from URLs and enables proper history handling)
  url_strategy.configureUrlStrategy();

  if (kDebugMode) debugPrint('ARTAV_LOG: App Main Starting...');

  // Determine if we're on a native desktop platform (Windows/macOS/Linux)
  final bool isNativeDesktop = !kIsWeb && 
      (defaultTargetPlatform == TargetPlatform.windows ||
       defaultTargetPlatform == TargetPlatform.macOS ||
       defaultTargetPlatform == TargetPlatform.linux);
  
  // All platforms now use HTTP services - no Firebase initialization needed
  if (kDebugMode) {
    debugPrint('ARTAV_LOG: Using HTTP backend services (Firebase-free architecture)');
    debugPrint('ARTAV_LOG: Platform: ${kIsWeb ? "Web" : (isNativeDesktop ? "Desktop" : "Mobile")}');
  }
  
  // Flush offline queue (works on all platforms via HTTP)
  try {
    final flushed = await OfflineQueue.flush().timeout(const Duration(seconds: 2), onTimeout: () => 0);
    if (flushed > 0 && kDebugMode) debugPrint('ARTAV_LOG: Flushed $flushed pending feedbacks');
  } catch (e) {
    if (kDebugMode) debugPrint('ARTAV_LOG: Failed flushing offline queue: $e');
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

  // Initialize push notification service
  final pushNotificationService = push_notif.PushNotificationService.instance;
  pushNotificationService.initialize();
  if (kDebugMode) debugPrint('PushNotificationService initialized');

  // Initialize native notification service (for desktop platforms)
  final nativeNotificationService = native_notif.NativeNotificationService.instance;
  nativeNotificationService.initialize();
  if (kDebugMode) debugPrint('NativeNotificationService initialized');

  // Initialize unified notification service
  final unifiedNotificationService = UnifiedNotificationService.instance;
  unifiedNotificationService.initialize();
  if (kDebugMode) debugPrint('UnifiedNotificationService initialized');

  // Initialize bot protection service
  final botProtectionService = BotProtectionService.instance;
  botProtectionService.initialize();
  if (kDebugMode) debugPrint('BotProtectionService initialized');

  // Create platform-specific services
  // Native desktop (Windows/macOS/Linux) uses HTTP services
  // Web can use Firebase directly for real-time features
  final authService = AuthServiceHttp(); // Use HTTP for all platforms
  final feedbackService = FeedbackServiceHttp();
  final userManagementService = UserManagementServiceHttp();
  final auditLogService = AuditLogServiceHttp();
  
  if (kDebugMode) {
    debugPrint('Services initialized: isNativeDesktop=$isNativeDesktop');
    debugPrint('Using HTTP services for all platforms (Firebase removed)');
  }

  // Global error handlers to capture uncaught exceptions on all platforms
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) debugPrint('Uncaught Flutter error: ${details.exceptionAsString()}');
  };

  ui.PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) debugPrint('PlatformDispatcher uncaught error: $error\n$stack');
    return true; // handled
  };

  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cacheService),
          ChangeNotifierProvider.value(value: offlineQueueService),
          ChangeNotifierProvider.value(value: pushNotificationService),
          ChangeNotifierProvider<AuthServiceHttp>.value(value: authService),
          ChangeNotifierProvider<FeedbackServiceHttp>.value(value: feedbackService),
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
          ChangeNotifierProvider<UserManagementServiceHttp>.value(value: userManagementService),
          ChangeNotifierProvider(create: (_) => SurveyProvider()),
          ChangeNotifierProvider<AuditLogServiceHttp>.value(value: auditLogService),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    if (kDebugMode) debugPrint('Uncaught zone error: $error\n$stack');
  });
}

// Route observer to track navigation and handle security
// This implementation properly ignores dialogs/modals to prevent unintended logouts
class AuthRouteObserver extends NavigatorObserver {
  final AuthServiceHttp authService;
  
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
      final auditLogService = context.read<AuditLogServiceHttp>();
      final authService = context.read<AuthServiceHttp>();
      final userManagementService = context.read<UserManagementServiceHttp>();
      // ignore: unused_local_variable - Will be used when survey config audit logging is enabled
      final _ = context.read<SurveyConfigService>();
      
      // Connect audit service to auth service
      authService.setAuditService(auditLogService);
      
      // Connect audit service to user management (will get current user from auth when needed)
      userManagementService.setAuditService(auditLogService, authService.currentUser);
      
      // Connect audit service to survey config (uses base AuditLogService interface)
      // surveyConfigService.setAuditService(auditLogService, authService.currentUser);
      
      // Listen for auth changes to update the actor in services
      authService.addListener(() {
        userManagementService.setAuditService(auditLogService, authService.currentUser);
        // surveyConfigService.setAuditService(auditLogService, authService.currentUser);
      });
      
      if (kDebugMode) debugPrint('AuditLogging: Services initialized and connected');
    } catch (e) {
      if (kDebugMode) debugPrint('AuditLogging: Failed to initialize - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to properly listen to AuthServiceHttp changes
    return Consumer<AuthServiceHttp>(
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
  
  Route<dynamic>? _generateRoute(RouteSettings settings, AuthServiceHttp authService) {
    final routeName = settings.name ?? '/';
    
    // Define which routes require authentication
    final protectedRoutes = [
      '/admin/dashboard',
      '/dashboard',
    ];
    
    // Check if this is a protected route
    final isProtectedRoute = protectedRoutes.contains(routeName);
    
    // If trying to access protected route, wait for session to be restored first
    if (isProtectedRoute) {
      // If not initialized yet, show loading while waiting for session restore
      if (!authService.isInitialized) {
        return MaterialPageRoute(
          builder: (context) => _SessionRestoreScreen(
            authService: authService,
            targetRoute: routeName,
          ),
          settings: settings,
        );
      }
      // After initialization, check authentication
      if (!authService.isAuthenticated) {
        if (kDebugMode) debugPrint('Security: Blocked unauthenticated access to $routeName - redirecting to login');
        return MaterialPageRoute(
          builder: (context) => const RoleBasedLoginScreen(),
          settings: const RouteSettings(name: '/admin/login'),
        );
      }
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
        
      // Admin routes - blocked in user-only mode
      case '/admin':
      case '/admin/login':
      case '/login':
        // In user-only mode, redirect to landing page instead of login
        if (kUserOnlyMode) {
          if (kDebugMode) debugPrint('Security: Admin access disabled in user-only mode');
          return MaterialPageRoute(
            builder: (context) => const LandingScreen(),
            settings: const RouteSettings(name: '/'),
          );
        }
        return MaterialPageRoute(
          builder: (context) => const RoleBasedLoginScreen(),
          settings: settings,
        );
      case '/admin/dashboard':
      case '/dashboard':
        // In user-only mode, redirect to landing page
        if (kUserOnlyMode) {
          if (kDebugMode) debugPrint('Security: Dashboard access disabled in user-only mode');
          return MaterialPageRoute(
            builder: (context) => const LandingScreen(),
            settings: const RouteSettings(name: '/'),
          );
        }
        // Protected route check already handled above, just render dashboard
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
    return Consumer<AuthServiceHttp>(
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

/// Screen shown while waiting for session restoration to complete
class _SessionRestoreScreen extends StatefulWidget {
  final AuthServiceHttp authService;
  final String targetRoute;
  
  const _SessionRestoreScreen({
    required this.authService,
    required this.targetRoute,
  });

  @override
  State<_SessionRestoreScreen> createState() => _SessionRestoreScreenState();
}

class _SessionRestoreScreenState extends State<_SessionRestoreScreen> {
  @override
  void initState() {
    super.initState();
    _waitForSession();
  }
  
  Future<void> _waitForSession() async {
    // Wait for session restoration to complete
    await widget.authService.sessionRestored;
    
    if (!mounted) return;
    
    // After session is restored, navigate based on auth state
    if (widget.authService.isAuthenticated) {
      // Session restored successfully, go to dashboard
      Navigator.of(context).pushReplacementNamed(widget.targetRoute);
    } else {
      // No valid session, go to login
      Navigator.of(context).pushReplacementNamed('/admin/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003366),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/valenzuela_logo.png',
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.account_circle,
                size: 100,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Restoring session...',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



