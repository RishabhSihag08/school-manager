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

/// Dashed perforation divider for ticket-style card with clean edge notches
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

/// Polish join_class_code_screen.dart:
/// - Class Code ticket with JetBrains Mono auto-formatting boxes (8B-K9X2)
/// - Clipboard paste button (48x48dp target)
/// - Dashed custom painter divider with circular punch-out notches
/// - Sliding Emerald celebration confirmation card when 6 chars are entered
/// - Clean student profile form preserving exact test IDs and form fields
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
  final _codeFocusNode = FocusNode();

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
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    final raw = _codeController.text.trim().toUpperCase();
    final cleanAlphaNum = raw.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (raw.length >= 6 || cleanAlphaNum.length >= 6) {
      _verifyClassCode(raw);
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
    var cls = await repo.findClassByCode(code);
    if (cls == null && code.length == 6 && !code.contains('-')) {
      final withHyphen = '${code.substring(0, 2)}-${code.substring(2)}';
      cls = await repo.findClassByCode(withHyphen);
    }

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
      _codeController.selection = TextSelection.fromPosition(
        TextPosition(offset: _codeController.text.length),
      );
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
        leading: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.welcome),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ticket-Style Card with Perforation Divider & Auto-formatting Boxes
              _buildTicketCard(),

              const SizedBox(height: 18),

              // Instant Verification / Sliding Emerald Celebration Card
              if (_isSearching)
                _buildSearchingBanner()
              else if (_foundClass != null)
                _buildFoundClassCelebrationCard()
              else if (_searchError != null)
                _buildErrorBanner(),

              const SizedBox(height: 24),

              // Student Profile Form (Reveals upon Class verification)
              if (_foundClass != null) ...[
                Text(
                  'Student Profile Details',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter details as recorded in school admissions',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                _buildProfileForm(),

                const SizedBox(height: 28),

                // Primary Submit CTA with 48dp+ touch target and tactile feedback
                TactileFeedback(
                  onTap: _isSubmitting ? null : _submitRegistration,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
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
                const SizedBox(height: 28),
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
            blurRadius: 12,
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.brandPrimary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.ticket,
                      color: AppColors.brandPrimary,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter 6-Char Class Code',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your Homeroom Class Teacher shared this on WhatsApp or blackboard.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.inkSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dashed Perforation Divider with Circular Notches
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

          // Bottom ticket body: JetBrains Mono Auto-formatting Boxes & Paste Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // JetBrains Mono Auto-formatting Code Boxes (8B-K9X2)
                _buildAutoFormattingBoxes(),

                const SizedBox(height: 16),

                // Clipboard Paste Button Pill (48dp touch target)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TactileFeedback(
                      onTap: _pasteCode,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.brandPrimary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.clipboard,
                              size: 16,
                              color: AppColors.brandPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Paste Class Code',
                              style: AppTypography.pillLabel.copyWith(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// JetBrains Mono auto-formatting boxes:
  /// Renders 6 distinct visual character boxes + separator dash (8B-K9X2)
  /// with a transparent overlay TextField so typing and 'tester.enterText(find.byType(TextField).first, ...)'
  /// works seamlessly.
  Widget _buildAutoFormattingBoxes() {
    return AnimatedBuilder(
      animation: _codeController,
      builder: (context, _) {
        final rawText = _codeController.text.trim().toUpperCase();
        final clean = rawText.replaceAll(RegExp(r'[^A-Z0-9]'), '');

        // Extract 6 character slots (slot 0,1 then '-' then slot 2,3,4,5)
        final char0 = clean.isNotEmpty ? clean[0] : '';
        final char1 = clean.length > 1 ? clean[1] : '';
        final char2 = clean.length > 2 ? clean[2] : '';
        final char3 = clean.length > 3 ? clean[3] : '';
        final char4 = clean.length > 4 ? clean[4] : '';
        final char5 = clean.length > 5 ? clean[5] : '';

        final isVerified = _foundClass != null;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1: Visual Bento JetBrains Mono Character Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCharBox(char0, isVerified, 0, clean.length),
                const SizedBox(width: 6),
                _buildCharBox(char1, isVerified, 1, clean.length),
                const SizedBox(width: 8),
                // Separator Hyphen
                Text(
                  '–',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isVerified ? AppColors.success : AppColors.inkMuted,
                  ),
                ),
                const SizedBox(width: 8),
                _buildCharBox(char2, isVerified, 2, clean.length),
                const SizedBox(width: 6),
                _buildCharBox(char3, isVerified, 3, clean.length),
                const SizedBox(width: 6),
                _buildCharBox(char4, isVerified, 4, clean.length),
                const SizedBox(width: 6),
                _buildCharBox(char5, isVerified, 5, clean.length),
              ],
            ),

            // Layer 2: The primary TextField (tested via find.byType(TextField).first)
            // Positioned right across the boxes to capture clicks, pastes, and tests.
            Positioned.fill(
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  controller: _codeController,
                  focusNode: _codeFocusNode,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCharBox(String char, bool isVerified, int index, int currentLen) {
    final hasChar = char.isNotEmpty;
    final isCurrentSlot = index == currentLen && !isVerified;

    Color bgColor = AppColors.secondarySurface;
    Color borderColor = AppColors.cardBorder;
    Color textColor = AppColors.inkPrimary;

    if (isVerified) {
      bgColor = AppColors.successBg;
      borderColor = AppColors.success;
      textColor = const Color(0xFF065F46);
    } else if (hasChar) {
      bgColor = Colors.white;
      borderColor = AppColors.brandPrimary;
      textColor = AppColors.inkPrimary;
    } else if (isCurrentSlot) {
      borderColor = AppColors.brandPrimary.withValues(alpha: 0.5);
    }

    return Container(
      width: 42,
      height: 54,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: hasChar || isVerified ? 1.8 : 1.2,
        ),
        boxShadow: hasChar
            ? const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: hasChar
            ? Text(
                char,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              )
            : (isCurrentSlot
                ? Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  )
                : const SizedBox.shrink()),
      ),
    );
  }

  Widget _buildSearchingBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          const SizedBox(width: 14),
          Text(
            'Verifying class code...',
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Sliding Emerald Celebration Confirmation Card
  Widget _buildFoundClassCelebrationCard() {
    final cls = _foundClass!;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: AppMotion.durationStandard,
      curve: AppMotion.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1410B981),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.checkCheck, color: Colors.white, size: 22),
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
                                '🎉 Found ${cls.displayName}',
                                style: AppTypography.titleMedium.copyWith(
                                  color: const Color(0xFF065F46),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                cls.academicYear,
                                style: GoogleFonts.jetBrainsMono(
                                  color: const Color(0xFF065F46),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Class Teacher: ${cls.classTeacherName?.isNotEmpty == true ? cls.classTeacherName! : 'Not Assigned'}',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF047857),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
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
          Text(
            '4-Digit Secret Login PIN',
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep this safe! Used for returning student login.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.inkSecondary),
          ),
          const SizedBox(height: 10),
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
                    controller: _pinController,
                    obscureText: _pinObscured,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                    decoration: const InputDecoration(
                      hintText: '••••',
                      counterText: '',
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
                    onPressed: () {
                      setState(() => _pinObscured = !_pinObscured);
                    },
                  ),
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
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
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
              Icon(icon, size: 18, color: AppColors.inkMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkPrimary,
                  ),
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
