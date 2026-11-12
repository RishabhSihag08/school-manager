import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/school_manager_logo.dart';
import '../../core/widgets/tactile_feedback.dart';

/// Modern Role-Selection Onboarding Screen
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String? _selectedRole;

  Future<void> _selectRoleAndProceed(String role, String targetRoute) async {
    setState(() => _selectedRole = role);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_onboarding', true);
      await prefs.setString('preferred_role', role);
    } catch (_) {}

    ref.read(activeRoleProvider.notifier).state = role;
    if (mounted) {
      context.go(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SchoolManagerLogo(size: 26),
            const SizedBox(width: 10),
            Text(AppConfig.appName, style: AppTypography.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            tooltip: 'App Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Hero
                      _buildHeaderHero(),

                      const SizedBox(height: 28),

                      // Section Title
                      Text(
                        'Select Your Role to Continue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Role Cards
                      if (isWide) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildStudentCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTeacherCard()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStaffCard(),
                      ] else ...[
                        _buildStudentCard(),
                        const SizedBox(height: 16),
                        _buildTeacherCard(),
                        const SizedBox(height: 16),
                        _buildStaffCard(),
                      ],

                      const SizedBox(height: 32),

                      // Help & Academic Session Footer
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderHero() {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.sparkles, size: 14, color: AppColors.brandPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Unified Digital Campus',
                      style: GoogleFonts.inter(
                        color: AppColors.brandPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  AppConfig.currentAcademicYear,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.inkSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Welcome to ${AppConfig.appName}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.inkPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your seamless companion for classroom connection, daily homeroom attendance, instant timetables, and academic notices.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard() {
    final isSelected = _selectedRole == 'student';
    return BentoCard(
      padding: const EdgeInsets.all(0),
      borderColor: isSelected ? AppColors.brandPrimary : AppColors.cardBorder,
      borderWidth: isSelected ? 2.0 : 1.0,
      onTap: () => _selectRoleAndProceed('student', AppRoutes.welcome),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.user,
                    color: AppColors.brandPrimary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Student / Parent', style: AppTypography.titleLarge),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.coralLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Instant Access',
                              style: GoogleFonts.inter(
                                color: AppColors.coralStreak,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Class Code & Student Portal',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: AppColors.inkMuted),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Join your class section with a 6-character code, check daily attendance calendar, view homework, timetables, and exam results.',
              style: AppTypography.bodySmall.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),
            TactileFeedback(
              onTap: () => _selectRoleAndProceed('student', AppRoutes.welcome),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continue as Student / Parent',
                        style: AppTypography.labelLarge.copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherCard() {
    final isSelected = _selectedRole == 'teacher';
    return BentoCard(
      padding: const EdgeInsets.all(0),
      borderColor: isSelected ? const Color(0xFF059669) : AppColors.cardBorder,
      borderWidth: isSelected ? 2.0 : 1.0,
      onTap: () => _selectRoleAndProceed('teacher', AppRoutes.welcome),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.userCheck,
                    color: Color(0xFF059669),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Teacher', style: AppTypography.titleLarge),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Faculty',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF065F46),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Homeroom & Subject Portal',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: AppColors.inkMuted),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Conduct 30-second homeroom attendance, post class circulars, broadcast multimedia homework, and manage class join codes.',
              style: AppTypography.bodySmall.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),
            TactileFeedback(
              onTap: () => _selectRoleAndProceed('teacher', AppRoutes.welcome),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Teacher Sign In',
                        style: AppTypography.labelLarge.copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard() {
    final isSelected = _selectedRole == 'admin';
    return BentoCard(
      padding: const EdgeInsets.all(0),
      borderColor: isSelected ? const Color(0xFF7C3AED) : AppColors.cardBorder,
      borderWidth: isSelected ? 2.0 : 1.0,
      onTap: () => _selectRoleAndProceed('admin', AppRoutes.welcome),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.shieldCheck,
                    color: Color(0xFF7C3AED),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Staff & Administration', style: AppTypography.titleLarge),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Management',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF5B21B6),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Principal Office & Administration',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: AppColors.inkMuted),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Publish school-wide announcements, configure class sections, allocate teachers, and process student exam marks via the Excel wizard.',
              style: AppTypography.bodySmall.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),
            TactileFeedback(
              onTap: () => _selectRoleAndProceed('admin', AppRoutes.welcome),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Office / Staff Sign In',
                        style: AppTypography.labelLarge.copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.helpCircle, size: 14, color: AppColors.inkMuted),
            const SizedBox(width: 6),
            Text(
              'Need access? Contact your school administrative office.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'v${AppConfig.currentVersion} • Production Build',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }
}
