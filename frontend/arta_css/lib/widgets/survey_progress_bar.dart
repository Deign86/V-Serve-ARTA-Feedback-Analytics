import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Enhanced survey progress bar with step icons, connecting lines, and animations
class SurveyProgressBar extends StatefulWidget {
  final int currentStep; // 1-based index
  final int totalSteps;
  final bool isMobile;
  final List<ProgressBarStep>? customSteps;

  const SurveyProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.isMobile = false,
    this.customSteps,
  });

  @override
  State<SurveyProgressBar> createState() => _SurveyProgressBarState();
}

class _SurveyProgressBarState extends State<SurveyProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Default steps configuration
  static const List<ProgressBarStep> _defaultSteps = [
    ProgressBarStep(icon: Icons.person_outline, label: 'Profile'),
    ProgressBarStep(icon: Icons.article_outlined, label: 'Charter'),
    ProgressBarStep(icon: Icons.star_outline, label: 'Ratings'),
    ProgressBarStep(icon: Icons.chat_bubble_outline, label: 'Feedback'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<ProgressBarStep> get _steps {
    if (widget.customSteps != null && widget.customSteps!.length == widget.totalSteps) {
      return widget.customSteps!;
    }
    // Return appropriate subset of default steps
    return _defaultSteps.take(widget.totalSteps).toList();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final circleSize = widget.isMobile ? 36.0 : 44.0;
    final iconSize = widget.isMobile ? 18.0 : 22.0;
    final fontSize = widget.isMobile ? 9.0 : 11.0;

    return Column(
      children: [
        Row(
          children: List.generate(steps.length * 2 - 1, (index) {
            // Even indices are circles, odd indices are connecting lines
            if (index.isEven) {
              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex < widget.currentStep - 1;
              final isActive = stepIndex == widget.currentStep - 1;
              
              return _buildStepCircle(
                step: steps[stepIndex],
                isCompleted: isCompleted,
                isActive: isActive,
                circleSize: circleSize,
                iconSize: iconSize,
              );
            } else {
              final lineIndex = index ~/ 2;
              final isCompleted = lineIndex < widget.currentStep - 1;
              
              return _buildConnectingLine(
                isCompleted: isCompleted,
              );
            }
          }),
        ),
        SizedBox(height: widget.isMobile ? 6 : 8),
        // Step labels
        Row(
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isEven) {
              final stepIndex = index ~/ 2;
              final isActive = stepIndex == widget.currentStep - 1;
              final isCompleted = stepIndex < widget.currentStep - 1;
              
              return _buildStepLabel(
                label: steps[stepIndex].label,
                isActive: isActive,
                isCompleted: isCompleted,
                fontSize: fontSize,
              );
            } else {
              return Expanded(child: Container());
            }
          }),
        ),
      ],
    );
  }

  Widget _buildStepCircle({
    required ProgressBarStep step,
    required bool isCompleted,
    required bool isActive,
    required double circleSize,
    required double iconSize,
  }) {
    final completedColor = const Color(0xFF00C853);
    final activeColor = const Color(0xFF0099FF);
    final pendingColor = Colors.white.withValues(alpha: 0.3);

    Widget circleContent = AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? completedColor
            : isActive
                ? activeColor
                : pendingColor,
        border: Border.all(
          color: isCompleted
              ? completedColor
              : isActive
                  ? activeColor
                  : Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : isCompleted
                ? [
                    BoxShadow(
                      color: completedColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: isCompleted
              ? Icon(
                  Icons.check,
                  key: const ValueKey('check'),
                  color: Colors.white,
                  size: iconSize,
                )
              : Icon(
                  step.icon,
                  key: ValueKey(step.icon),
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
                  size: iconSize,
                ),
        ),
      ),
    );

    // Add pulse animation for active step
    if (isActive) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: circleContent,
      );
    }

    return circleContent;
  }

  Widget _buildConnectingLine({required bool isCompleted}) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 2 : 4),
        child: Stack(
          children: [
            // Background line
            Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            // Animated fill line
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              height: 3,
              width: isCompleted ? double.infinity : 0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF36A0E1)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepLabel({
    required String label,
    required bool isActive,
    required bool isCompleted,
    required double fontSize,
  }) {
    return SizedBox(
      width: widget.isMobile ? 50 : 60,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          color: isActive || isCompleted
              ? Colors.white
              : Colors.white.withValues(alpha: 0.6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Represents a single step in the survey progress
class ProgressBarStep {
  final IconData icon;
  final String label;

  const ProgressBarStep({
    required this.icon,
    required this.label,
  });
}
