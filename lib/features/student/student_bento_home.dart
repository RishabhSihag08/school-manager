import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/announcement.dart';
import '../../core/models/class_section.dart';
import '../../core/models/exam_result.dart';
import '../../core/models/homework.dart';
import '../../core/models/student.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/tactile_feedback.dart';
import '../../core/widgets/unified_media_viewer.dart';
import '../auth/sibling_switcher_sheet.dart';

class StudentBentoHome extends ConsumerStatefulWidget {
  const StudentBentoHome({super.key});

  @override
  ConsumerState<StudentBentoHome> createState() => _StudentBentoHomeState();
}

class _StudentBentoHomeState extends ConsumerState<StudentBentoHome> {
  List<Homework> _homeworks = [];
  Announcement? _pinnedAnnouncement;
  double _attendancePct = 92.4;
  ExamStudentSummary? _latestExamSummary;
  String? _timetableFileUrl;
  String? _className;
  bool _isLoading = true;
  bool _isBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final currentStudent = ref.read(currentStudentProvider);
    if (currentStudent == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final studentId = currentStudent.id;
    final classId = currentStudent.classSectionId;

    final repo = ref.read(schoolRepositoryProvider);

    final homeworkFuture = repo.getHomeworksForClass(classId, studentId: studentId);
    final pinnedFuture = repo.getPinnedAnnouncement(classSectionId: classId);
    final attPctFuture = repo.getStudentAttendancePercentage(studentId);
    final examFuture = repo.getStudentExamSummary(studentId, 'Half Yearly Examination');
    final classFuture = repo.getClassSectionById(classId);

    final results = await Future.wait([
      homeworkFuture,
      pinnedFuture,
      attPctFuture,
      examFuture,
      classFuture,
    ]);

    if (!mounted) return;
    final cls = results[4] as ClassSection?;
    setState(() {
      _homeworks = results[0] as List<Homework>;
      _pinnedAnnouncement = results[1] as Announcement?;
      _attendancePct = results[2] as double;
      _latestExamSummary = results[3] as ExamStudentSummary?;
      _timetableFileUrl = cls?.timetableFileUrl;
      _className = cls?.displayName;
      _isLoading = false;
    });
  }

  Future<void> _toggleHomework(Homework hw) async {
    final newStatus = !hw.isCompleted;
    final currentStudent = ref.read(currentStudentProvider);
    final studentId = currentStudent?.id ?? '';
    if (studentId.isEmpty) return;

    HapticFeedback.mediumImpact();

    // Optimistic UI update
    setState(() {
      final index = _homeworks.indexWhere((item) => item.id == hw.id);
      if (index != -1) {
        _homeworks[index] = hw.copyWith(isCompleted: newStatus);
      }
    });

    final repo = ref.read(schoolRepositoryProvider);
    await repo.toggleHomeworkCompletion(
      homeworkId: hw.id,
      studentId: studentId,
      isCompleted: newStatus,
    );
  }

