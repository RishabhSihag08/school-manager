import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/tactile_feedback.dart';

/// Modal bottom sheet allowing parents to switch between multiple linked siblings
/// or register another child via Class Code.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStudent = ref.watch(currentStudentProvider);
    final siblings = ref.watch(linkedSiblingsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvasBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Linked Children',
                    style: AppTypography.headlineSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Switch student view or add a sibling',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              TactileFeedback(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.secondarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sibling list
          ...siblings.map((sibling) {
            final isSelected = currentStudent?.id == sibling.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: BentoCard(
                padding: const EdgeInsets.all(14),
                borderColor: isSelected ? AppColors.brandPrimary : AppColors.cardBorder,
                borderWidth: isSelected ? 2.0 : 1.0,
                onTap: () {
                  ref.read(currentStudentProvider.notifier).state = sibling;
                  Navigator.of(context).pop();
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.brandPrimaryLight,
                      child: Text(
                        sibling.fullName.isNotEmpty
                            ? sibling.fullName.substring(0, 1).toUpperCase()
                            : 'S',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.brandPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sibling.fullName,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Roll #${sibling.rollNo} • Streak: ${sibling.homeworkStreak}🔥',
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.inkSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active checkmark indicator
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.brandPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          // Add Another Child (Class Code) Action Button
          TactileFeedback(
            onTap: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.joinClass);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.brandPrimary,
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
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
  }
}
