import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/school_manager_logo.dart';
import '../../core/widgets/tactile_feedback.dart';

class WelcomeRoleScreen extends ConsumerStatefulWidget {
  const WelcomeRoleScreen({super.key});

  @override
  ConsumerState<WelcomeRoleScreen> createState() => _WelcomeRoleScreenState();
}

class _WelcomeRoleScreenState extends ConsumerState<WelcomeRoleScreen> {
  bool _showStudentLoginDialog = false;
  bool _showStaffLoginDialog = false;

  final _studentRollController = TextEditingController();
  final _studentPinController = TextEditingController();
  String _studentSelectedClass = 'class-8b';

  final _staffCodeController = TextEditingController();
  final _staffPinController = TextEditingController();

  @override
  void dispose() {
    _studentRollController.dispose();
    _studentPinController.dispose();
    _staffCodeController.dispose();
    _staffPinController.dispose();
    super.dispose();
  }

  Future<void> _submitStudentLogin() async {
    final rollStr = _studentRollController.text.trim();
    final pin = _studentPinController.text.trim();

    if (rollStr.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Roll Number and 4-digit PIN')),
      );
      return;
    }

    final repo = ref.read(schoolRepositoryProvider);
    final roll = int.tryParse(rollStr) ?? 1;
    final student = await repo.loginStudent(
      classSectionId: _studentSelectedClass,
      rollNo: roll,
      pin: pin,
    );

    if (!mounted) return;

    if (student != null) {
      ref.read(currentStudentProvider.notifier).state = student;
      ref.read(activeRoleProvider.notifier).state = 'student';
      await SessionService.saveStudentSession(student);
      if (!mounted) return;
      context.go(AppRoutes.studentHome);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Student not found. Please verify your Class, Roll Number, and PIN.'),
        ),
      );
    }
  }

  Future<void> _submitStaffLogin() async {
    final code = _staffCodeController.text.trim();
    final pin = _staffPinController.text.trim();

    if (code.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Staff Code and PIN')),
      );
      return;
    }

    final repo = ref.read(schoolRepositoryProvider);
    final staff = await repo.loginStaff(loginCode: code, pin: pin);

    if (!mounted) return;

    if (staff != null) {
      ref.read(currentStaffProvider.notifier).state = staff;
      final role = staff['role'] as String? ?? 'teacher';
      ref.read(activeRoleProvider.notifier).state = role;
      await SessionService.saveStaffSession(staff);
      if (!mounted) return;
      if (role == 'admin') {
        context.go(AppRoutes.adminDashboard);
      } else {
        context.go(AppRoutes.teacherDashboard);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Staff credentials invalid. Please check your Staff Code and PIN.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final otaState = ref.watch(otaUpdateProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Row(
          children: [
            const SchoolManagerLogo(size: 28),
            const SizedBox(width: 10),
            Text('School Manager', style: AppTypography.titleLarge),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.settings),
                tooltip: 'Settings & Updates',
                onPressed: () => context.push(AppRoutes.settings),
              ),
              if (otaState.availableRelease != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.coralStreak,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // School Branding Header
              _buildSchoolBranding(),

              const SizedBox(height: 24),

              // Primary Action: Ticket Card "Join Class with Code"
              _buildJoinClassTicket(),

              const SizedBox(height: 16),

              // Secondary Row: Returning Student Login & Staff Login
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      title: 'Student Login',
                      subtitle: 'Roll No + PIN',
                      icon: LucideIcons.userCheck,
                      color: AppColors.brandPrimary,
                      bg: AppColors.brandPrimaryLight,
                      onTap: () {
                        setState(() {
                          _showStudentLoginDialog = !_showStudentLoginDialog;
                          _showStaffLoginDialog = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionTile(
                      title: 'Staff Portal',
                      subtitle: 'Teacher / Office',
                      icon: LucideIcons.shieldCheck,
                      color: const Color(0xFF059669),
                      bg: const Color(0xFFECFDF5),
                      onTap: () {
                        setState(() {
                          _showStaffLoginDialog = !_showStaffLoginDialog;
                          _showStudentLoginDialog = false;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Create Account Card
              BentoCard(
                padding: const EdgeInsets.all(18),
                onTap: () => context.push(AppRoutes.createAccount),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.userPlus,
                        color: AppColors.brandPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Don\'t have an account?',
                            style: AppTypography.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Create new Student, Teacher or Staff profile',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, color: AppColors.inkMuted),
                  ],
                ),
              ),

              // Expandable Student Login Box
              if (_showStudentLoginDialog) ...[
                const SizedBox(height: 16),
                _buildStudentLoginCard(),
              ],

              // Expandable Staff Login Box
              if (_showStaffLoginDialog) ...[
                const SizedBox(height: 16),
                _buildStaffLoginCard(),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolBranding() {
    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SchoolManagerLogo(size: 42),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'School Manager',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Digital Campus Portal',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '2026–2027',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.brandPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),
          Text(
            'Complete School Ecosystem',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Zero-friction class code onboarding, 30-sec homeroom attendance, and live academic tracking.',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildJoinClassTicket() {
    return BentoCard(
      padding: const EdgeInsets.all(0),
      borderColor: AppColors.brandPrimary,
      borderWidth: 1.5,
      onTap: () => context.push(AppRoutes.joinClass),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF9F9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x334F46E5),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.ticket,
                    color: Colors.white,
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
                          Text(
                            'Join Class with Code',
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.coralLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Instant',
                              style: GoogleFonts.inter(
                                color: AppColors.coralStreak,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Got a 6-char code like 8B-K9X2? Tap here to enter your class with zero OTP hassle.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.brandPrimaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap to paste code & select house shield',
                    style: GoogleFonts.inter(
                      color: AppColors.brandPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    LucideIcons.arrowRight,
                    color: AppColors.brandPrimary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildStudentLoginCard() {
    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.userCheck, color: AppColors.brandPrimary, size: 20),
              const SizedBox(width: 8),
              Text('Returning Student Login', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _studentSelectedClass,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'class-8b',
                          child: Text('Class 8-B'),
                        ),
                        DropdownMenuItem(
                          value: 'class-6a',
                          child: Text('Class 6-A'),
                        ),
                        DropdownMenuItem(
                          value: 'class-7c',
                          child: Text('Class 7-C'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _studentSelectedClass = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _studentRollController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Roll #',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _studentPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '4-Digit PIN (Default: 1234)',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TactileFeedback(
            onTap: _submitStudentLogin,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Log In to Student Shell',
                  style: AppTypography.labelLarge.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () => context.push('${AppRoutes.createAccount}?role=student'),
              icon: const Icon(LucideIcons.userPlus, size: 14, color: AppColors.brandPrimary),
              label: Text(
                'Don\'t have an account? Register as Student',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffLoginCard() {
    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shieldCheck, color: Color(0xFF059669), size: 20),
              const SizedBox(width: 8),
              Text('Teacher / Staff Portal Login', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _staffCodeController,
              decoration: const InputDecoration(
                hintText: 'Staff Login Code (e.g. T-RAMESH or ADMIN-01)',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _staffPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Staff PIN (Default: 1234)',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          TactileFeedback(
            onTap: _submitStaffLogin,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Log In to Staff Portal',
                  style: AppTypography.labelLarge.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () => context.push('${AppRoutes.createAccount}?role=teacher'),
              icon: const Icon(LucideIcons.userPlus, size: 14, color: Color(0xFF059669)),
              label: Text(
                'New Teacher/Staff? Create Account',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF059669),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
