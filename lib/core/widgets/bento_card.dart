import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import 'tactile_feedback.dart';

/// Tactile Bento grid card component for School Manager.
/// Provides pure white or frosted glass surface with subtle 1px border,
/// optional subtle gradient, and verified Emil Kowalski press physics (scale down to 0.97 on press).
class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final Gradient? gradient;
  final bool isGlass;
  final double glassBlur;
  final Color? glassColor;
  final double pressScale;
  final bool enableFeedback;

  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.backgroundColor = AppColors.surfaceCard,
    this.borderColor = AppColors.cardBorder,
    this.borderWidth = 1.0,
    this.borderRadius = 16.0,
    this.onTap,
    this.onLongPress,
    this.width,
    this.height,
    this.constraints,
    this.gradient,
    this.isGlass = false,
    this.glassBlur = 12.0,
    this.glassColor,
    this.pressScale = AppMotion.pressScale,
    this.enableFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = gradient != null
        ? null
        : (isGlass ? (glassColor ?? AppColors.surfaceGlass) : backgroundColor);

    final boxDecoration = BoxDecoration(
      color: effectiveColor,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );

    Widget card = Container(
      width: width,
      height: height,
      constraints: constraints,
      padding: padding,
      decoration: boxDecoration,
      child: child,
    );

    if (isGlass) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: glassBlur, sigmaY: glassBlur),
          child: card,
        ),
      );
    }

    if (margin != null) {
      card = Padding(
        padding: margin!,
        child: card,
      );
    }

    if (onTap != null || onLongPress != null) {
      card = TactileFeedback(
        onTap: onTap,
        onLongPress: onLongPress,
        pressScale: pressScale,
        enableHaptics: enableFeedback,
        child: card,
      );
    }

    return card;
  }
}
