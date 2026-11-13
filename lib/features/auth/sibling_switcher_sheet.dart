import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/student.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/tactile_feedback.dart';

/// Modal bottom sheet allowing parents to switch between multiple linked siblings
/// or register another child via Class Code.
/// Follows Impeccable's 'onboard', 'animate', and 'polish' principles:
/// - Smooth iOS-style bottom sheet drawer (AppMotion.easeDrawer)
/// - Active child badge
/// - 1-tap switch physics with Emil Kowalski tactile scale
class SiblingSwitcherSheet extends ConsumerWidget {
  const SiblingSwitcherSheet({super.key});

  /// Static helper to display the sheet with standard iOS-like physics
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SiblingSwitcherSheet(),
    );
  }

  void _onSelectSibling(BuildContext context, WidgetRef ref, Student sibling) {
    ref.read(currentStudentProvider.notifier).state = sibling;
    SessionService.saveStudentSession(sibling);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStudent = ref.watch(currentStudentProvider);
    final siblings = ref.watch(linkedSiblingsProvider);
    final reduceMotion = AppMotion.shouldReduceMotion(context);

    Widget sheetBody = Container(
      decoration: const BoxDecoration(
        color: AppColors.canvasBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // iOS-Style Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header with 48dp Close Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Linked Children',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Switch student view or add a sibling',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: TactileFeedback(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.secondarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sibling list or Tactile Empty State
          if (siblings.isEmpty)
            AppEmptyState(
              icon: LucideIcons.users,
              title: 'No Linked Children Yet',
              subtitle: 'Join a class using your child\'s Class Code to link them to your family account.',
              ctaLabel: '+ Add Child with Class Code',
              onCtaPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.joinClass);
              },
            )
          else ...[
            ...siblings.map((sibling) {
              final isSelected = currentStudent?.id == sibling.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: BentoCard(
                  padding: const EdgeInsets.all(16),
                  borderColor: isSelected ? AppColors.brandPrimary : AppColors.cardBorder,
                  borderWidth: isSelected ? 2.0 : 1.0,
                  onTap: () => _onSelectSibling(context, ref, sibling),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: Row(
                      children: [
                        // Avatar Badge with Initials
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brandPrimary
                                : AppColors.brandPrimaryLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brandPrimary
                                  : AppColors.brandPrimary.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              sibling.fullName.isNotEmpty
                                  ? sibling.fullName.substring(0, 1).toUpperCase()
                                  : 'S',
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected ? Colors.white : AppColors.brandPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Student Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      sibling.fullName,
                                      style: AppTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  // Active Child Badge
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.successBg,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.success.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            LucideIcons.check,
                                            size: 11,
                                            color: Color(0xFF065F46),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Active Child',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF065F46),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Roll #${sibling.rollNo} • Streak: ${sibling.homeworkStreak}🔥',
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.inkSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 1-Tap Switch Chevron / Checkmark Indicator
                        const SizedBox(width: 8),
                        if (isSelected)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.brandPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          )
                        else
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 20,
                            color: AppColors.inkMuted,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 10),

          // Add Another Child (Class Code) Action Button (48dp+ height, tactile physics)
          TactileFeedback(
            onTap: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.joinClass);
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 50),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.brandPrimary,
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.plus,
                    color: AppColors.brandPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+ Add Another Child (Class Code)',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (reduceMotion) {
      return sheetBody;
    }

    // Smooth iOS-style drawer entrance physics with AppMotion.easeDrawer
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: AppMotion.durationModal,
      curve: AppMotion.easeDrawer,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1.0 - value) * 16),
          child: child,
        );
      },
      child: sheetBody,
    );
  }
}
