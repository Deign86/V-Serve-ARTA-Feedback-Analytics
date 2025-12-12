import 'package:flutter/material.dart';

/// A custom page transition builder that provides a "premium" feel
/// using a combination of Slide and Fade effects.
class GenericPageTransitionsBuilder extends PageTransitionsBuilder {
  const GenericPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Custom curve for a modern feel
    const curve = Curves.easeOutQuart;
    
    // Scale slightly from 0.95 to 1.0 (Subtle zoom in)
    final scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve,
    ));

    // Fade in
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ));

    // Combined: Fade + Scale
    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: child,
      ),
    );
  }
}
