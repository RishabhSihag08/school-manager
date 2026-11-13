import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'bento_card.dart';
import 'tactile_feedback.dart';

/// Reusable tactile empty state widget following Impeccable design principles.
/// Used across School Manager to turn empty screens into actionable onboarding moments.
class AppEmptyState extends StatelessWidget {
  /// Primary icon representing the empty entity
  final IconData? icon;

  /// Custom widget for icon/badge area (takes precedence over [icon])
  final Widget? customIcon;

  /// Color for the icon (defaults to [AppColors.inkSecondary])
  final Color? iconColor;

  /// Background circle/badge color for the icon
  final Color? iconBackgroundColor;

  /// Bold main headline
  final String title;

  /// Descriptive explanation explaining what belongs here and why it's valuable
  final String subtitle;

  /// Optional primary action label (e.g. "+ Add Homework", "Join Class")
  final String? ctaLabel;

  /// Callback when primary CTA is tapped
  final VoidCallback? onCtaPressed;

  /// Optional icon to render inside the primary CTA button
  final IconData? ctaIcon;

  /// Optional secondary action label (e.g. "Learn more", "Refresh")
  final String? secondaryCtaLabel;

  /// Callback when secondary CTA is tapped
  final VoidCallback? onSecondaryCtaPressed;

  /// Whether to render inside a white tactile [BentoCard] container
  final bool isCard;

  /// Internal padding for the empty state
  final EdgeInsetsGeometry padding;

  /// Maximum content width for responsive readability
  final double maxWidth;

  const AppEmptyState({
    super.key,
    this.icon,
    this.customIcon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCtaPressed,
    this.ctaIcon,
    this.secondaryCtaLabel,
    this.onSecondaryCtaPressed,
    this.isCard = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    this.maxWidth = 420,
  });

  /// Convenience constructor matching actionLabel / onAction naming conventions
  factory AppEmptyState.action({
    Key? key,
    IconData? icon,
    Widget? customIcon,
    Color? iconColor,
    Color? iconBackgroundColor,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    IconData? actionIcon,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    bool isCard = false,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    double maxWidth = 420,
  }) {
    return AppEmptyState(
      key: key,
      icon: icon,
      customIcon: customIcon,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      title: title,
      subtitle: subtitle,
      ctaLabel: actionLabel,
      onCtaPressed: onAction,
      ctaIcon: actionIcon,
      secondaryCtaLabel: secondaryActionLabel,
      onSecondaryCtaPressed: onSecondaryAction,
      isCard: isCard,
      padding: padding,
      maxWidth: maxWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.inkSecondary;
    final effectiveIconBg = iconBackgroundColor ?? AppColors.secondarySurface;

    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tactile Icon / Badge Container
              _buildIconBadge(effectiveIconColor, effectiveIconBg),

              const SizedBox(height: 20),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkPrimary,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                  height: 1.45,
                ),
              ),

              // Primary CTA
              if (ctaLabel != null && onCtaPressed != null) ...[
                const SizedBox(height: 24),
                _buildPrimaryButton(context),
              ],

              // Secondary CTA
              if (secondaryCtaLabel != null && onSecondaryCtaPressed != null) ...[
                const SizedBox(height: 12),
                _buildSecondaryButton(context),
              ],
            ],
          ),
        ),
      ),
    );

    if (isCard) {
      return BentoCard(
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(16),
        child: content,
      );
    }

    return content;
  }

  Widget _buildIconBadge(Color fg, Color bg) {
    if (customIcon != null) return customIcon!;

    final displayIcon = icon ?? LucideIcons.inbox;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          displayIcon,
          size: 32,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return TactileFeedback(
      onTap: onCtaPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.brandPrimary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x264F46E5),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (ctaIcon != null) ...[
              Icon(ctaIcon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              ctaLabel!,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return TactileFeedback(
      onTap: onSecondaryCtaPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        alignment: Alignment.center,
        child: Text(
          secondaryCtaLabel!,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.brandPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
