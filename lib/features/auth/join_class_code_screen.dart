import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/class_section.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/tactile_feedback.dart';

/// Dashed perforation divider for ticket-style card
class DashedDividerPainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedDividerPainter({
    required this.color,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedDividerPainter oldDelegate) =>
      color != oldDelegate.color;
}

class JoinClassCodeScreen extends ConsumerStatefulWidget {
  const JoinClassCodeScreen({super.key});

  @override
  ConsumerState<JoinClassCodeScreen> createState() =>
      _JoinClassCodeScreenState();
}

class _JoinClassCodeScreenState extends ConsumerState<JoinClassCodeScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _admissionController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _pinController = TextEditingController();

  ClassSection? _foundClass;
  bool _isSearching = false;
  String? _searchError;
  bool _pinObscured = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _nameController.dispose();
    _rollController.dispose();
    _admissionController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    final cleaned = _codeController.text.trim().toUpperCase();
    if (cleaned.length >= 6) {
      _verifyClassCode(cleaned);
    } else {
      if (_foundClass != null || _searchError != null) {
        setState(() {
          _foundClass = null;
          _searchError = null;
        });
      }
    }
  }

  Future<void> _verifyClassCode(String code) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    final repo = ref.read(schoolRepositoryProvider);
    final cls = await repo.findClassByCode(code);

    if (!mounted) return;

    setState(() {
      _isSearching = false;
      if (cls != null) {
        _foundClass = cls;
        _searchError = null;
      } else {
        _foundClass = null;
        _searchError = 'Class code not found. Check with your Class Teacher.';
      }
    });
  }

  Future<void> _pasteCode() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
      final code = clipboardData.text!.trim().toUpperCase();
      _codeController.text = code;
    }
  }

  Future<void> _submitRegistration() async {
    if (_foundClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-char Class Code first')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final rollStr = _rollController.text.trim();
    final parentName = _parentNameController.text.trim();
    final parentPhone = _parentPhoneController.text.trim();
    final pin = _pinController.text.trim();

    if (name.isEmpty || rollStr.isEmpty || pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill student name, roll number, and 4-digit PIN'),
        ),
      );
      return;
    }

    final rollNo = int.tryParse(rollStr) ?? 1;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(schoolRepositoryProvider);
      final newStudent = await repo.registerStudentWithCode(
        classCode: _foundClass!.classCode,
        fullName: name,
        rollNo: rollNo,
        admissionNo: _admissionController.text.trim().isNotEmpty
            ? _admissionController.text.trim()
            : null,
        parentName: parentName.isNotEmpty ? parentName : 'Parent',
        parentPhone: parentPhone.isNotEmpty ? parentPhone : '+91 98765 00000',
        house: '',
        pin: pin,
      );

      // Update current student in state
      ref.read(currentStudentProvider.notifier).state = newStudent;

      // Add to linked siblings list if not present
      final siblings = ref.read(linkedSiblingsProvider);
      if (!siblings.any((s) => s.id == newStudent.id)) {
        ref.read(linkedSiblingsProvider.notifier).state = [...siblings, newStudent];
      }

      ref.read(activeRoleProvider.notifier).state = 'student';

      // Persist session across app restarts
      await SessionService.saveStudentSession(newStudent);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('🎉 Joined ${_foundClass!.displayName}! Welcome, $name!'),
        ),
      );

      context.go(AppRoutes.studentHome);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Text('Join Class with Code', style: AppTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.welcome),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ticket-Style Card with Perforation Divider
              _buildTicketCard(),

              const SizedBox(height: 20),

              // Instant Verification Banner
              if (_isSearching)
                _buildSearchingBanner()
              else if (_foundClass != null)
                _buildFoundClassBanner()
              else if (_searchError != null)
                _buildErrorBanner(),

              const SizedBox(height: 24),

              // Student Profile Form (Reveals upon Class verification)
              if (_foundClass != null) ...[
                Text('Student Profile Details', style: AppTypography.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Enter details as recorded in school admissions',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 16),

                _buildProfileForm(),

                const SizedBox(height: 28),

                // Primary Submit CTA
                TactileFeedback(
                  onTap: _isSubmitting ? null : _submitRegistration,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x334F46E5),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Complete Registration & Enter Class',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  LucideIcons.arrowRight,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top ticket stub: Instructions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    LucideIcons.ticket,
                    color: AppColors.brandPrimary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enter 6-Char Class Code', style: AppTypography.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Your Homeroom Class Teacher shared this on WhatsApp or blackboard.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dashed Perforation Divider
          Row(
            children: [
              // Left cutout notch
              Container(
                width: 12,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.canvasBackground,
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 24,
                  child: CustomPaint(
                    painter: DashedDividerPainter(color: AppColors.cardBorder),
                  ),
                ),
              ),
              // Right cutout notch
              Container(
                width: 12,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.canvasBackground,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                ),
              ),
            ],
          ),

          // Bottom ticket body: Input field & Paste pill
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Big JetBrains Mono Code Input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _foundClass != null
                          ? AppColors.success
                          : AppColors.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4.0,
                      color: AppColors.inkPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '8B-K9X2',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4.0,
                        color: AppColors.inkMuted,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Instant Paste Button Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TactileFeedback(
                      onTap: _pasteCode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.clipboard,
                              size: 15,
                              color: AppColors.brandPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Paste Class Code',
                              style: AppTypography.pillLabel.copyWith(
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text('Verifying class code...', style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildFoundClassBanner() {
    final cls = _foundClass!;
    return AnimatedContainer(
      duration: AppMotion.durationStandard,
      curve: AppMotion.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.check, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '🎉 Found ${cls.displayName}',
                      style: AppTypography.titleMedium.copyWith(
                        color: const Color(0xFF065F46),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cls.academicYear,
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF065F46),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Class Teacher: ${cls.classTeacherName ?? 'Mr. Ramesh Sharma'}',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF047857),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, color: AppColors.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _searchError!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full Name
          _buildFormField(
            label: 'Student Full Name',
            controller: _nameController,
            hint: 'Enter student full name',
            icon: LucideIcons.user,
          ),
          const SizedBox(height: 16),

          // Roll No & Admission No
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildFormField(
                  label: 'Roll Number',
                  controller: _rollController,
                  hint: 'Enter roll number',
                  icon: LucideIcons.hash,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildFormField(
                  label: 'Admission No. (Optional)',
                  controller: _admissionController,
                  hint: 'Enter admission number',
                  icon: LucideIcons.fileText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Parent Name & Phone
          _buildFormField(
            label: 'Parent / Guardian Name',
            controller: _parentNameController,
            hint: 'Enter parent / guardian name',
            icon: LucideIcons.users,
          ),
          const SizedBox(height: 16),

          _buildFormField(
            label: 'Parent Phone Number',
            controller: _parentPhoneController,
            hint: '+91 98765 43210',
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),



          // 4-Digit Secret PIN
          Text('4-Digit Secret Login PIN', style: AppTypography.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Keep this safe! Used for returning student login.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 10),
          Container(
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
                    controller: _pinController,
                    obscureText: _pinObscured,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                    decoration: const InputDecoration(
                      hintText: '••••',
                      counterText: '',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _pinObscured ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 18,
                    color: AppColors.inkMuted,
                  ),
                  onPressed: () {
                    setState(() => _pinObscured = !_pinObscured);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.inkMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkMuted,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
