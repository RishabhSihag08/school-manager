import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/models.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/school_manager_logo.dart';
import '../../core/widgets/tactile_feedback.dart';

/// 2-Step Guided Onboarding & Campus Role Gateway.
/// Follows Impeccable's 'onboard', 'animate', and 'polish' principles:
/// Step 1: "What are you?" with 3 tactile Bento role cards (Student & Parent, Teacher, Admin),
///         quick demo pills, and 48x48dp touch targets.
/// Step 2: Role-focused screen with smooth micro-transitions, demo auto-fill pills,
///         Join with Class Code ticket option, and direct registration.
class WelcomeRoleScreen extends ConsumerStatefulWidget {
  const WelcomeRoleScreen({super.key});

  @override
  ConsumerState<WelcomeRoleScreen> createState() => _WelcomeRoleScreenState();
}

class _WelcomeRoleScreenState extends ConsumerState<WelcomeRoleScreen> {
  // Step 1: null (Role selection)
  // Step 2: 'student', 'teacher', or 'admin'
  String? _selectedRole;

  // Student Login
  final _studentRollController = TextEditingController();
  final _studentPinController = TextEditingController();
  String? _studentSelectedClass;
  List<ClassSection> _availableClasses = [];
  bool _isLoadingClasses = false;

  // Staff / Teacher / Admin Login
  final _staffCodeController = TextEditingController();
  final _staffPinController = TextEditingController();
  bool _pinObscured = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadClassSections();
  }

  @override
  void dispose() {
    _studentRollController.dispose();
    _studentPinController.dispose();
    _staffCodeController.dispose();
    _staffPinController.dispose();
    super.dispose();
  }

  Future<void> _loadClassSections() async {
    setState(() => _isLoadingClasses = true);
    try {
      final repo = ref.read(schoolRepositoryProvider);
      final classes = await repo.getAllClassSections();
      if (mounted) {
        setState(() {
          _availableClasses = classes;
          if (classes.isNotEmpty) {
            _studentSelectedClass = classes.first.id;
          }
          _isLoadingClasses = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingClasses = false);
    }
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

    final selectedClassId = _studentSelectedClass ??
        (_availableClasses.isNotEmpty ? _availableClasses.first.id : null);
    if (selectedClassId == null || selectedClassId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Class & Section')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(schoolRepositoryProvider);
      final roll = int.tryParse(rollStr) ?? 1;
      final student = await repo.loginStudent(
        classSectionId: selectedClassId,
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitStaffLogin() async {
    final code = _staffCodeController.text.trim();
    final pin = _staffPinController.text.trim();

    if (code.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Login Code and PIN')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(schoolRepositoryProvider);
      final staff = await repo.loginStaff(loginCode: code, pin: pin);

      if (!mounted) return;

      if (staff != null) {
        ref.read(currentStaffProvider.notifier).state = staff;
        final role = staff['role'] as String? ?? (_selectedRole ?? 'teacher');
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
            content: Text('Credentials invalid. Please check your Code and PIN.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otaState = ref.watch(otaUpdateProvider);
    final reduceMotion = AppMotion.shouldReduceMotion(context);

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
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.settings),
                  tooltip: 'Settings & Updates',
                  onPressed: () => context.push(AppRoutes.settings),
                ),
                if (otaState.availableRelease != null)
                  Positioned(
                    top: 12,
                    right: 12,
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
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : AppMotion.durationStandard,
            switchInCurve: AppMotion.easeOut,
            switchOutCurve: AppMotion.easeInOut,
            transitionBuilder: (child, animation) {
              if (reduceMotion) return child;
              final isStep2 = child.key == const ValueKey('step2');
              final offsetBegin = isStep2 ? const Offset(0.04, 0) : const Offset(-0.04, 0);

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: offsetBegin,
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _selectedRole == null
                ? _buildStep1RoleSelection()
                : _buildStep2RoleActions(),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: "What are you?" / "Select Your Campus Role"
  // ---------------------------------------------------------------------------
  Widget _buildStep1RoleSelection() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Branding Banner
        _buildSchoolBranding(),

        const SizedBox(height: 20),

        // Section Prompt
        Text(
          'What are you?',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select your campus role to enter your personalized dashboard',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSecondary),
        ),

        const SizedBox(height: 18),

        // Bento Card 1: Student / Parent
        _buildRoleBentoCard(
          roleKey: 'student',
          title: 'Student / Parent',
          tag: 'Instant Access',
          tagColor: AppColors.brandPrimary,
          tagBg: AppColors.brandPrimaryLight,
          subtitle:
              'Join with Class Code, view daily homework, timetables, and academic report cards.',
          icon: LucideIcons.graduationCap,
          primaryColor: AppColors.brandPrimary,
          bgColor: AppColors.brandPrimaryLight,
        ),

        const SizedBox(height: 14),

        // Bento Card 2: Teacher / Faculty
        _buildRoleBentoCard(
          roleKey: 'teacher',
          title: 'Teacher / Faculty',
          tag: 'Educator',
          tagColor: const Color(0xFF059669),
          tagBg: const Color(0xFFECFDF5),
          subtitle:
              'Take attendance in 30 seconds, assign homework, upload syllabus, and manage students.',
          icon: LucideIcons.bookOpen,
          primaryColor: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
        ),

        const SizedBox(height: 14),

        // Bento Card 3: Staff / Administration
        _buildRoleBentoCard(
          roleKey: 'admin',
          title: 'Staff / Administration',
          tag: 'Administration',
          tagColor: const Color(0xFF7C3AED),
          tagBg: const Color(0xFFF5F3FF),
          subtitle:
              'Manage class sections, oversee student rosters, edit records, and export Excel reports.',
          icon: LucideIcons.shieldCheck,
          primaryColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF5F3FF),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRoleBentoCard({
    required String roleKey,
    required String title,
    required String tag,
    required Color tagColor,
    required Color tagBg,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
    required Color bgColor,
  }) {
    return BentoCard(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.cardBorder,
      onTap: () {
        setState(() {
          _selectedRole = roleKey;
        });
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(icon, color: primaryColor, size: 26),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tagColor.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tagColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Selected Role Choices (Log In OR Create Account)
  // ---------------------------------------------------------------------------
  Widget _buildStep2RoleActions() {
    final meta = _getRoleMeta(_selectedRole!);

    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Navigation Bar: "<- Change Role" + Active Role Pill (48dp touch targets)
        _buildStep2TopBar(meta),

        const SizedBox(height: 20),

        // Section: "1. Log In to Existing Account"
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: meta.bg,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.logIn, size: 16, color: meta.color),
            ),
            const SizedBox(width: 8),
            Text('Log In to Existing Account', style: AppTypography.titleMedium),
          ],
        ),
        const SizedBox(height: 12),

        // Role-Specific Login Component
        if (_selectedRole == 'student')
          _buildStudentLoginOptions()
        else
          _buildStaffLoginCard(meta),

        const SizedBox(height: 24),

        // Section: "2. Create New Account"
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.brandPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.userPlus, size: 16, color: AppColors.brandPrimary),
            ),
            const SizedBox(width: 8),
            Text('Create New Account', style: AppTypography.titleMedium),
          ],
        ),
        const SizedBox(height: 12),

        // Create Account Action Card
        _buildCreateAccountCard(meta),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStep2TopBar(({Color color, Color bg, IconData icon, String title}) meta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 48dp minimum touch target for Change Role button
          TactileFeedback(
            onTap: () => setState(() => _selectedRole = null),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.arrowLeft, size: 16, color: AppColors.inkPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Change Role',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: meta.bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: meta.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(meta.icon, size: 14, color: meta.color),
                const SizedBox(width: 6),
                Text(
                  meta.title,
                  style: GoogleFonts.plusJakartaSans(
                    color: meta.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Student Login Options (Class Code Ticket OR Roll No + PIN) ---
  Widget _buildStudentLoginOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Option 1A: Join with Class Code Ticket
        BentoCard(
          padding: const EdgeInsets.all(18),
          borderColor: AppColors.brandPrimary,
          borderWidth: 1.5,
          onTap: () => context.push(AppRoutes.joinClass),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.ticket, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Join with Class Code',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandPrimary,
                              ),
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
                      const SizedBox(height: 2),
                      Text(
                        'Have a class code? Enter class directly',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.arrowRight, size: 20, color: AppColors.brandPrimary),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Option 1B: Roll No + PIN Login Box
        BentoCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.userCheck, color: AppColors.brandPrimary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Returning Student (Roll No + PIN)',
                      style: AppTypography.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: _isLoadingClasses
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _availableClasses.any((c) => c.id == _studentSelectedClass)
                                    ? _studentSelectedClass
                                    : (_availableClasses.isNotEmpty ? _availableClasses.first.id : null),
                                isExpanded: true,
                                hint: const Text('Select Class'),
                                items: _availableClasses.map((c) {
                                  return DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.displayName),
                                  );
                                }).toList(),
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
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _studentRollController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            hintText: 'Roll #',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _studentPinController,
                        obscureText: _pinObscured,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: _pinObscured ? 4 : 2,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter 4-digit PIN',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      child: IconButton(
                        icon: Icon(
                          _pinObscured ? LucideIcons.eyeOff : LucideIcons.eye,
                          size: 18,
                          color: AppColors.inkMuted,
                        ),
                        onPressed: () => setState(() => _pinObscured = !_pinObscured),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Submit CTA button with 48dp min height and tactile feedback
              TactileFeedback(
                onTap: _isSubmitting ? null : _submitStudentLogin,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x264F46E5),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Log In to Student Shell',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Staff / Teacher / Admin Login Card ---
  Widget _buildStaffLoginCard(({Color color, Color bg, IconData icon, String title}) meta) {
    final isTeacher = _selectedRole == 'teacher';
    final codeHint = isTeacher ? 'Enter teacher login code' : 'Enter admin login code';

    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(meta.icon, color: meta.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${meta.title} Login',
                  style: AppTypography.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Center(
              child: TextField(
                controller: _staffCodeController,
                decoration: InputDecoration(
                  hintText: codeHint,
                  border: InputBorder.none,
                  prefixIcon: Icon(LucideIcons.idCard, size: 18, color: meta.color),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.lock, size: 18, color: AppColors.inkMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _staffPinController,
                    obscureText: _pinObscured,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: _pinObscured ? 4 : 2,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter 4-digit PIN',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  child: IconButton(
                    icon: Icon(
                      _pinObscured ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 18,
                      color: AppColors.inkMuted,
                    ),
                    onPressed: () => setState(() => _pinObscured = !_pinObscured),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TactileFeedback(
            onTap: _isSubmitting ? null : _submitStaffLogin,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: meta.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: meta.color.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Log In as ${meta.title}',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Create New Account Card (Preconfigured for Selected Role) ---
  Widget _buildCreateAccountCard(({Color color, Color bg, IconData icon, String title}) meta) {
    String createSubtitle = '';
    if (_selectedRole == 'student') {
      createSubtitle = 'Register a new student with Class Code and parent contact';
    } else if (_selectedRole == 'teacher') {
      createSubtitle = 'Register teacher credentials and select your teaching subject';
    } else {
      createSubtitle = 'Register administration profile with School Master Key';
    }

    return BentoCard(
      padding: const EdgeInsets.all(18),
      onTap: () => context.push('${AppRoutes.createAccount}?role=$_selectedRole'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: meta.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: meta.color.withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.userPlus,
                  color: meta.color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New ${meta.title} Account',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    createSubtitle,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }

  // --- School Branding Header Card ---
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
                  border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2)),
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
            style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSecondary),
          ),
        ],
      ),
    );
  }

  ({String title, IconData icon, Color color, Color bg}) _getRoleMeta(String role) {
    switch (role) {
      case 'teacher':
        return (
          title: 'Teacher / Faculty',
          icon: LucideIcons.bookOpen,
          color: const Color(0xFF059669),
          bg: const Color(0xFFECFDF5),
        );
      case 'admin':
        return (
          title: 'Staff / Administration',
          icon: LucideIcons.shieldCheck,
          color: const Color(0xFF7C3AED),
          bg: const Color(0xFFF5F3FF),
        );
      case 'student':
      default:
        return (
          title: 'Student / Parent',
          icon: LucideIcons.graduationCap,
          color: AppColors.brandPrimary,
          bg: AppColors.brandPrimaryLight,
        );
    }
  }
}
