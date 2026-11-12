import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/tactile_feedback.dart';

/// School Manager Teacher 2-Gear Dashboard
/// Gear 1: Homeroom Class 8-B Pinned Banner (Join Code, Lock/Copy, 30-sec Roll Call, Roster, Notice)
/// Gear 2: Subject Classes Grid (Assigned Class+Subject cards with +Homework, Syllabus, Marks)
class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  bool _isCodeLocked = false;
  bool _attendanceDoneToday = false;
  int _presentCount = 40;
  int _totalCount = 42;
  String _classCode = '8B-K9X2';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(schoolRepositoryProvider);
    final cls = await repo.getClassSectionById('class-8b');
    if (cls != null && mounted) {
      setState(() {
        _isCodeLocked = cls.isCodeLocked;
        _classCode = cls.classCode;
      });
    }

    // Check today's attendance
    final today = DateTime.now();
    final attList = await repo.getAttendanceForDate('class-8b', today);
    if (attList.isNotEmpty && mounted) {
      final present =
          attList.where((a) => a.status == AttendanceStatus.present).length;
      setState(() {
        _attendanceDoneToday = true;
        _presentCount = present;
        _totalCount = attList.length;
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _copyClassCode() {
    Clipboard.setData(ClipboardData(text: _classCode));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCheck, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Class Code $_classCode copied to clipboard!',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.brandPrimary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareClassCode() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share Link: "Join Class 8-B on School Manager with code $_classCode"',
          style: AppTypography.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.brandPrimary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleLockCode() async {
    final repo = ref.read(schoolRepositoryProvider);
    final newLocked = !_isCodeLocked;
    await repo.setClassCodeLocked('class-8b', newLocked);
    HapticFeedback.mediumImpact();
    if (mounted) {
      setState(() => _isCodeLocked = newLocked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newLocked
                ? '🔒 Class Join Code LOCKED. No new students can join.'
                : '🔓 Class Join Code UNLOCKED for registration.',
          ),
          backgroundColor:
              newLocked ? AppColors.warning : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openRosterSheet() async {
    final repo = ref.read(schoolRepositoryProvider);
    final students = await repo.getStudentsForClass('class-8b');

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Class 8-B Student Roster',
                          style: AppTypography.headlineSmall),
                      Text(
                        '${students.length} Enrolled Students (Verified via Class Code)',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '8B-K9X2',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final s = students[idx];
                    final houseColor = AppColors.getHouseColor(s.house);
                    return BentoCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: houseColor, width: 2),
                              color: houseColor.withValues(alpha: 0.12),
                            ),
                            child: Center(
                              child: Text(
                                s.rollNo.toString(),
                                style: GoogleFonts.jetBrainsMono(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.inkPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.fullName,
                                    style: AppTypography.titleSmall),
                                const SizedBox(height: 2),
                                Text(
                                  'Parent: ${s.parentName} (${s.parentPhone})',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: houseColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${s.house.toUpperCase()} HOUSE',
                              style: AppTypography.monospace(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: houseColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openNoticeDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(LucideIcons.megaphone,
                  color: AppColors.brandPrimary, size: 24),
              const SizedBox(width: 10),
              Text('Post Class 8-B Notice', style: AppTypography.titleLarge),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'This announcement will be delivered instantly to all Class 8-B students and parents.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.inkSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Notice Title',
                  hintText: 'e.g. Bring Science project models tomorrow',
                  filled: true,
                  fillColor: AppColors.canvasBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notice Instructions',
                  hintText: 'Details for students regarding materials...',
                  filled: true,
                  fillColor: AppColors.canvasBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final repo = ref.read(schoolRepositoryProvider);
                await repo.createAnnouncement(
                  Announcement(
                    id: 'ann-${DateTime.now().millisecondsSinceEpoch}',
                    title: titleCtrl.text.trim(),
                    body: bodyCtrl.text.trim(),
                    category: AnnouncementCategory.classNotice,
                    targetClassSectionId: 'class-8b',
                    createdAt: DateTime.now(),
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📢 Class notice posted successfully!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Broadcast Notice'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentStaffProvider);
    final teacherName = staff?['full_name'] ?? 'Mr. Ramesh Sharma';

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: AppColors.canvasBackground,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Faculty Portal', style: AppTypography.headlineSmall),
            Text(
              'Session ${AppConfig.currentAcademicYear}',
              style:
                  AppTypography.caption.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
        actions: [
          // Switch Role / Session Action
          TactileFeedback(
            onTap: () {
              ref.read(currentStaffProvider.notifier).state = null;
              context.go(AppRoutes.onboarding);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.logOut,
                      size: 14, color: AppColors.inkSecondary),
                  const SizedBox(width: 4),
                  Text('Switch Role', style: AppTypography.pillLabel),
                ],
              ),
            ),
          ),
          // Settings Gear Icon
          IconButton(
            icon: const Icon(LucideIcons.settings, color: AppColors.inkPrimary),
            tooltip: 'Settings & Updates',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandPrimary))
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              color: AppColors.brandPrimary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // Greeting row
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.brandPrimary,
                              Color(0xFF6366F1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.userCheck,
                              color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Namaste, $teacherName 👋',
                              style: AppTypography.headlineSmall,
                            ),
                            Text(
                              'Class Teacher: 8-B • Subject: Mathematics',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.inkSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ==========================================
                  // GEAR 1: HOMEROOM PINNED BANNER (CLASS 8-B)
                  // ==========================================
                  _buildGear1HomeroomBanner(),

                  const SizedBox(height: 24),

                  // ==========================================
                  // GEAR 2: SUBJECT CLASSES ALLOCATION GRID
                  // ==========================================
                  _buildGear2SubjectClassesSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildGear1HomeroomBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3730A3), // Deep Indigo
            Color(0xFF4F46E5), // Electric Indigo
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Top Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.crown, color: Colors.amber, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'HOMEROOM IN-CHARGE',
                      style: AppTypography.monospace(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isCodeLocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.lock,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'LOCKED',
                        style: AppTypography.monospace(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Class Name Title
          Text(
            'Class 8-B (Academic Year 2026-27)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '42 Enrolled Students • Secondary Wing • Room 204',
            style: AppTypography.bodySmall
                .copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),

          const SizedBox(height: 16),

          // 6-Character Join Code Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.ticket,
                    color: Color(0xFFFDE68A), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STUDENT CLASS JOIN CODE',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        _classCode,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFDE68A), // Soft gold
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
                // Copy Button
                TactileFeedback(
                  onTap: _copyClassCode,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.copy,
                        color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 6),
                // Share Button
                TactileFeedback(
                  onTap: _shareClassCode,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.share2,
                        color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 6),
                // Lock Toggle Button
                TactileFeedback(
                  onTap: _toggleLockCode,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isCodeLocked
                          ? AppColors.warning
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isCodeLocked ? LucideIcons.lock : LucideIcons.unlock,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 3 Primary Action Buttons
          Row(
            children: [
              // 1. Take Attendance Button
              Expanded(
                flex: 5,
                child: TactileFeedback(
                  onTap: () async {
                    await context.push(AppRoutes.teacherAttendance);
                    _loadInitialData();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: _attendanceDoneToday
                          ? const Color(0xFF065F46) // Deep Emerald
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _attendanceDoneToday
                              ? LucideIcons.checkCircle
                              : LucideIcons.checkSquare,
                          color: _attendanceDoneToday
                              ? const Color(0xFFA7F3D0)
                              : AppColors.brandPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _attendanceDoneToday
                                ? 'Done ($_presentCount/$_totalCount)'
                                : 'Take Attendance',
                            style: AppTypography.button.copyWith(
                              fontSize: 13,
                              color: _attendanceDoneToday
                                  ? Colors.white
                                  : AppColors.brandPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 2. Class Roster Button
              Expanded(
                flex: 4,
                child: TactileFeedback(
                  onTap: _openRosterSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.users,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Roster (42)',
                          style: AppTypography.button.copyWith(
                            fontSize: 12.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 3. Class Notice Button
              TactileFeedback(
                onTap: _openNoticeDialog,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(LucideIcons.megaphone,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGear2SubjectClassesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.bookOpen,
                    size: 18, color: AppColors.brandPrimary),
                const SizedBox(width: 8),
                Text('My Subject Allocations',
                    style: AppTypography.titleLarge),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                '3 Assigned Sections',
                style: AppTypography.caption
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Cards for allocated classes (Class 8-B Maths, Class 6-A Maths, Class 7-C Maths)
        _buildSubjectCard(
          className: 'Class 8-B',
          classId: 'class-8b',
          subjectName: 'Mathematics',
          subjectCode: 'MATH',
          isHomeroom: true,
          studentCount: 42,
          schedule: 'Mon, Wed, Fri • P1 (08:00 AM)',
        ),
        const SizedBox(height: 12),
        _buildSubjectCard(
          className: 'Class 6-A',
          classId: 'class-6a',
          subjectName: 'Mathematics',
          subjectCode: 'MATH',
          isHomeroom: false,
          studentCount: 38,
          schedule: 'Tue, Thu, Sat • P2 (08:45 AM)',
        ),
        const SizedBox(height: 12),
        _buildSubjectCard(
          className: 'Class 7-C',
          classId: 'class-7c',
          subjectName: 'Mathematics',
          subjectCode: 'MATH',
          isHomeroom: false,
          studentCount: 40,
          schedule: 'Mon, Tue, Fri • P4 (10:15 AM)',
        ),
      ],
    );
  }

  Widget _buildSubjectCard({
    required String className,
    required String classId,
    required String subjectName,
    required String subjectCode,
    required bool isHomeroom,
    required int studentCount,
    required String schedule,
  }) {
    final (bg, fg) = AppColors.getSubjectColors(subjectCode);

    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(LucideIcons.binary,
                      color: fg, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('$className • $subjectName',
                            style: AppTypography.titleMedium),
                        if (isHomeroom) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Homeroom',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.brandPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$studentCount Students • $schedule',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),

          // 3 Action Buttons: [+ Homework], [📚 Syllabus], [📊 Marks]
          Row(
            children: [
              // + Homework Button
              Expanded(
                child: TactileFeedback(
                  onTap: () {
                    context.push(AppRoutes.teacherCreateHomework);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.canvasBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.filePlus,
                            size: 14, color: AppColors.brandPrimary),
                        const SizedBox(width: 6),
                        Text('+ Homework', style: AppTypography.pillLabel),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Syllabus Button
              Expanded(
                child: TactileFeedback(
                  onTap: () {
                    context.push(AppRoutes.studentSyllabus);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.canvasBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.bookOpen,
                            size: 14, color: AppColors.inkSecondary),
                        const SizedBox(width: 6),
                        Text('Syllabus', style: AppTypography.pillLabel),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Marks Button
              Expanded(
                child: TactileFeedback(
                  onTap: () {
                    context.push(AppRoutes.adminExcelWizard);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.canvasBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.award,
                            size: 14, color: AppColors.inkSecondary),
                        const SizedBox(width: 6),
                        Text('Marks', style: AppTypography.pillLabel),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
