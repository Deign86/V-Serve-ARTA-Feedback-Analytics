import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dark_mode_service.dart';

/// Color inversion matrix for dark mode (like Dark Reader browser extension).
/// 
/// This matrix inverts the luminance while attempting to preserve hues.
/// The effect is similar to CSS `filter: invert(1) hue-rotate(180deg)`.
/// 
/// Matrix breakdown:
/// - Inverts RGB channels
/// - Applies hue rotation to maintain color relationships
/// - Adjusts brightness/contrast for readability
const List<double> _darkModeInvertMatrix = <double>[
  // R    G      B      A    offset
  -0.9,  0.1,   0.1,   0.0,  255.0, // Red output
   0.1, -0.9,   0.1,   0.0,  255.0, // Green output
   0.1,  0.1,  -0.9,   0.0,  255.0, // Blue output
   0.0,  0.0,   0.0,   1.0,    0.0, // Alpha output
];

/// Alternative matrix - simpler inversion with slight warm tint
/// Easier on the eyes for extended reading
const List<double> _darkModeWarmMatrix = <double>[
  // R      G      B      A    offset
  -0.85,   0.15,  0.05,  0.0,  255.0, // Slightly warm red
   0.10,  -0.90,  0.05,  0.0,  255.0, // Green
   0.05,   0.10, -0.85,  0.0,  255.0, // Slightly reduced blue
   0.0,    0.0,   0.0,   1.0,    0.0, // Alpha unchanged
];

/// High contrast dark mode matrix
/// Better for accessibility
const List<double> _darkModeHighContrastMatrix = <double>[
  // R    G     B     A    offset
  -1.0,  0.0,  0.0,  0.0,  255.0,
   0.0, -1.0,  0.0,  0.0,  255.0,
   0.0,  0.0, -1.0,  0.0,  255.0,
   0.0,  0.0,  0.0,  1.0,    0.0,
];

/// A widget that applies a dark mode color filter overlay.
/// 
/// This implements browser extension-style dark mode by applying
/// a ColorFilter.matrix transformation over the entire widget tree.
/// 
/// Features:
/// - Dynamic toggle with smooth animations
/// - Performance-optimized with RepaintBoundary
/// - Uses canvas-level color inversion
/// - Excludes child widgets wrapped in [IgnoreDarkMode]
/// 
/// Usage:
/// ```dart
/// DarkModeOverlay(
///   child: MaterialApp(...),
/// )
/// ```
class DarkModeOverlay extends StatefulWidget {
  const DarkModeOverlay({
    super.key,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.useWarmTint = true,
  });

  /// The child widget tree to apply dark mode to
  final Widget child;
  
  /// Duration for the dark mode transition animation
  final Duration animationDuration;
  
  /// Curve for the dark mode transition animation
  final Curve animationCurve;
  
  /// Whether to use the warm-tinted matrix (easier on eyes)
  /// If false, uses the standard inversion matrix
  final bool useWarmTint;

  @override
  State<DarkModeOverlay> createState() => _DarkModeOverlayState();
}

class _DarkModeOverlayState extends State<DarkModeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DarkModeService>(
      builder: (context, darkModeService, child) {
        // Update system brightness when MediaQuery is available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final brightness = MediaQuery.of(context).platformBrightness;
          darkModeService.updateSystemBrightness(brightness);
        });

        // Animate based on dark mode state
        if (darkModeService.isDarkMode) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }

        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final t = _animation.value;
            
            if (t == 0.0) {
              // No dark mode - return child without filter
              return child!;
            }
            
            // Interpolate matrix values for smooth transition
            final matrix = widget.useWarmTint
                ? _interpolateMatrix(_identityMatrix, _darkModeWarmMatrix, t)
                : _interpolateMatrix(_identityMatrix, _darkModeInvertMatrix, t);
            
            return RepaintBoundary(
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(matrix),
                child: child,
              ),
            );
          },
          child: widget.child,
        );
      },
    );
  }

  /// Identity matrix (no color transformation)
  static const List<double> _identityMatrix = <double>[
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  /// Linearly interpolate between two color matrices
  List<double> _interpolateMatrix(List<double> a, List<double> b, double t) {
    return List.generate(20, (i) => a[i] + (b[i] - a[i]) * t);
  }
}

/// A wrapper widget that excludes its children from dark mode color inversion.
/// 
/// Use this to preserve the original colors of specific widgets like:
/// - Charts (fl_chart)
/// - Images and logos
/// - Brand-colored elements
/// - Video players
/// 
/// The widget works by applying a reverse color filter that cancels
/// out the dark mode transformation.
/// 
/// Usage:
/// ```dart
/// IgnoreDarkMode(
///   child: LineChart(...),
/// )
/// ```
class IgnoreDarkMode extends StatelessWidget {
  const IgnoreDarkMode({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<DarkModeService>(
      builder: (context, darkModeService, _) {
        if (!darkModeService.isDarkMode) {
          return child;
        }
        
        // Apply reverse transformation to cancel out the dark mode filter
        // This effectively "undoes" the color inversion for this subtree
        return RepaintBoundary(
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(_reverseMatrix),
            child: child,
          ),
        );
      },
    );
  }

  /// Reverse matrix to cancel out the warm dark mode matrix
  /// This is the inverse of _darkModeWarmMatrix
  static const List<double> _reverseMatrix = <double>[
    // Approximate inverse - re-inverts the colors
    -1.05,  0.15,  0.05,  0.0,  255.0,
     0.10, -1.05,  0.05,  0.0,  255.0,
     0.05,  0.10, -1.05,  0.0,  255.0,
     0.0,   0.0,   0.0,   1.0,    0.0,
  ];
}

/// A widget that provides a dark mode toggle button.
/// 
/// This is a convenience widget that shows an icon button
/// to toggle dark mode with optional tooltip.
class DarkModeToggleButton extends StatelessWidget {
  const DarkModeToggleButton({
    super.key,
    this.iconSize = 24.0,
    this.color,
    this.showTooltip = true,
  });

  final double iconSize;
  final Color? color;
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    return Consumer<DarkModeService>(
      builder: (context, darkModeService, _) {
        final isDark = darkModeService.isDarkMode;
        
        final button = IconButton(
          icon: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            size: iconSize,
            color: color,
          ),
          onPressed: () => darkModeService.toggleDarkMode(),
        );
        
        if (showTooltip) {
          return Tooltip(
            message: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            child: button,
          );
        }
        
        return button;
      },
    );
  }
}

/// Extension to easily access dark mode service from BuildContext
extension DarkModeContext on BuildContext {
  DarkModeService get darkMode => Provider.of<DarkModeService>(this, listen: false);
  bool get isDarkMode => Provider.of<DarkModeService>(this).isDarkMode;
}
