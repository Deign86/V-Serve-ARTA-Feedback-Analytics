import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A wrapper around SingleChildScrollView that provides "flowing" physics-based animation
/// for mouse wheel events, eliminating the discrete "ticking" feel.
/// Allows standard touch dragging for mobile.
/// 
/// Performance optimized: Uses Ticker-based animation for smoother scrolling
/// on lower-end devices and avoids animation pile-up.
class SmoothScrollView extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;

  const SmoothScrollView({
    super.key,
    required this.child,
    this.controller,
    this.padding,
    this.scrollDirection = Axis.vertical,
  });

  @override
  State<SmoothScrollView> createState() => _SmoothScrollViewState();
}

class _SmoothScrollViewState extends State<SmoothScrollView>
    with SingleTickerProviderStateMixin {
  late ScrollController _controller;
  double _targetScroll = 0.0;
  
  // Ticker-based smooth scrolling for better performance
  Ticker? _ticker;
  
  // Lerp factor for smooth interpolation (higher = snappier, lower = smoother)
  // 0.15 provides a good balance between responsiveness and smoothness
  static const double _lerpFactor = 0.15;
  
  // Minimum velocity threshold to stop animation
  static const double _velocityThreshold = 0.5;
  
  // Track if we're using touch input
  bool _isTouchInput = false;
  
  // We use ClampingScrollPhysics which allows animateTo but prevents bouncing
  // Our custom wheel handler provides smooth scrolling for mouse
  ScrollPhysics _physics = const ClampingScrollPhysics();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    
    // Sync target with current position initially and add listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) {
        _targetScroll = _controller.offset;
      }
    });
    
    // Listen for external scroll changes (like animateTo) to sync _targetScroll
    _controller.addListener(_onScrollChanged);
  }
  
  void _onScrollChanged() {
    // Always sync target scroll to prevent fighting with external animations
    // This handles Scrollable.ensureVisible, animateTo, and manual scroll
    if (_controller.hasClients) {
      // Only sync if the ticker is not actively controlling the scroll
      // or if the difference is significant (external animation)
      final currentOffset = _controller.offset;
      final diff = (_targetScroll - currentOffset).abs();
      
      if (_ticker == null || !_ticker!.isActive || diff > 50) {
        _targetScroll = currentOffset;
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScrollChanged);
    _stopTicker();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _startTicker() {
    if (_ticker != null && _ticker!.isActive) return;
    
    _ticker = createTicker(_onTick);
    _ticker!.start();
  }

  void _stopTicker() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
  }

  void _onTick(Duration elapsed) {
    if (!_controller.hasClients) return;
    
    final currentOffset = _controller.offset;
    final diff = _targetScroll - currentOffset;
    
    // If we're close enough, stop the animation
    if (diff.abs() < _velocityThreshold) {
      if (currentOffset != _targetScroll) {
        _controller.jumpTo(_targetScroll);
      }
      _stopTicker();
      return;
    }
    
    // Lerp towards target for smooth animation
    // Using lerp provides consistent smoothness across frame rates
    final newOffset = currentOffset + (diff * _lerpFactor);
    _controller.jumpTo(newOffset);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (!_controller.hasClients) return;
      
      // Get scroll delta
      final delta = widget.scrollDirection == Axis.vertical 
          ? event.scrollDelta.dy 
          : event.scrollDelta.dx;
      
      // Ignore zero delta
      if (delta == 0) return;
      
      // Accumulate target with a slight multiplier for responsiveness
      _targetScroll += delta;
      
      // Clamp to extents
      final min = _controller.position.minScrollExtent;
      final max = _controller.position.maxScrollExtent;
      _targetScroll = _targetScroll.clamp(min, max);
      
      // Start smooth scrolling using ticker
      _startTicker();
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    final isTouch = event.kind == PointerDeviceKind.touch || 
                    event.kind == PointerDeviceKind.stylus;
    
    // Only update state if input type actually changed
    if (isTouch != _isTouchInput) {
      _isTouchInput = isTouch;
      
      if (isTouch) {
        // Touch: Stop any ongoing smooth scroll and enable physics
        _stopTicker();
        setState(() {
          _physics = const BouncingScrollPhysics();
        });
      } else {
        // Mouse/Trackpad: Use ClampingScrollPhysics to allow programmatic scrolling
        // but our custom wheel handler provides smooth scrolling
        setState(() {
          _physics = const ClampingScrollPhysics();
        });
      }
    }
    
    // Sync target with current offset
    if (_controller.hasClients) {
      _targetScroll = _controller.offset;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      onPointerDown: _handlePointerDown,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // If the user drags manually (Touch), we must sync the target
          // so the next wheel event starts from the correct place.
          if (notification is ScrollUpdateNotification && 
              notification.dragDetails != null && 
              _controller.hasClients) {
            _targetScroll = _controller.offset;
          }
          return false;
        },
        child: SingleChildScrollView(
          controller: _controller,
          physics: _physics,
          padding: widget.padding,
          scrollDirection: widget.scrollDirection,
          child: widget.child,
        ),
      ),
    );
  }
}
