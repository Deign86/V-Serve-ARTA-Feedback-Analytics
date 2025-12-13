import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  /// Minimum display time in milliseconds (ensures splash is visible even if init is fast)
  final int minimumDisplayMs;

  const SplashScreen({
    super.key,
    required this.nextScreen,
    this.minimumDisplayMs = 800, // Minimum 800ms so animation is visible
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late DateTime _startTime;
  bool _navigationTriggered = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    
    // Animation setup
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Navigate after animation completes and minimum display time is met
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateWhenReady();
      }
    });
  }

  void _navigateWhenReady() {
    if (_navigationTriggered || !mounted) return;
    
    final elapsed = DateTime.now().difference(_startTime).inMilliseconds;
    final remaining = widget.minimumDisplayMs - elapsed;
    
    if (remaining > 0) {
      // Wait for minimum display time
      Timer(Duration(milliseconds: remaining), _performNavigation);
    } else {
      // Minimum time already passed, navigate immediately
      _performNavigation();
    }
  }

  void _performNavigation() {
    if (_navigationTriggered || !mounted) return;
    _navigationTriggered = true;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: child,
                    ),
                  );
                },
              child: Column(
                children: [
                  // Placeholder for actual logo asset, using styled text for now
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 80,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "V-Serve",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    "ARTA Feedback Analytics",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
            
            const SizedBox(height: 60),
            
            // Loading Indicator
            SizedBox(
              width: 200,
              child: Column(
                children: [
                  const LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: Color(0xFFE0E0E0),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Initializing...",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
