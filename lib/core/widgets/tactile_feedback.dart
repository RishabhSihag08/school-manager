import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_motion.dart';

/// Wraps any widget with Emil Kowalski-inspired tactile feedback:
/// scales to 0.97 on press with easeOut curve and haptic vibration,
/// respecting reduced-motion accessibility settings.
class TactileFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressScale;
  final Duration duration;
  final bool enableHaptics;

  const TactileFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressScale = AppMotion.pressScale,
    this.duration = AppMotion.durationPress,
    this.enableHaptics = true,
  });

  @override
  State<TactileFeedback> createState() => _TactileFeedbackState();
}

class _TactileFeedbackState extends State<TactileFeedback> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    setState(() => _isPressed = true);
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onTap == null && widget.onLongPress == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.shouldReduceMotion(context);
    final scale = (_isPressed && !reduceMotion) ? widget.pressScale : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: scale,
        duration: reduceMotion ? Duration.zero : widget.duration,
        curve: AppMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}