  void _showAnnouncementsDialog() async {
    final currentStudent = ref.read(currentStudentProvider);
    final classId = currentStudent?.classSectionId;

    final repo = ref.read(schoolRepositoryProvider);
    final cls = classId != null && classId.isNotEmpty
        ? await repo.getClassSectionById(classId)
        : null;
    final announcements = await repo.getAnnouncements(
      grade: cls?.grade,
      classSectionId: classId,
    );
    // Sort newest first
    announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.canvasBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      Text('School Announcements', style: AppTypography.headlineSmall),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: announcements.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.megaphoneOff,
                                  size: 40,
                                  color: AppColors.inkMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No announcements published yet',
                                  style: AppTypography.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Official notices from the school administration will appear here.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: announcements.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final ann = announcements[index];
                              return BentoCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ann.category == AnnouncementCategory.holiday
                                                ? AppColors.coralLight
                                                : AppColors.brandPrimaryLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            ann.category.label,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: ann.category == AnnouncementCategory.holiday
                                                  ? AppColors.coralStreak
                                                  : AppColors.brandPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd MMM yyyy, hh:mm a').format(ann.createdAt),
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 11,
                                            color: AppColors.inkSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(ann.title, style: AppTypography.titleMedium),
                                    const SizedBox(height: 4),
                                    Text(ann.body, style: AppTypography.bodySmall),
                                    if (ann.attachments.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      TactileFeedback(
                                        onTap: () {
                                          UnifiedMediaViewer.show(context, items: ann.attachments);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondarySurface,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(LucideIcons.paperclip, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                ann.attachments.first.title,
                                                style: AppTypography.labelSmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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
      },
    );
  }

  Future<void> _openTimetable() async {
    final currentStudent = ref.read(currentStudentProvider);
    final classId = currentStudent?.classSectionId;

    String? url = _timetableFileUrl;
    String? className = _className;

    if (url == null || url.isEmpty) {
      if (classId != null && classId.isNotEmpty) {
        final repo = ref.read(schoolRepositoryProvider);
        final cls = await repo.getClassSectionById(classId);
        url = cls?.timetableFileUrl;
        className = cls?.displayName;
        if (mounted) {
          setState(() {
            _timetableFileUrl = url;
            _className = className;
          });
        }
      }
    }

    if (!mounted) return;

    if (url != null && url.isNotEmpty) {
      UnifiedMediaViewer.show(
        context,
        items: [
          MediaAttachmentItem(
            title: className != null ? '$className Timetable' : 'Class Timetable',
            url: url,
            type: 'image',
          ),
        ],
      );
    } else {
      _showNoTimetableDialog();
    }
  }

  void _showNoTimetableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.calendarOff, color: AppColors.brandPrimary, size: 22),
            const SizedBox(width: 8),
            Text(
              'No Timetable Uploaded Yet',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'The school administration has not uploaded the timetable photo for your class yet.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Okay',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.brandPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStudent = ref.watch(currentStudentProvider);
    final otaState = ref.watch(otaUpdateProvider);

    final completedCount = _homeworks.where((h) => h.isCompleted).length;
    final totalCount = _homeworks.length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.75;

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: AppColors.brandPrimary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar: Sibling Pill & Settings Action
                      _buildTopBar(currentStudent, otaState.availableRelease != null),

                      const SizedBox(height: 16),

                      // Pinned Holiday / Urgent Coral Banner (Conditional)
                      if (_pinnedAnnouncement != null && !_isBannerDismissed)
                        _buildPinnedNoticeBanner(_pinnedAnnouncement!),

                      const SizedBox(height: 16),

                      // Hero Bento Card: "Today's Homework Mission" Streak Card
                      _buildHomeworkMissionHero(
                        completedCount,
                        totalCount,
                        progress,
                        currentStudent?.homeworkStreak ?? 5,
                      ),

                      const SizedBox(height: 16),

                      // Middle Bento Row: 2 Equal Square Cards (Attendance Ring & Exam Hub)
                      _buildMiddleBentoRow(),

                      const SizedBox(height: 16),

                      // Quick Academic Bar (3 Compact Tactile Pills)
                      _buildQuickAcademicBar(),

                      const SizedBox(height: 20),

                      // Interactive Homework Feed Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Due Homework & Tasks', style: AppTypography.titleLarge),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$completedCount / $totalCount Done',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Homework List
                      ..._homeworks.map((hw) => _buildHomeworkCard(hw)),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar(Student? student, bool hasOtaUpdate) {
    return Row(
      children: [
        // Sibling Pill (Avatar + Name)
        Expanded(
          child: TactileFeedback(
            onTap: () => SiblingSwitcherSheet.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.brandPrimaryLight,
                    child: Text(
                      student?.fullName.isNotEmpty == true
                          ? student!.fullName[0].toUpperCase()
                          : 'S',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.brandPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student?.fullName ?? 'Student',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                        Text(
                          'Class 8-B • Roll #${student?.rollNo ?? 1}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: AppColors.inkMuted,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Notifications Bell
        TactileFeedback(
          onTap: _showAnnouncementsDialog,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(
              LucideIcons.bell,
              size: 20,
              color: AppColors.inkPrimary,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Settings Gear with Update dot
        TactileFeedback(
          onTap: () => context.push(AppRoutes.settings),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(
                  LucideIcons.settings,
                  size: 20,
                  color: AppColors.inkPrimary,
                ),
              ),
              if (hasOtaUpdate)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.coralStreak,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPinnedNoticeBanner(Announcement ann) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.coralStreak,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FF6B4A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.megaphone,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ann.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TactileFeedback(
                      onTap: () => setState(() => _isBannerDismissed = true),
                      child: const Icon(
                        LucideIcons.x,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ann.body,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (ann.attachments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TactileFeedback(
                    onTap: () {
                      UnifiedMediaViewer.show(context, items: ann.attachments);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.paperclip,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'View Circular Document',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkMissionHero(
    int completed,
    int total,
    double progress,
    int streak,
  ) {
    return BentoCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: AppColors.cardSurface,
      borderColor: AppColors.brandPrimary.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.coralLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.flame,
                      color: AppColors.coralStreak,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Today\'s Homework Mission',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.coralLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$streak-Day Streak 🔥',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.coralStreak,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$completed of $total Homeworks Done Today!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.inkPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            completed == total
                ? 'All clear for tomorrow! You are on fire.'
                : 'Complete remaining assignments before 9:00 PM.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.secondarySurface,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.brandPrimary,
              ),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleBentoRow() {
    return Row(
      children: [
        // Left Square Card: Attendance Ring
        Expanded(
          child: BentoCard(
            padding: const EdgeInsets.all(16),
            onTap: () => context.push(AppRoutes.studentAttendance),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.calendarCheck,
                        color: AppColors.success,
                        size: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Present ✅',
                        style: GoogleFonts.inter(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${_attendancePct.toStringAsFixed(1)}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Attendance', style: AppTypography.titleSmall),
                Text('Tap for calendar', style: AppTypography.bodySmall),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Right Square Card: Exam Hub
        Expanded(
          child: BentoCard(
            padding: const EdgeInsets.all(16),
            onTap: () => context.push(AppRoutes.studentResults),
            child: _latestExamSummary != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              LucideIcons.award,
                              color: AppColors.brandPrimary,
                              size: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Grade ${_latestExamSummary!.overallGrade}',
                              style: GoogleFonts.inter(
                                color: AppColors.brandPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '${_latestExamSummary!.percentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Exam Hub', style: AppTypography.titleSmall),
                      Text(
                        _latestExamSummary!.examName,
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              LucideIcons.award,
                              color: AppColors.inkMuted,
                              size: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Pending',
                              style: GoogleFonts.inter(
                                color: AppColors.inkMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.fileQuestion,
                            size: 18,
                            color: AppColors.inkMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'No exam has been taken yet.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Exam Hub', style: AppTypography.titleSmall),
                      Text('Tap to check results', style: AppTypography.bodySmall),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAcademicBar() {
    return Row(
      children: [
        Expanded(
          child: _academicPill(
            label: 'Timetable',
            icon: LucideIcons.calendar,
            onTap: _openTimetable,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _academicPill(
            label: 'Syllabus',
            icon: LucideIcons.bookOpen,
            onTap: () => context.push(AppRoutes.studentSyllabus),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _academicPill(
            label: 'Notices',
            icon: LucideIcons.megaphone,
            onTap: _showAnnouncementsDialog,
          ),
        ),
      ],
    );
  }

  Widget _academicPill({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return BentoCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppColors.brandPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.pillLabel.copyWith(
              color: AppColors.inkPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkCard(Homework hw) {
    final (bg, fg) = AppColors.getSubjectColors(hw.subjectName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: BentoCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bouncy Tactile Checkbox
            TactileFeedback(
              onTap: () => _toggleHomework(hw),
              child: AnimatedContainer(
                duration: AppMotion.durationFast,
                curve: AppMotion.easeOut,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: hw.isCompleted ? AppColors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hw.isCompleted ? AppColors.success : AppColors.cardBorder,
                    width: 2,
                  ),
                ),
                child: hw.isCompleted
                    ? const Icon(LucideIcons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Homework details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hw.subjectName,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                      ),
                      Text(
                        'Due ${DateFormat('MMM d').format(hw.dueDate)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hw.title,
                    style: AppTypography.titleMedium.copyWith(
                      decoration: hw.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: hw.isCompleted
                          ? AppColors.inkMuted
                          : AppColors.inkPrimary,
                    ),
                  ),
                  if (hw.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      hw.description!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                  if (hw.attachments.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: hw.attachments.map((att) {
                        return TactileFeedback(
                          onTap: () {
                            UnifiedMediaViewer.show(context, items: hw.attachments);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  att.type == 'pdf'
                                      ? LucideIcons.fileText
                                      : LucideIcons.image,
                                  size: 13,
                                  color: AppColors.brandPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  att.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
