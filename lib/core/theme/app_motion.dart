import 'package:flutter/widgets.dart';

/// Emil Kowalski-inspired motion tokens for School Manager.
/// Strictly enforces no scale(0), subtle 0.97 press scale, strong easeOut curves,
/// and accessible reduced-motion gating.
class AppMotion {
  AppMotion._();

  // Custom Cubic Curves
  /// Strong ease-out for entering and UI feedback
  static const Curve easeOut = Cubic(0.23, 1.0, 0.32, 1.0);

  /// Strong ease-in-out for elements moving or morphing on screen
  static const Curve easeInOut = Cubic(0.77, 0.0, 0.175, 1.0);

  /// iOS-like drawer and bottom-sheet curve
  static const Curve easeDrawer = Cubic(0.32, 0.72, 0.0, 1.0);

  // Standard UI Durations (strictly <= 300ms for UI feel)
  static const Duration durationPress = Duration(milliseconds: 140);
  static const Duration durationFast = Duration(milliseconds: 180);
  static const Duration durationStandard = Duration(milliseconds: 240);
  static const Duration durationModal = Duration(milliseconds: 280);

  // Physicality scales (Never 0)
  static const double pressScale = 0.97;
  static const double entryInitialScale = 0.95;

  /// Check whether animations should be minimized for accessibility
  static bool shouldReduceMotion(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    return mediaQuery?.disableAnimations ?? false;
  }

  /// Get gated duration for animations
  static Duration getDuration(BuildContext context, Duration standard) {
    if (shouldReduceMotion(context)) {
      return Duration.zero;
    }
    return standard;
  }
}
