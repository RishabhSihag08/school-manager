import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/models.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/tactile_feedback.dart';

/// 30-Second Roll Call Grid for Class Teacher
/// Defaults all students to Green Present.
/// 1 tap toggles to Red Absent.
/// Long-press toggles to Amber On Leave.
class MarkAttendanceScreen extends ConsumerStatefulWidget {
  final String? classSectionId;
  final String? className;

  const MarkAttendanceScreen({
    super.key,
    this.classSectionId,
    this.className,
  });

  @override
  ConsumerState<MarkAttendanceScreen> createState() =>
      _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  List<Student> _students = [];
  final Map<String, AttendanceStatus> _attendanceState = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  late final DateTime _attendanceDate;

  String get _effectiveClassId {
    final staff = ref.read(currentStaffProvider);
    return widget.classSectionId ?? (staff?['homeroom_class_id'] as String?) ?? '';
  }

  String get _effectiveClassName {
    final staff = ref.read(currentStaffProvider);
    return widget.className ?? (staff?['homeroom_class_name'] as String?) ?? 'Class';
  }

  @override
  void initState() {
    super.initState();
    _attendanceDate = DateTime.now();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final repo = ref.read(schoolRepositoryProvider);
    final classId = _effectiveClassId;
    if (classId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final students = await repo.getStudentsForClass(classId);

    // Check if attendance already recorded for today
    final existing = await repo.getAttendanceForDate(
      classId,
      _attendanceDate,
    );
    final existingMap = {for (final a in existing) a.studentId: a.status};

    setState(() {
      _students = students;
      for (final s in students) {
        // Default to existing record or default to Present (Green)
        _attendanceState[s.id] =
            existingMap[s.id] ?? AttendanceStatus.present;
      }
      _isLoading = false;
    });
  }

  int get _presentCount => _attendanceState.values
      .where((s) => s == AttendanceStatus.present)
      .length;

  int get _absentCount => _attendanceState.values
      .where((s) => s == AttendanceStatus.absent)
      .length;

  int get _leaveCount =>
      _attendanceState.values.where((s) => s == AttendanceStatus.leave).length;

  void _onStudentTap(String studentId) {
    HapticFeedback.lightImpact();
    setState(() {
      final current = _attendanceState[studentId] ?? AttendanceStatus.present;
      if (current == AttendanceStatus.present) {
        _attendanceState[studentId] = AttendanceStatus.absent;
      } else {
        _attendanceState[studentId] = AttendanceStatus.present;
      }
    });
  }

  void _onStudentLongPress(String studentId) {
    HapticFeedback.mediumImpact();
    setState(() {
      final current = _attendanceState[studentId] ?? AttendanceStatus.present;
      if (current == AttendanceStatus.leave) {
        _attendanceState[studentId] = AttendanceStatus.present;
      } else {
        _attendanceState[studentId] = AttendanceStatus.leave;
      }
    });
  }

  void _markAllPresent() {
    HapticFeedback.selectionClick();
    setState(() {
      for (final s in _students) {
        _attendanceState[s.id] = AttendanceStatus.present;
      }
    });
  }

  Future<void> _submitAttendance() async {
    setState(() => _isSubmitting = true);
    HapticFeedback.heavyImpact();

    final repo = ref.read(schoolRepositoryProvider);
    final staff = ref.read(currentStaffProvider);
    final teacherId = staff?['id'] as String? ?? '';

    await repo.submitClassAttendance(
      classSectionId: _effectiveClassId,
      date: _attendanceDate,
      attendanceMap: _attendanceState,
      markedBy: teacherId,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCheck, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Attendance Submitted! Present: $_presentCount • Absent: $_absentCount',
                style: AppTypography.bodySmall.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, dd MMM yyyy').format(_attendanceDate);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: AppColors.canvasBackground,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('30-Second Roll Call', style: AppTypography.titleLarge),
            Text(
              '$_effectiveClassName • $dateStr',
              style:
                  AppTypography.caption.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _markAllPresent,
            icon: const Icon(LucideIcons.checkCheck,
                size: 16, color: AppColors.brandPrimary),
            label: Text(
              'All Present',
              style: AppTypography.pillLabel
                  .copyWith(color: AppColors.brandPrimary),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandPrimary))
          : Column(
              children: [
                // Quick Legend Bar
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _legendItem('Tap = Toggle Absent', AppColors.danger),
                      _legendItem('Hold = On Leave', AppColors.warning),
                      _legendItem('Green = Present', AppColors.success),
                    ],
                  ),
                ),

                // Student Roll Call Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final s = _students[index];
                      final status =
                          _attendanceState[s.id] ?? AttendanceStatus.present;
                      return _buildStudentTile(s, status);
                    },
                  ),
                ),
              ],
            ),
      bottomSheet: _buildStickyBottomSummary(),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(text, style: AppTypography.caption.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _buildStudentTile(Student student, AttendanceStatus status) {
    return _StudentAttendanceCard(
      student: student,
      status: status,
      onTap: () => _onStudentTap(student.id),
      onLongPress: () => _onStudentLongPress(student.id),
    );
  }

  Widget _buildStickyBottomSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Counters & Summary Text Block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Present: $_presentCount • Absent: $_absentCount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                      if (_leaveCount > 0) ...[
                        Text(
                          ' • Leave: $_leaveCount',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${((_students.isEmpty ? 0 : (_presentCount / _students.length) * 100)).toStringAsFixed(0)}% Attendance Rate (${_students.length} Total)',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Submit Attendance Button
            TactileFeedback(
              onTap: _isSubmitting ? null : _submitAttendance,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPrimary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.check,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Submit Attendance',
                              style: AppTypography.button.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
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
}

/// Tactile Student Roll Call Card with spring bounce scale & border morphing on toggle
class _StudentAttendanceCard extends StatefulWidget {
  final Student student;
  final AttendanceStatus status;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _StudentAttendanceCard({
    required this.student,
    required this.status,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_StudentAttendanceCard> createState() => _StudentAttendanceCardState();
}

class _StudentAttendanceCardState extends State<_StudentAttendanceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.94)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.94, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(covariant _StudentAttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    double borderWidth;

    switch (widget.status) {
      case AttendanceStatus.absent:
        bgColor = const Color(0xFFFEE2E2); // Danger Light
        borderColor = AppColors.danger;
        statusColor = AppColors.danger;
        statusLabel = 'ABSENT';
        statusIcon = LucideIcons.x;
        borderWidth = 2.0;
        break;
      case AttendanceStatus.leave:
        bgColor = const Color(0xFFFEF3C7); // Amber Light
        borderColor = AppColors.warning;
        statusColor = AppColors.warning;
        statusLabel = 'LEAVE';
        statusIcon = LucideIcons.clock;
        borderWidth = 2.0;
        break;
      case AttendanceStatus.late:
      case AttendanceStatus.present:
        bgColor = const Color(0xFFD1FAE5); // Emerald Mint Light
        borderColor = AppColors.success;
        statusColor = AppColors.success;
        statusLabel = 'PRESENT';
        statusIcon = LucideIcons.check;
        borderWidth = 1.5;
        break;
    }

    return TactileFeedback(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.16),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Roll No Badge + Status Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.student.rollNo.toString(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 14),
                  ),
                ],
              ),

              // Student Name
              Text(
                widget.student.fullName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
