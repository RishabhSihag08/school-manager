import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/school_manager_logo.dart';
import '../../core/widgets/tactile_feedback.dart';
import 'teacher_syllabus_screen.dart';

/// School Manager Teacher Faculty Portal
/// Responsive Layout with Desktop Sidebar and Mobile Drawer matching AdminShell.
/// - Gear 1: Class in Charge Pinned Banner (Attendance, Roster, Notice, Join Code)
///   (Completely hidden if teacher is in charge of NO class)
/// - Gear 2: Subject Allocations Grid
/// - Announcements Hub: View circulars, publish notices, delete circulars
class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard>
    with WidgetsBindingObserver {
  int _selectedNavIndex = 0;
  bool _isCodeLocked = false;
  bool _attendanceDoneToday = false;
  int _presentCount = 0;
  int _totalCount = 0;
  int _rosterStudentCount = 0;
  String _classCode = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _subjectAllocations = [];
  List<Announcement> _announcements = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Auto-refresh when reopening the app
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(schoolRepositoryProvider);

    var staff = ref.read(currentStaffProvider);
    if (staff == null && (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST'))) {
      staff = await SessionService.getSavedStaff();
      if (staff != null && mounted) {
        ref.read(currentStaffProvider.notifier).state = staff;
      }
    }
    final teacherId = staff?['id'] as String? ?? '';
    final teacherSubject = staff?['subject_name'] as String? ?? 'General';
    final teacherSubjectCode = staff?['subject_code'] as String? ?? 'GEN';

    final homeroomClassId = staff?['homeroom_class_id'] as String?;
    final hasClassInCharge =
        staff?['homeroom_class_id'] != null &&
        staff?['homeroom_class_id'].toString().isNotEmpty == true;

    if (hasClassInCharge && homeroomClassId != null && homeroomClassId.isNotEmpty) {
      final classInChargeId = homeroomClassId.trim();
      final cls = await repo.getClassSectionById(classInChargeId);
      if (cls != null && mounted) {
        setState(() {
          _isCodeLocked = cls.isCodeLocked;
          _classCode = cls.classCode;
        });
      }

      final students = await repo.getStudentsForClass(classInChargeId);
      if (mounted) {
        setState(() {
          _rosterStudentCount = students.length;
        });
      }

      // Check today's attendance
      final today = DateTime.now();
      final attList = await repo.getAttendanceForDate(classInChargeId, today);
      if (attList.isNotEmpty && mounted) {
        final present =
            attList.where((a) => a.status == AttendanceStatus.present).length;
        setState(() {
          _attendanceDoneToday = true;
          _presentCount = present;
          _totalCount = attList.length;
        });
      } else if (mounted) {
        setState(() {
          _attendanceDoneToday = false;
          _presentCount = 0;
          _totalCount = students.length;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _attendanceDoneToday = false;
          _presentCount = 0;
          _totalCount = 0;
          _rosterStudentCount = 0;
          _classCode = '';
        });
      }
    }

    // Load dynamic subject allocations for this teacher's subject
    try {
      final allocations = await repo.getTeacherSubjectAllocations(teacherId);
      var filtered = allocations.where((a) {
        final subName = (a['subject_name'] as String?)?.toLowerCase() ?? '';
        final subCode = (a['subject_code'] as String?)?.toUpperCase() ?? '';
        return subName == teacherSubject.toLowerCase() ||
            subCode == teacherSubjectCode.toUpperCase();
      }).toList();

      if (filtered.isEmpty && hasClassInCharge && homeroomClassId != null) {
        filtered = [
          {
            'class_section_id': homeroomClassId,
            'class_name':
                staff?['homeroom_class_name'] as String? ?? 'Homeroom Class',
            'subject_name': teacherSubject,
            'subject_code': teacherSubjectCode,
            'is_homeroom': true,
            'student_count': _rosterStudentCount,
            'schedule': 'Weekly Homeroom Session',
          },
        ];
      }
      if (mounted) {
        setState(() {
          _subjectAllocations = filtered;
        });
      }
    } catch (_) {}

    // Load announcements
    try {
      final announcements = await repo.getAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = announcements;
        });
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  void _copyClassCode() {
    if (_classCode.isEmpty) return;
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

  void _shareClassCode(String className) {
    if (_classCode.isEmpty) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share Link: "Join $className on School Manager with code $_classCode"',
          style: AppTypography.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.brandPrimary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleLockCode(String classId) async {
    final repo = ref.read(schoolRepositoryProvider);
    final newLocked = !_isCodeLocked;
    await repo.setClassCodeLocked(classId, newLocked);
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

  void _openRosterSheet(String classId, String className) async {
    final repo = ref.read(schoolRepositoryProvider);
    final students = await repo.getStudentsForClass(classId);

    if (mounted) {
      setState(() => _rosterStudentCount = students.length);
    }

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
                      Text('$className Student Roster',
                          style: AppTypography.headlineSmall),
                      Text(
                        '${students.length} Enrolled Students (Verified via Class Code)',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                  if (_classCode.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _classCode,
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
                child: students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.users,
                                size: 40, color: AppColors.inkMuted),
                            const SizedBox(height: 8),
                            Text(
                              'No students enrolled in this class yet.',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.inkMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final s = students[idx];
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
                                    border: Border.all(
                                        color: AppColors.brandPrimary
                                            .withValues(alpha: 0.3),
                                        width: 1.5),
                                    color: AppColors.brandPrimaryLight,
                                  ),
                                  child: Center(
                                    child: Text(
                                      s.rollNo.toString(),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.brandPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                if (s.admissionNo != null &&
                                    s.admissionNo!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondarySurface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      s.admissionNo!,
                                      style: AppTypography.monospace(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.inkSecondary,
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

  void _openNoticeDialog({String? classId, String? className}) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final staff = ref.read(currentStaffProvider);
    final teacherId = staff?['id'] as String? ?? '';
    final teacherName = staff?['full_name'] as String? ?? 'Faculty';
    final homeroomClassId = staff?['homeroom_class_id'] as String?;
    final homeroomClassName =
        staff?['homeroom_class_name'] as String? ?? 'Class in Charge';
    final hasClassInCharge =
        homeroomClassId != null && homeroomClassId.isNotEmpty;

    // Scope selection: 'school', 'homeroom', 'teaching'
    String selectedScope = classId != null
        ? (classId == homeroomClassId ? 'homeroom' : 'teaching')
        : 'school';
    String? selectedTeachingClassId = classId != null && classId != homeroomClassId
        ? classId
        : (_subjectAllocations.isNotEmpty
            ? (_subjectAllocations.first['class_section_id'] ??
                    _subjectAllocations.first['class_id'])
                as String?
            : null);
    int expiryDays = 0; // 0 = Never

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(LucideIcons.megaphone,
                      color: AppColors.brandPrimary, size: 24),
                  SizedBox(width: 10),
                  Text('Post Announcement'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Target Scope Selector
                    DropdownButtonFormField<String>(
                      initialValue: selectedScope,
                      decoration: const InputDecoration(
                        labelText: 'Announce To',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'school',
                          child: Text('Whole School (All Classes)'),
                        ),
                        if (hasClassInCharge)
                          DropdownMenuItem(
                            value: 'homeroom',
                            child: Text('Class in Charge ($homeroomClassName)'),
                          ),
                        if (_subjectAllocations.isNotEmpty)
                          const DropdownMenuItem(
                            value: 'teaching',
                            child: Text('Classes You Teach'),
                          ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedScope = val);
                        }
                      },
                    ),
                    if (selectedScope == 'teaching' &&
                        _subjectAllocations.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedTeachingClassId,
                        decoration: const InputDecoration(
                          labelText: 'Select Teaching Class',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        items: _subjectAllocations.map((alloc) {
                          final cId = (alloc['class_section_id'] ??
                              alloc['class_id']) as String;
                          final cName =
                              alloc['class_name'] as String? ?? 'Class';
                          final sName =
                              alloc['subject_name'] as String? ?? 'Subject';
                          return DropdownMenuItem(
                            value: cId,
                            child: Text('$cName • $sName'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(
                                () => selectedTeachingClassId = val);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Expiration Selector
                    DropdownButtonFormField<int>(
                      initialValue: expiryDays,
                      decoration: const InputDecoration(
                        labelText: 'Expires In',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('Never (No Expiry)'),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('1 Day'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('2 Days'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('3 Days'),
                        ),
                        DropdownMenuItem(
                          value: 7,
                          child: Text('7 Days'),
                        ),
                        DropdownMenuItem(
                          value: 14,
                          child: Text('14 Days'),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text('30 Days'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => expiryDays = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Announcement Title',
                        hintText: 'e.g. Science Fair Submission Guidelines',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Announcement Details / Instructions',
                        hintText: 'Details for students regarding materials...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;

                    String? targetClassId;
                    if (selectedScope == 'homeroom') {
                      targetClassId = homeroomClassId;
                    } else if (selectedScope == 'teaching') {
                      targetClassId = selectedTeachingClassId;
                    }

                    final category = selectedScope == 'school'
                        ? AnnouncementCategory.general
                        : AnnouncementCategory.classNotice;

                    final newAnn = Announcement(
                      id: 'ann-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      body: bodyCtrl.text.trim(),
                      category: category,
                      targetClassSectionId: targetClassId,
                      createdAt: DateTime.now(),
                      expiresAt: expiryDays > 0
                          ? DateTime.now().add(Duration(days: expiryDays))
                          : null,
                      authorId: teacherId,
                      authorName: teacherName,
                      authorRole: 'teacher',
                    );

                    final repo = ref.read(schoolRepositoryProvider);
                    await repo.createAnnouncement(newAnn);

                    if (ctx.mounted) Navigator.pop(ctx);

                    if (mounted) {
                      setState(() {
                        _announcements.removeWhere((item) => item.id == newAnn.id);
                        _announcements.insert(0, newAnn);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📢 Announcement posted successfully!'),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Auto-refresh when app reopens or network reconnects
    ref.listen<int>(appRefreshTriggerProvider, (prev, next) {
      if (next > (prev ?? 0)) {
        _loadInitialData();
      }
    });

    // Auto-refresh if staff session changes
    ref.listen<Map<String, dynamic>?>(currentStaffProvider, (prev, next) {
      if (next != null && (prev == null || prev['id'] != next['id'])) {
        _loadInitialData();
      }
    });

    final staff = ref.watch(currentStaffProvider);
    final teacherName = staff?['full_name'] ?? 'Faculty';
    final teachingSubject = staff?['subject_name'] ?? 'General';
    final homeroomName = staff?['homeroom_class_name'] as String? ?? 'Homeroom';
    final homeroomClassId = staff?['homeroom_class_id'] as String?;
    final hasClassInCharge =
        staff?['homeroom_class_id'] != null &&
        staff?['homeroom_class_id'].toString().isNotEmpty == true;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppColors.canvasBackground,
              elevation: 0,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(LucideIcons.menu, color: AppColors.inkPrimary),
                  tooltip: 'Open Drawer',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Faculty Portal', style: AppTypography.titleLarge),
                  Text(
                    'Session ${AppConfig.currentAcademicYear}',
                    style:
                        AppTypography.caption.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.settings, color: AppColors.inkPrimary),
                  tooltip: 'Settings & Updates',
                  onPressed: () => context.push(AppRoutes.settings),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.logOut, color: AppColors.danger),
                  tooltip: 'Log Out',
                  onPressed: () => SessionService.confirmAndLogout(context, ref),
                ),
              ],
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: _buildSidebarContent(
                isDrawer: true,
                hasClassInCharge: hasClassInCharge,
                teacherName: teacherName,
                teachingSubject: teachingSubject,
              ),
            ),
      body: Row(
        children: [
          // Desktop Fixed Left Sidebar (width 260)
          if (isDesktop)
            Container(
              width: 260,
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                border: Border(right: BorderSide(color: AppColors.cardBorder)),
              ),
              child: _buildSidebarContent(
                isDrawer: false,
                hasClassInCharge: hasClassInCharge,
                teacherName: teacherName,
                teachingSubject: teachingSubject,
              ),
            ),

          // Main View Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.brandPrimary))
                : _buildSelectedView(
                    hasClassInCharge: hasClassInCharge,
                    classInChargeId: homeroomClassId,
                    homeroomName: homeroomName,
                    teacherName: teacherName,
                    teachingSubject: teachingSubject,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent({
    required bool isDrawer,
    required bool hasClassInCharge,
    required String teacherName,
    required String teachingSubject,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // School Branding Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SchoolManagerLogo.horizontal(
              iconSize: 34,
              subtitle: 'Teacher Faculty Portal',
            ),
          ),
        ),

        const Divider(height: 1, color: AppColors.cardBorder),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            children: [
              _navItem(
                title: 'Dashboard & Classes',
                icon: LucideIcons.layoutGrid,
                isSelected: _selectedNavIndex == 0,
                onTap: () {
                  setState(() => _selectedNavIndex = 0);
                  if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                    Navigator.pop(context);
                  }
                },
              ),
              _navItem(
                title: 'Take Attendance',
                icon: LucideIcons.checkSquare,
                isSelected: false,
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                    Navigator.pop(context);
                  }
                  if (hasClassInCharge) {
                    context.push(AppRoutes.teacherAttendance).then((_) {
                      _loadInitialData();
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'You are not currently assigned as Class Teacher in charge of any class.',
                        ),
                        backgroundColor: AppColors.warning,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              _navItem(
                title: 'Subject Syllabus',
                icon: LucideIcons.bookOpen,
                isSelected: false,
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                    Navigator.pop(context);
                  }
                  final alloc =
                      _subjectAllocations.isNotEmpty ? _subjectAllocations.first : null;
                  final staff = ref.read(currentStaffProvider);
                  final sub = staff?['subject_name'] as String? ?? 'Mathematics';
                  final code = staff?['subject_code'] as String? ?? 'MATH';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeacherSyllabusScreen(
                        classSectionId: alloc?['class_section_id'] as String? ??
                            alloc?['class_id'] as String? ??
                            (staff?['homeroom_class_id'] as String? ?? ''),
                        className: alloc?['class_name'] as String? ??
                            (staff?['homeroom_class_name'] as String? ?? 'Class'),
                        subjectName: alloc?['subject_name'] as String? ?? sub,
                        subjectCode: alloc?['subject_code'] as String? ?? code,
                      ),
                    ),
                  );
                },
              ),
              _navItem(
                title: 'Homework Manager',
                icon: LucideIcons.filePlus,
                isSelected: false,
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                    Navigator.pop(context);
                  }
                  context.push(AppRoutes.teacherCreateHomework);
                },
              ),
              _navItem(
                title: 'Announcements Hub',
                icon: LucideIcons.megaphone,
                badge: _announcements.isNotEmpty ? '${_announcements.length}' : null,
                isSelected: _selectedNavIndex == 4,
                onTap: () {
                  setState(() => _selectedNavIndex = 4);
                  if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                    Navigator.pop(context);
                  }
                },
              ),
              _navItem(
                title: 'Settings',
                icon: LucideIcons.settings,
                isSelected: false,
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                    Navigator.pop(context);
                  }
                  context.push(AppRoutes.settings);
                },
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.cardBorder),

        // Bottom Teacher Profile Card with Name, Subject, and Log Out
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandPrimaryLight,
                      border: Border.all(color: AppColors.brandPrimary),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.userCheck,
                          size: 18, color: AppColors.brandPrimary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacherName,
                          style: AppTypography.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          teachingSubject,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.inkMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TactileFeedback(
                onTap: () => SessionService.confirmAndLogout(context, ref),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.logOut,
                          size: 14, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Text(
                        'Log Out',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TactileFeedback(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandPrimaryLight
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.brandPrimary
                    : AppColors.inkSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.inkPrimary,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.inkSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedView({
    required bool hasClassInCharge,
    required String? classInChargeId,
    required String homeroomName,
    required String teacherName,
    required String teachingSubject,
  }) {
    if (_selectedNavIndex == 4) {
      return _buildAnnouncementsHubView();
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: AppColors.brandPrimary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                      hasClassInCharge
                          ? 'Class in Charge: ${homeroomName.replaceFirst("Class ", "")} • Subject: $teachingSubject'
                          : 'Subject Teacher: $teachingSubject',
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
          // GEAR 1: CLASS IN CHARGE PINNED BANNER
          // Hidden completely if NOT in charge of any class!
          // ==========================================
          if (hasClassInCharge && classInChargeId != null) ...[
            _buildGear1ClassInChargeBanner(classInChargeId, homeroomName),
            const SizedBox(height: 24),
          ],

          // ==========================================
          // GEAR 2: SUBJECT CLASSES ALLOCATION GRID
          // ==========================================
          _buildGear2SubjectClassesSection(),
        ],
      ),
    );
  }

  Widget _buildGear1ClassInChargeBanner(String classId, String className) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF28256E), // Deepest Midnight Indigo
            Color(0xFF3730A3), // Deep Indigo
            Color(0xFF4F46E5), // Electric Indigo
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.crown, color: Color(0xFFFDE047), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'CLASS IN CHARGE',
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
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.lock,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        'LOCKED',
                        style: AppTypography.monospace(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.unlock,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        'OPEN',
                        style: AppTypography.monospace(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Class Name Title
          Text(
            '$className (Academic Year ${AppConfig.currentAcademicYear})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 16),

          // 6-Character Join Code Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE68A).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.ticket,
                      color: Color(0xFFFDE68A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STUDENT CLASS JOIN CODE',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.75),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _classCode.isNotEmpty ? _classCode : 'PENDING',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFDE68A), // Soft gold
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Copy Button with Tooltip
                Tooltip(
                  message: 'Copy Join Code',
                  child: TactileFeedback(
                    onTap: _copyClassCode,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(LucideIcons.copy,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Share Button with Tooltip
                Tooltip(
                  message: 'Share Class Join Link',
                  child: TactileFeedback(
                    onTap: () => _shareClassCode(className),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(LucideIcons.share2,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Lock Toggle Button with Tooltip
                Tooltip(
                  message: _isCodeLocked
                      ? 'Unlock Registration for Students'
                      : 'Lock Code (Freeze Enrollment)',
                  child: TactileFeedback(
                    onTap: () => _toggleLockCode(classId),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _isCodeLocked
                            ? AppColors.warning
                            : Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isCodeLocked
                              ? AppColors.warning
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(
                        _isCodeLocked ? LucideIcons.lock : LucideIcons.unlock,
                        color: Colors.white,
                        size: 16,
                      ),
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
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _attendanceDoneToday
                          ? const Color(0xFF065F46) // Deep Emerald
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                                ? 'Attendance Done ($_presentCount/$_totalCount)'
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

              const SizedBox(width: 10),

              // 2. Class Roster Button - Real student count
              Expanded(
                flex: 4,
                child: TactileFeedback(
                  onTap: () => _openRosterSheet(classId, className),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.users,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Roster ($_rosterStudentCount)',
                          style: AppTypography.button.copyWith(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 3. Class Notice Button
              Tooltip(
                message: 'Post Notice to Class',
                child: TactileFeedback(
                  onTap: () =>
                      _openNoticeDialog(classId: classId, className: className),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: const Icon(LucideIcons.megaphone,
                        color: Colors.white, size: 18),
                  ),
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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.bookOpen,
                      size: 18, color: AppColors.brandPrimary),
                ),
                const SizedBox(width: 10),
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
                '${_subjectAllocations.length} Assigned Sections',
                style: AppTypography.caption
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_subjectAllocations.isEmpty)
          BentoCard(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Column(
                children: [
                  const Icon(LucideIcons.bookOpen,
                      size: 36, color: AppColors.inkMuted),
                  const SizedBox(height: 10),
                  Text(
                    'No Subject Allocations Yet',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No sections currently allocated for your subject. Classes assigned by school admin will appear here.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.inkSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              if (isWide) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 165,
                  ),
                  itemCount: _subjectAllocations.length,
                  itemBuilder: (context, index) {
                    final alloc = _subjectAllocations[index];
                    return _buildAllocCardFromData(alloc);
                  },
                );
              }

              return Column(
                children: _subjectAllocations.map((alloc) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAllocCardFromData(alloc),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAllocCardFromData(Map<String, dynamic> alloc) {
    final className = alloc['class_name'] as String? ?? 'Class';
    final classId = alloc['class_section_id'] as String? ??
        alloc['class_id'] as String? ??
        '';
    final subjectName = alloc['subject_name'] as String? ?? 'Mathematics';
    final subjectCode = alloc['subject_code'] as String? ?? 'MATH';
    final isHomeroom = alloc['is_homeroom'] as bool? ?? false;
    final studentCount = alloc['student_count'] as int? ?? 0;
    final schedule = alloc['schedule'] as String? ?? 'Scheduled Weekly';

    return _buildSubjectCard(
      className: className,
      classId: classId,
      subjectName: subjectName,
      subjectCode: subjectCode,
      isHomeroom: isHomeroom,
      studentCount: studentCount,
      schedule: schedule,
    );
  }

  IconData _getSubjectIcon(String? code) {
    final c = code?.toUpperCase() ?? '';
    if (c.contains('MATH')) return LucideIcons.calculator;
    if (c.contains('SCI') ||
        c.contains('PHY') ||
        c.contains('CHEM') ||
        c.contains('BIO')) {
      return LucideIcons.flaskConical;
    }
    if (c.contains('ENG')) return LucideIcons.bookOpen;
    if (c.contains('HIN') || c.contains('SAN')) return LucideIcons.languages;
    if (c.contains('SST') || c.contains('ECO')) return LucideIcons.globe;
    if (c.contains('COMP') || c.contains('CS')) return LucideIcons.laptop;
    return LucideIcons.bookOpen;
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
                  child: Icon(_getSubjectIcon(subjectCode),
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
                              'Class in Charge',
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeacherSyllabusScreen(
                          classSectionId: classId,
                          className: className,
                          subjectName: subjectName,
                          subjectCode: subjectCode,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimaryLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.bookOpen,
                            size: 14, color: AppColors.brandPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'Syllabus',
                          style: AppTypography.pillLabel.copyWith(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  // ==========================================
  // VIEW: ANNOUNCEMENTS HUB
  // View circulars, post circular, delete circulars
  // ==========================================
  Widget _buildAnnouncementsHubView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Announcements & Circulars Hub',
                      style: AppTypography.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'View previous circulars, publish class notices, and manage announcements.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.inkSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _openNoticeDialog(),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('New Circular'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (_announcements.isEmpty)
          BentoCard(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  const Icon(LucideIcons.megaphone,
                      size: 40, color: AppColors.inkSecondary),
                  const SizedBox(height: 12),
                  Text('No Announcements Yet', style: AppTypography.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'No circulars or notices have been posted. Click "New Circular" above to publish one.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.inkSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ..._announcements.map((a) {
            final isHoliday = a.category == AnnouncementCategory.holiday;
            final isNotice = a.category == AnnouncementCategory.classNotice;
            final isUrgent = a.category == AnnouncementCategory.urgent;
            final isExpired = a.isExpired;
            final isAdminNotice = a.authorRole == 'admin';
            final canDelete = !isAdminNotice;
            final dateStr =
                DateFormat('dd MMM yyyy, hh:mm a').format(a.createdAt);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BentoCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isUrgent
                                    ? const Color(0xFFFEE2E2)
                                    : isHoliday
                                        ? const Color(0xFFFFEDD5)
                                        : isNotice
                                            ? const Color(0xFFE0E7FF)
                                            : AppColors.brandPrimaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isUrgent
                                    ? '🚨 URGENT'
                                    : isHoliday
                                        ? '🏖️ HOLIDAY'
                                        : isNotice
                                            ? '📝 CLASS NOTICE'
                                            : '📢 SCHOOL NOTICE',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isUrgent
                                      ? AppColors.danger
                                      : isHoliday
                                          ? AppColors.coralStreak
                                          : isNotice
                                              ? const Color(0xFF4338CA)
                                              : AppColors.brandPrimary,
                                ),
                              ),
                            ),
                            if (a.targetClassSectionId != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.canvasBackground,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: AppColors.cardBorder),
                                ),
                                child: Text(
                                  'Class Target',
                                  style: AppTypography.monospace(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.inkSecondary,
                                  ),
                                ),
                              ),
                            ],
                            if (isExpired) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Text(
                                  'EXPIRED',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            if (a.isPinned)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.pin,
                                        size: 13, color: AppColors.coralStreak),
                                    SizedBox(width: 3),
                                    Text('PINNED',
                                        style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.coralStreak)),
                                  ],
                                ),
                              ),
                            if (canDelete)
                              IconButton(
                                icon: const Icon(LucideIcons.trash2,
                                    size: 16, color: AppColors.danger),
                                tooltip: 'Delete Circular',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: AppColors.cardSurface,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      title: Row(
                                        children: [
                                          const Icon(LucideIcons.trash2,
                                              color: AppColors.danger, size: 20),
                                          const SizedBox(width: 8),
                                          Text('Delete Circular',
                                              style: AppTypography.titleMedium),
                                        ],
                                      ),
                                      content: Text(
                                        'Are you sure you want to delete "${a.title}"?',
                                        style: const TextStyle(
                                            color: AppColors.inkPrimary),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.danger,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true && mounted) {
                                    await ref
                                        .read(schoolRepositoryProvider)
                                        .deleteAnnouncement(a.id);
                                    setState(() {
                                      _announcements
                                          .removeWhere((item) => item.id == a.id);
                                    });
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Announcement deleted successfully!'),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.canvasBackground,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.shieldCheck,
                                        size: 11, color: AppColors.inkMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Admin Notice',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9.5,
                                        color: AppColors.inkMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(a.title, style: AppTypography.titleMedium),
                    const SizedBox(height: 4),
                    Text(a.body,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.inkSecondary)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(LucideIcons.clock,
                            size: 12.5, color: AppColors.inkMuted),
                        const SizedBox(width: 5),
                        Text(
                          dateStr,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.inkMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (a.authorName != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            '•  ${a.authorName}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: AppColors.inkSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (a.expiresAt != null) ...[
                          const SizedBox(width: 12),
                          Icon(LucideIcons.timer,
                              size: 12.5,
                              color: isExpired
                                  ? AppColors.danger
                                  : AppColors.inkMuted),
                          const SizedBox(width: 5),
                          Text(
                            isExpired
                                ? 'Expired'
                                : 'Expires: ${DateFormat("dd MMM, hh:mm a").format(a.expiresAt!)}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: isExpired
                                  ? AppColors.danger
                                  : AppColors.inkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
