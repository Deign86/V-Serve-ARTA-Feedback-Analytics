import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A wrapper around SingleChildScrollView that provides "flowing" physics-based animation
/// for mouse wheel events, eliminating the discrete "ticking" feel.
/// allows standard touch dragging for mobile.
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

class _SmoothScrollViewState extends State<SmoothScrollView> {
  late ScrollController _controller;
  double _targetScroll = 0.0;
  
  // We disable the native scroll physics for Mouse to prevent "ticking"
  // But we enable it for Touch to allow dragging.
  ScrollPhysics _physics = const NeverScrollableScrollPhysics();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    
    // Sync target with current position initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) {
        _targetScroll = _controller.offset;
      }
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (!_controller.hasClients) return;
      
      // Update target based on delta
      // We use a multiplier to make it feel responsive but smooth
      final delta = event.scrollDelta.dy;
      // If delta is 0 (horizontal?), ignore for vertical
      if (widget.scrollDirection == Axis.vertical && delta == 0) return;
      
      // Accumulate target
      _targetScroll += delta;
      
      // Clamp to extents
      final min = _controller.position.minScrollExtent;
      final max = _controller.position.maxScrollExtent;
      _targetScroll = _targetScroll.clamp(min, max);
      
      // Animate smoothly to the new target
      _controller.animateTo(
        _targetScroll,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    // If user touches screen, enable standard physics logic (Drag)
    // If mouse, disable standard logic to prevent "tick" double scroll
    if (event.kind == PointerDeviceKind.touch || event.kind == PointerDeviceKind.stylus) {
      setState(() {
        _physics = const BouncingScrollPhysics();
      });
    } else {
      // Mouse/Trackpad: We handle scroll manually via Signal
      setState(() {
        _physics = const NeverScrollableScrollPhysics();
      });
      // Also update target to current offset in case they used drag previously
      if (_controller.hasClients) {
        _targetScroll = _controller.offset;
      }
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
