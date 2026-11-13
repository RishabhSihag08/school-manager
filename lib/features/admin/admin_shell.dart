import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../core/providers/core_providers.dart';
import '../../core/repositories/school_repository.dart';
import '../../core/router/app_router.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/school_manager_logo.dart';
import '../../core/widgets/tactile_feedback.dart';
import 'admin_teachers_screen.dart';
import 'excel_upload_wizard.dart';

/// Responsive Desktop & Web Admin Shell with Sidebar Navigation:
/// 1. Classes & Sections (with + Create New Class Section)
/// 2. Student Directory (Search, Class Filter, Full Edit Modal)
/// 3. Subject Allocation Matrix
/// 4. 3-Step Excel Wizard
/// 5. Announcements Hub
/// 6. Timetable Builder
/// 7. Settings / OTA Release Dashboard
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _selectedNavIndex = 0;
  bool _isLoading = false;
  bool _isLoadingStudents = false;

  final List<ClassSection> _classes = [];
  final List<Announcement> _announcements = [];
  final List<Teacher> _teachers = [];
  final List<Student> _allStudents = [];
  final List<Map<String, dynamic>> _subjectAllocations = [];

  String _selectedClassFilterId = 'all';
  String _studentSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _selectedTimetableClassId;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(schoolRepositoryProvider);
    final classes = await repo.getAllClassSections();
    final announcements = await repo.getAnnouncements();
    final allStudents = await repo.getAllStudents();
    final allocations = await repo.getAllSubjectAllocations();
    final teachers = await repo.getAllTeachers();

    if (mounted) {
      setState(() {
        _classes.clear();
        _classes.addAll(classes);
        _announcements.clear();
        _announcements.addAll(announcements);
        _teachers.clear();
        _teachers.addAll(teachers);
        _allStudents.clear();
        _allStudents.addAll(allStudents);
        _subjectAllocations.clear();
        _subjectAllocations.addAll(allocations);
        if (_selectedTimetableClassId == null ||
            !_classes.any((c) => c.id == _selectedTimetableClassId)) {
          if (_classes.isNotEmpty) {
            _selectedTimetableClassId = _classes.first.id;
          }
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoadingStudents = true);
    final repo = ref.read(schoolRepositoryProvider);
    final allStudents = await repo.getAllStudents();
    if (mounted) {
      setState(() {
        _allStudents.clear();
        _allStudents.addAll(allStudents);
        _isLoadingStudents = false;
      });
    }
  }

  String _generateClassCode(
    int grade,
    String section, {
    String? customName,
  }) {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final rnd = Random();
    final suffix = String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
    if (customName != null && customName.trim().isNotEmpty) {
      final clean = customName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      final prefix = clean.length > 3 ? clean.substring(0, 3) : clean;
      return '$prefix-$suffix';
    }
    return '$grade${section.toUpperCase()}-$suffix';
  }

  Future<ClassSection> _createClassSection(
    SchoolRepository repo, {
    required int grade,
    required String section,
    required String classCode,
    String? classTeacherName,
    String? customName,
  }) async {
    try {
      return await repo.createClassSection(
        grade: grade,
        section: section,
        classCode: classCode,
        classTeacherName: classTeacherName,
        customName: customName,
      );
    } catch (_) {}

    if (AppConfig.hasSupabaseCredentials) {
      final client = Supabase.instance.client;
      String? academicYearId;
      try {
        final yr = await client
            .from('academic_years')
            .select('id')
            .eq('is_active', true)
            .maybeSingle();
        if (yr != null && yr['id'] != null) {
          academicYearId = yr['id'] as String;
        } else {
          final anyYr = await client
              .from('academic_years')
              .select('id')
              .limit(1)
              .maybeSingle();
          if (anyYr != null && anyYr['id'] != null) {
            academicYearId = anyYr['id'] as String;
          }
        }
      } catch (_) {}

      final insertData = <String, dynamic>{
        'grade': grade,
        'section': section.toUpperCase(),
        'class_code': classCode.toUpperCase(),
        'is_code_locked': false,
      };
      if (academicYearId != null) {
        insertData['academic_year_id'] = academicYearId;
      }
      if (classTeacherName != null && classTeacherName.isNotEmpty) {
        insertData['class_teacher_name'] = classTeacherName;
      }
      if (customName != null && customName.isNotEmpty) {
        insertData['custom_name'] = customName;
      }

      final res = await client
          .from('class_sections')
          .insert(insertData)
          .select()
          .single();
      return ClassSection.fromJson(res);
    }

    final prefix = (customName != null && customName.trim().isNotEmpty)
        ? customName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')
        : 'class-$grade';
    final newClass = ClassSection(
      id: '$prefix${section.toLowerCase()}-${DateTime.now().millisecondsSinceEpoch % 10000}',
      grade: grade,
      section: section.toUpperCase(),
      classTeacherName: classTeacherName,
      classCode: classCode.toUpperCase(),
      customName: customName,
      academicYear: AppConfig.currentAcademicYear,
    );
    return newClass;
  }

  Future<Student> _updateStudent(
    SchoolRepository repo,
    Student student,
  ) async {
    try {
      return await repo.updateStudent(student);
    } catch (_) {}

    if (AppConfig.hasSupabaseCredentials) {
      final client = Supabase.instance.client;
      final payload = <String, dynamic>{
        'full_name': student.fullName,
        'roll_no': student.rollNo,
        'admission_no': student.admissionNo,
        'class_section_id': student.classSectionId,
        'parent_name': student.parentName,
        'parent_phone': student.parentPhone,
        'pin_hash': student.pinHash,
      };
      final res = await client
          .from('students')
          .update(payload)
          .eq('id', student.id)
          .select()
          .single();
      return Student.fromJson(res);
    }

    return student;
  }

  List<Student> get _filteredStudents {
    return _allStudents.where((s) {
      if (_selectedClassFilterId != 'all' &&
          s.classSectionId != _selectedClassFilterId) {
        return false;
      }
      if (_studentSearchQuery.trim().isNotEmpty) {
        final q = _studentSearchQuery.trim().toLowerCase();
        final nameMatch = s.fullName.toLowerCase().contains(q);
        final rollMatch = s.rollNo.toString().contains(q);
        final admMatch = (s.admissionNo ?? '').toLowerCase().contains(q);
        final phoneMatch = s.parentPhone.toLowerCase().contains(q);
        final parentMatch = s.parentName.toLowerCase().contains(q);
        return nameMatch || rollMatch || admMatch || phoneMatch || parentMatch;
      }
      return true;
    }).toList();
  }

  String _getClassName(String classSectionId) {
    for (final cls in _classes) {
      if (cls.id == classSectionId) return cls.displayName;
    }
    return 'Class $classSectionId';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppColors.canvasBackground,
              elevation: 0,
              title: Text('Admin Console', style: AppTypography.titleLarge),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.logOut, color: AppColors.danger),
                  tooltip: 'Log Out',
                  onPressed: () => _confirmLogout(context),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.settings,
                      color: AppColors.inkPrimary),
                  onPressed: () => context.push(AppRoutes.settings),
                ),
              ],
            ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebarContent(isDrawer: true)),
      body: Row(
        children: [
          // Desktop Fixed Left Sidebar
          if (isDesktop)
            Container(
              width: 260,
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                border: Border(right: BorderSide(color: AppColors.cardBorder)),
              ),
              child: _buildSidebarContent(isDrawer: false),
            ),

          // Main Content View
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.brandPrimary))
                : _buildSelectedView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent({required bool isDrawer}) {
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
              subtitle: 'Office Admin Shell',
            ),
          ),
        ),

        const Divider(height: 1, color: AppColors.cardBorder),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            children: [
              _navItem(0, 'Classes & Sections', LucideIcons.layoutGrid,
                  badge: '${_classes.length}'),
              _navItem(1, 'Teachers Directory', LucideIcons.graduationCap,
                  badge: '${_teachers.length}'),
              _navItem(2, 'Student Directory', LucideIcons.users,
                  badge: '${_allStudents.length}'),
              _navItem(3, 'Subject Matrix', LucideIcons.layers),
              _navItem(4, 'Excel Marks Wizard', LucideIcons.fileSpreadsheet,
                  badge: 'Step 1-3'),
              _navItem(5, 'Announcements Hub', LucideIcons.megaphone),
              _navItem(6, 'Timetable Builder', LucideIcons.calendar),
              _navItem(7, 'Settings & OTA Release', LucideIcons.sparkles),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.cardBorder),

        // Bottom User Profile & Logout
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandPrimaryLight,
                      border: Border.all(color: AppColors.brandPrimary),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.shield,
                          size: 18, color: AppColors.brandPrimary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Office Admin', style: AppTypography.titleSmall),
                        Text('School Code: 08412',
                            style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildLogoutButton(isCompact: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navItem(int index, String title, IconData icon, {String? badge}) {
    final isSelected = _selectedNavIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TactileFeedback(
        onTap: () {
          setState(() => _selectedNavIndex = index);
          if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
            Navigator.pop(context);
          }
        },
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

  Widget _buildLogoutButton({bool isCompact = false}) {
    return TactileFeedback(
      onTap: () => _confirmLogout(context),
      child: Container(
        margin: EdgeInsets.symmetric(
            vertical: isCompact ? 8 : 4, horizontal: isCompact ? 8 : 0),
        padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 12, vertical: isCompact ? 6 : 9),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.logOut, size: 14, color: AppColors.danger),
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
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.logOut, color: AppColors.danger, size: 22),
            const SizedBox(width: 10),
            Text('Log Out', style: AppTypography.titleMedium),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of School Manager?',
          style: TextStyle(color: AppColors.inkPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final router = GoRouter.of(context);
      await SessionService.clearSession();
      ref.read(currentStaffProvider.notifier).state = null;
      ref.read(activeRoleProvider.notifier).state = 'student';
      router.go(AppRoutes.onboarding);
    }
  }

  Widget _buildSelectedView() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildClassesAndSectionsView();
      case 1:
        return const AdminTeachersScreen(isEmbedded: true);
      case 2:
        return _buildStudentDirectoryView();
      case 3:
        return _buildSubjectAllocationMatrixView();
      case 4:
        return const ExcelUploadWizard();
      case 5:
        return _buildAnnouncementsHubView();
      case 6:
        return _buildTimetableBuilderView();
      case 7:
      default:
        return _buildSettingsAndOtaView();
    }
  }

  // ==========================================
  // VIEW 1: CLASSES & SECTIONS
  // ==========================================
  Widget _buildClassesAndSectionsView() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ListView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      children: [
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Classes & Sections Management',
                      style: AppTypography.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Manage Class Join Codes, Homeroom Teachers, and Student Enrollment Rosters',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.inkSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _openCreateClassDialog,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('+ Create New Class / Section'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Classes & Sections Management',
                        style: AppTypography.headlineSmall),
                    Text(
                      'Manage Class Join Codes, Homeroom Teachers, and Student Enrollment Rosters',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.inkSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _openCreateClassDialog,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('+ Create New Class / Section'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),

        if (_classes.isEmpty)
          BentoCard(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  const Icon(LucideIcons.layoutGrid,
                      size: 40, color: AppColors.inkSecondary),
                  const SizedBox(height: 12),
                  Text('No Class Sections Found',
                      style: AppTypography.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Click "+ Create New Class / Section" above to establish grade sections.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.inkSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ..._classes.map((cls) {
            final classStudents =
                _allStudents.where((s) => s.classSectionId == cls.id).toList();

            final badgeText = cls.section.trim().isNotEmpty
                ? '${cls.grade}-${cls.section}'
                : '${cls.grade}';

            final teacherDisplay = (cls.classTeacherName != null &&
                    cls.classTeacherName!.trim().isNotEmpty)
                ? cls.classTeacherName!
                : 'None';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BentoCard(
                padding: const EdgeInsets.all(16),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Tier: Avatar (50x50) + Class Name + Student count badge + Lock status chip on right
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.brandPrimaryLight,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    badgeText,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.brandPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        cls.displayName,
                                        style: AppTypography.titleMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.canvasBackground,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: AppColors.cardBorder),
                                      ),
                                      child: Text(
                                        '${classStudents.length} Students',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.inkSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cls.isCodeLocked
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cls.isCodeLocked ? 'Locked' : 'Open',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: cls.isCodeLocked
                                        ? AppColors.warning
                                        : AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Middle Tier: Class in Charge name ('Class in Charge: ...')
                          Text(
                            'Class in Charge: $teacherDisplay',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Bottom Tier: Join code badge (with ticket icon) + 'View Roster' & Delete buttons
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.canvasBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.ticket,
                                        size: 14,
                                        color: AppColors.brandPrimary),
                                    const SizedBox(width: 6),
                                    Text(
                                      cls.classCode,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.inkPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _confirmDeleteClass(cls),
                                    icon: const Icon(LucideIcons.trash2,
                                        size: 14, color: AppColors.danger),
                                    label: const Text('Delete'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                      side: const BorderSide(
                                          color: Color(0xFFFCA5A5)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedClassFilterId = cls.id;
                                        _selectedNavIndex = 1;
                                      });
                                    },
                                    icon: const Icon(LucideIcons.users, size: 14),
                                    label: const Text('View Roster'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimaryLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                badgeText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(cls.displayName,
                                        style: AppTypography.titleMedium),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.canvasBackground,
                                        borderRadius: BorderRadius.circular(6),
                                        border:
                                            Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: Text(
                                        '${classStudents.length} Students',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.inkSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Class in Charge: $teacherDisplay',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Join Code Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.canvasBackground,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.ticket,
                                        size: 14, color: AppColors.brandPrimary),
                                    const SizedBox(width: 6),
                                    Text(
                                      cls.classCode,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.inkPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Lock status chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cls.isCodeLocked
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cls.isCodeLocked ? 'Locked' : 'Open',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: cls.isCodeLocked
                                        ? AppColors.warning
                                        : AppColors.success,
                                  ),
                                ),
                              ),
                              // View Roster quick button
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedClassFilterId = cls.id;
                                    _selectedNavIndex = 1;
                                  });
                                },
                                icon: const Icon(LucideIcons.users, size: 14),
                                label: const Text('View Roster'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                              // Delete Class button
                              OutlinedButton.icon(
                                onPressed: () => _confirmDeleteClass(cls),
                                icon: const Icon(LucideIcons.trash2,
                                    size: 14, color: AppColors.danger),
                                label: const Text('Delete Class'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
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

  Future<void> _confirmDeleteClass(ClassSection cls) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.trash2,
                  color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Class'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${cls.displayName}? This will remove all student links and timetables for this class.',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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
      try {
        setState(() {
          _classes.removeWhere((c) => c.id == cls.id);
          _allStudents.removeWhere((s) => s.classSectionId == cls.id);
        });
        await ref.read(schoolRepositoryProvider).deleteClassSection(cls.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${cls.displayName} deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          await _loadAdminData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete class: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _openCreateClassDialog() {
    bool isCustomName = false;
    int selectedGrade = 9;
    String selectedSection = 'A';
    final customNameCtrl = TextEditingController();
    final codeCtrl = TextEditingController(
      text: _generateClassCode(9, 'A'),
    );
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.plus,
                        color: AppColors.brandPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Create New Class / Section',
                      style: AppTypography.titleMedium),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select grade (1st to 12th) or create a custom class name (Nursery, Prep, Commerce, Arts).',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.inkSecondary),
                      ),
                      const SizedBox(height: 16),

                      // Format Toggle: Standard Grade vs Custom Class Name
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Standard Grade'),
                            icon: Icon(LucideIcons.graduationCap, size: 16),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Custom Class Name'),
                            icon: Icon(LucideIcons.sparkles, size: 16),
                          ),
                        ],
                        selected: {isCustomName},
                        onSelectionChanged: isSubmitting
                            ? null
                            : (Set<bool> newSelection) {
                                setDialogState(() {
                                  isCustomName = newSelection.first;
                                  codeCtrl.text = _generateClassCode(
                                    selectedGrade,
                                    selectedSection,
                                    customName: isCustomName ? customNameCtrl.text : null,
                                  );
                                });
                              },
                      ),
                      const SizedBox(height: 16),

                      if (!isCustomName) ...[
                        // Standard Grade & Section Selectors
                        Row(
                          children: [
                            Expanded(
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Grade / Standard *',
                                  prefixIcon: const Icon(LucideIcons.graduationCap,
                                      size: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: selectedGrade,
                                    isExpanded: true,
                                    items: List.generate(12, (index) {
                                      final g = index + 1;
                                      return DropdownMenuItem<int>(
                                        value: g,
                                        child: Text('Class $g'),
                                      );
                                    }),
                                    onChanged: isSubmitting
                                        ? null
                                        : (val) {
                                            if (val != null) {
                                              setDialogState(() {
                                                selectedGrade = val;
                                                codeCtrl.text = _generateClassCode(
                                                    selectedGrade, selectedSection);
                                              });
                                            }
                                          },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Section Selector
                            SizedBox(
                              width: 120,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Section *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedSection,
                                    isExpanded: true,
                                    items: ['A', 'B', 'C', 'D', 'E', 'F']
                                        .map((sec) => DropdownMenuItem(
                                              value: sec,
                                              child: Text('Sec $sec'),
                                            ))
                                        .toList(),
                                    onChanged: isSubmitting
                                        ? null
                                        : (val) {
                                            if (val != null) {
                                              setDialogState(() {
                                                selectedSection = val;
                                                codeCtrl.text = _generateClassCode(
                                                    selectedGrade, selectedSection);
                                              });
                                            }
                                          },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Custom Class Name & Section
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: customNameCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Custom Class Name *',
                                  hintText: 'Enter custom class name',
                                  prefixIcon: const Icon(LucideIcons.sparkles, size: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (val) {
                                  setDialogState(() {
                                    codeCtrl.text = _generateClassCode(
                                      selectedGrade,
                                      selectedSection,
                                      customName: val,
                                    );
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Section *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedSection,
                                    isExpanded: true,
                                    items: ['A', 'B', 'C', 'D', 'E', 'F']
                                        .map((sec) => DropdownMenuItem(
                                              value: sec,
                                              child: Text('Sec $sec'),
                                            ))
                                        .toList(),
                                    onChanged: isSubmitting
                                        ? null
                                        : (val) {
                                            if (val != null) {
                                              setDialogState(() {
                                                selectedSection = val;
                                                codeCtrl.text = _generateClassCode(
                                                  selectedGrade,
                                                  selectedSection,
                                                  customName: customNameCtrl.text,
                                                );
                                              });
                                            }
                                          },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Class Join Code with Regenerate button
                      TextFormField(
                        controller: codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Class Join Code (6-8 chars) *',
                          hintText: 'Enter class join code',
                          helperText:
                              'Students use this unique code on the welcome screen to enroll.',
                          prefixIcon:
                              const Icon(LucideIcons.ticket, size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            tooltip: 'Generate new random code',
                            onPressed: isSubmitting
                                ? null
                                : () {
                                    setDialogState(() {
                                      codeCtrl.text = _generateClassCode(
                                        selectedGrade,
                                        selectedSection,
                                        customName: isCustomName ? customNameCtrl.text : null,
                                      );
                                    });
                                  },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (isCustomName && customNameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a custom class name'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }

                          final code = codeCtrl.text.trim().toUpperCase();
                          if (code.isEmpty) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter or generate a Class Code'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            final repo = ref.read(schoolRepositoryProvider);
                            final customName = isCustomName ? customNameCtrl.text.trim() : null;
                            final grade = isCustomName ? 0 : selectedGrade;

                            final created = await _createClassSection(
                              repo,
                              grade: grade,
                              section: selectedSection,
                              classCode: code,
                              customName: customName,
                            );

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }

                            if (mounted) {
                              if (!_classes.any((c) => c.id == created.id)) {
                                _classes.add(created);
                              }
                              await _loadAdminData();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${created.displayName} created! Join code: $code'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to create class: $e'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Class'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // VIEW 2: STUDENT DIRECTORY & EDITING
  // ==========================================
  Widget _buildStudentDirectoryView() {
    final filtered = _filteredStudents;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ListView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      children: [
        // Header Row / Column
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student Directory & Records',
                  style: AppTypography.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Search, view, and modify student profiles, roll numbers, assigned classes, parent contacts, and login PINs.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.inkSecondary),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Showing ${filtered.length} of ${_allStudents.length} Students',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student Directory & Records',
                        style: AppTypography.headlineSmall),
                    Text(
                      'Search, view, and modify student profiles, roll numbers, assigned classes, parent contacts, and login PINs.',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.inkSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Showing ${filtered.length} of ${_allStudents.length} Students',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),

        // Filter and Search Toolbar
        BentoCard(
          padding: const EdgeInsets.all(14),
          child: isMobile
              ? Column(
                  children: [
                    // Search Input (Full Width on mobile)
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() => _studentSearchQuery = val);
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Search by name, roll no, admission no, or phone...',
                        hintStyle: AppTypography.bodySmall
                            .copyWith(color: AppColors.inkMuted),
                        prefixIcon:
                            const Icon(LucideIcons.search, size: 18),
                        suffixIcon: _studentSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _studentSearchQuery = '');
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Class Filter Dropdown + Refresh Button
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Filter Class',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.cardBorder),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedClassFilterId,
                                isDense: true,
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem<String>(
                                    value: 'all',
                                    child: Text(
                                        'All Classes (${_allStudents.length})'),
                                  ),
                                  ..._classes.map((cls) {
                                    final count = _allStudents
                                        .where((s) => s.classSectionId == cls.id)
                                        .length;
                                    return DropdownMenuItem<String>(
                                      value: cls.id,
                                      child: Text(
                                          '${cls.displayName} ($count)'),
                                    );
                                  }),
                                ],
                                onChanged: (val) {
                                  setState(() =>
                                      _selectedClassFilterId = val ?? 'all');
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Refresh Student Roster',
                          icon: _isLoadingStudents
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.brandPrimary,
                                  ),
                                )
                              : const Icon(LucideIcons.refreshCw,
                                  size: 18, color: AppColors.brandPrimary),
                          onPressed:
                              _isLoadingStudents ? null : _loadStudents,
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Search Input
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() => _studentSearchQuery = val);
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Search by name, roll no, admission no, or phone...',
                          hintStyle: AppTypography.bodySmall
                              .copyWith(color: AppColors.inkMuted),
                          prefixIcon:
                              const Icon(LucideIcons.search, size: 18),
                          suffixIcon: _studentSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(LucideIcons.x, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _studentSearchQuery = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Class Filter Dropdown using InputDecorator to avoid deprecation warning
                    Expanded(
                      flex: 2,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Filter Class',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedClassFilterId,
                            isDense: true,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem<String>(
                                value: 'all',
                                child:
                                    Text('All Classes (${_allStudents.length})'),
                              ),
                              ..._classes.map((cls) {
                                final count = _allStudents
                                    .where((s) => s.classSectionId == cls.id)
                                    .length;
                                return DropdownMenuItem<String>(
                                  value: cls.id,
                                  child: Text('${cls.displayName} ($count)'),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(
                                  () => _selectedClassFilterId = val ?? 'all');
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Reload Students button
                    IconButton(
                      tooltip: 'Refresh Student Roster',
                      icon: _isLoadingStudents
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brandPrimary,
                              ),
                            )
                          : const Icon(LucideIcons.refreshCw,
                              size: 18, color: AppColors.brandPrimary),
                      onPressed: _isLoadingStudents ? null : _loadStudents,
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),

        // Students List / Empty state
        if (_isLoadingStudents)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.brandPrimary),
            ),
          )
        else if (filtered.isEmpty)
          BentoCard(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  const Icon(LucideIcons.userX,
                      size: 44, color: AppColors.inkSecondary),
                  const SizedBox(height: 12),
                  Text('No Students Found', style: AppTypography.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    _studentSearchQuery.isNotEmpty
                        ? 'No students match "$_studentSearchQuery" in the selected class filter.'
                        : 'No students enrolled in this class section yet.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.inkSecondary),
                  ),
                  if (_studentSearchQuery.isNotEmpty ||
                      _selectedClassFilterId != 'all') ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _studentSearchQuery = '';
                          _selectedClassFilterId = 'all';
                        });
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          ...filtered.map((student) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BentoCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar Initials
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandPrimaryLight,
                        border: Border.all(
                            color: AppColors.brandPrimary.withValues(alpha: 0.2)),
                      ),
                      child: Center(
                        child: Text(
                          student.fullName.isNotEmpty
                              ? student.fullName
                                  .trim()
                                  .split(' ')
                                  .map((e) => e.isNotEmpty ? e[0] : '')
                                  .take(2)
                                  .join()
                                  .toUpperCase()
                              : 'ST',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Student Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(student.fullName,
                                  style: AppTypography.titleMedium),
                              // Roll No Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.canvasBackground,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: AppColors.cardBorder),
                                ),
                                child: Text(
                                  'Roll #${student.rollNo}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                              ),
                              if (student.admissionNo != null &&
                                  student.admissionNo!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.canvasBackground,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppColors.cardBorder),
                                  ),
                                  child: Text(
                                    student.admissionNo!,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10.5,
                                      color: AppColors.inkSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              // Class Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.brandPrimaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getClassName(student.classSectionId),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brandPrimary,
                                  ),
                                ),
                              ),
                              // Parent Phone
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.phone,
                                      size: 13, color: AppColors.inkSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${student.parentName} (${student.parentPhone})',
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                              // PIN indicator
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.keyRound,
                                      size: 13, color: AppColors.inkSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'PIN: ${student.pinHash}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      color: AppColors.inkSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Edit Button (compact tactile pill)
                    TactileFeedback(
                      onTap: () => _openEditStudentDialog(student),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.brandPrimary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.pencil,
                                size: 13, color: AppColors.brandPrimary),
                            const SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _openEditStudentDialog(Student student) {
    final nameCtrl = TextEditingController(text: student.fullName);
    final rollCtrl = TextEditingController(text: student.rollNo.toString());
    final admCtrl = TextEditingController(text: student.admissionNo ?? '');
    final parentNameCtrl = TextEditingController(text: student.parentName);
    final parentPhoneCtrl = TextEditingController(text: student.parentPhone);
    final pinCtrl = TextEditingController(text: student.pinHash);
    String selectedClassId = student.classSectionId;
    bool obscurePin = true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final activeClassId = _classes.any((c) => c.id == selectedClassId)
                ? selectedClassId
                : (_classes.isNotEmpty ? _classes.first.id : '');

            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.userCheck,
                        color: AppColors.brandPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit Student Profile',
                            style: AppTypography.titleMedium),
                        Text(
                          'ID: ${student.id}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: const Icon(LucideIcons.user, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Roll Number & Admission Number Row
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: rollCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Roll No *',
                                prefixIcon:
                                    const Icon(LucideIcons.hash, size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: admCtrl,
                              decoration: InputDecoration(
                                labelText: 'Admission Number',
                                hintText: 'Enter admission number',
                                prefixIcon: const Icon(LucideIcons.fileText,
                                    size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Assigned Class Section using InputDecorator
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Assigned Class Section *',
                          prefixIcon:
                              const Icon(LucideIcons.layoutGrid, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: activeClassId.isNotEmpty ? activeClassId : null,
                            isExpanded: true,
                            items: _classes.map((cls) {
                              return DropdownMenuItem<String>(
                                value: cls.id,
                                child: Text(cls.displayName),
                              );
                            }).toList(),
                            onChanged: isSaving
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setDialogState(() => selectedClassId = val);
                                    }
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Parent Name
                      TextFormField(
                        controller: parentNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Parent / Guardian Name *',
                          prefixIcon: const Icon(LucideIcons.users, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Parent Phone
                      TextFormField(
                        controller: parentPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Parent Mobile Phone Number *',
                          hintText: '+919876543210',
                          prefixIcon: const Icon(LucideIcons.phone, size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 4-Digit Secret PIN
                      TextFormField(
                        controller: pinCtrl,
                        obscureText: obscurePin,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'Student Login PIN (4 digits) *',
                          counterText: '',
                          helperText:
                              'Admin can reset or update the student login PIN here.',
                          prefixIcon:
                              const Icon(LucideIcons.keyRound, size: 18),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  obscurePin
                                      ? LucideIcons.eye
                                      : LucideIcons.eyeOff,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setDialogState(
                                      () => obscurePin = !obscurePin);
                                },
                              ),
                              TextButton(
                                onPressed: () {
                                  setDialogState(() => pinCtrl.text = '1234');
                                },
                                child: const Text('Reset',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          final rollText = rollCtrl.text.trim();
                          final roll = int.tryParse(rollText);
                          final adm = admCtrl.text.trim();
                          final parentName = parentNameCtrl.text.trim();
                          final parentPhone = parentPhoneCtrl.text.trim();
                          final pin = pinCtrl.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter student name'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }
                          if (roll == null) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid numeric roll number'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }
                          if (pin.isEmpty) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a 4-digit PIN'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          final updatedStudent = student.copyWith(
                            fullName: name,
                            rollNo: roll,
                            admissionNo: adm.isNotEmpty ? adm : null,
                            classSectionId: selectedClassId,
                            parentName: parentName,
                            parentPhone: parentPhone,
                            pinHash: pin,
                          );

                          try {
                            final repo = ref.read(schoolRepositoryProvider);
                            final saved = await _updateStudent(repo, updatedStudent);

                            final idx = _allStudents
                                .indexWhere((s) => s.id == saved.id);
                            if (idx != -1) {
                              _allStudents[idx] = saved;
                            }

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }

                            if (mounted) {
                              await _loadStudents();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Student "${saved.fullName}" updated successfully!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update student: $e'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // VIEW 3: SUBJECT ALLOCATION MATRIX
  // ==========================================
  Widget _buildSubjectAllocationMatrixView() {
    final subjects = ['Mathematics', 'Science', 'English', 'Social Science', 'Hindi'];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject Allocation Matrix',
                style: AppTypography.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Enforces 1 Homeroom Class Teacher limit and tracks subject teaching load across classes.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.inkSecondary),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (_classes.isEmpty)
          BentoCard(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  const Icon(LucideIcons.layers,
                      size: 40, color: AppColors.inkSecondary),
                  const SizedBox(height: 12),
                  Text('No Class Sections Configured',
                      style: AppTypography.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Create classes in the "Classes & Sections" tab to configure subject allocations.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.inkSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: BentoCard(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(AppColors.canvasBackground),
                columns: [
                  const DataColumn(label: Text('Class Section')),
                  ...subjects.map((s) => DataColumn(label: Text(s))),
                ],
                rows: _classes.map((cls) {
                  return DataRow(
                    cells: [
                      DataCell(Text(cls.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      ...subjects.map((subName) {
                        // Find allocated teacher for this class and subject
                        final match = _subjectAllocations.cast<Map<String, dynamic>?>().firstWhere(
                          (a) =>
                              a?['class_section_id'] == cls.id &&
                              a?['subject_name']?.toString().toLowerCase() ==
                                  subName.toLowerCase(),
                          orElse: () => null,
                        );

                        if (match != null && match['teacher_name'] != null) {
                          final teacherName = match['teacher_name'].toString();
                          final isHomeroom = cls.classTeacherName == teacherName;
                          return DataCell(_matrixCell(
                              isHomeroom ? '$teacherName (Homeroom)' : teacherName));
                        }

                        // If not specifically allocated, show "Not allocated"
                        return DataCell(_matrixCell('Not allocated'));
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _matrixCell(String teacher) {
    if (teacher == 'Not allocated') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.canvasBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          'Not allocated',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.inkMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    final isHomeroom = teacher.contains('Homeroom');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(teacher.replaceAll(' (Homeroom)', ''),
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
        if (isHomeroom) ...[
          const SizedBox(width: 4),
          const Icon(LucideIcons.crown, color: Colors.amber, size: 14),
        ],
      ],
    );
  }

  // ==========================================
  // VIEW 4: ANNOUNCEMENTS HUB
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
                  Text(
                    'Post school-wide holiday notices, exam alerts, and urgent broadcasts.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.inkSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _openCreateAnnouncementDialog,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('New Circular'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (_announcements.isEmpty)
          BentoCard(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  const Icon(LucideIcons.megaphone,
                      size: 40, color: AppColors.inkSecondary),
                  const SizedBox(height: 12),
                  Text('No Announcements Found',
                      style: AppTypography.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Click "+ New Circular" above to post school-wide notices.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.inkSecondary),
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
            final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(a.createdAt);

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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (a.isPinned) ...[
                              const Icon(LucideIcons.pin,
                                  size: 14, color: AppColors.coralStreak),
                              const SizedBox(width: 4),
                              const Text('PINNED BANNER',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.coralStreak)),
                              const SizedBox(width: 12),
                            ],
                            IconButton(
                              icon: const Icon(LucideIcons.trash2,
                                  size: 16, color: AppColors.danger),
                              tooltip: 'Delete Announcement',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _confirmDeleteAnnouncement(a),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(a.title, style: AppTypography.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      a.body,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.inkSecondary),
                    ),
                    const SizedBox(height: 10),
                    // Publication Date, Time & Expiry
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
                                ? 'Expired on ${DateFormat("dd MMM, hh:mm a").format(a.expiresAt!)}'
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

  Future<void> _confirmDeleteAnnouncement(Announcement a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.trash2,
                  color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Announcement'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this announcement?',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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
      try {
        await ref.read(schoolRepositoryProvider).deleteAnnouncement(a.id);
        if (mounted) {
          setState(() {
            _announcements.removeWhere((item) => item.id == a.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete announcement: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _openCreateAnnouncementDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    bool isPinned = true;
    AnnouncementCategory category = AnnouncementCategory.general;
    int expiryDays = 0; // 0 = Never
    String selectedTargetClassId = 'all';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('Post School Circular',
                  style: AppTypography.titleMedium),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Circular Title',
                        hintText: 'e.g. Annual Sports Meet 2026',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Circular Details / Instructions',
                        hintText: 'Enter details, guidelines, or schedule...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Notice Category & Expiration
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<AnnouncementCategory>(
                            initialValue: category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: AnnouncementCategory.general,
                                child: Text('General 📢'),
                              ),
                              DropdownMenuItem(
                                value: AnnouncementCategory.holiday,
                                child: Text('Holiday 🏖️'),
                              ),
                              DropdownMenuItem(
                                value: AnnouncementCategory.exam,
                                child: Text('Exam Alert 📝'),
                              ),
                              DropdownMenuItem(
                                value: AnnouncementCategory.event,
                                child: Text('Event 🎉'),
                              ),
                              DropdownMenuItem(
                                value: AnnouncementCategory.urgent,
                                child: Text('Urgent 🚨'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => category = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: expiryDays,
                            decoration: const InputDecoration(
                              labelText: 'Expires In',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('Never'),
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Target Audience
                    DropdownButtonFormField<String>(
                      initialValue: selectedTargetClassId,
                      decoration: const InputDecoration(
                        labelText: 'Target Audience',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('Whole School (All Classes)'),
                        ),
                        ..._classes.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.displayName),
                            )),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedTargetClassId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: isPinned,
                      onChanged: (val) =>
                          setDialogState(() => isPinned = val ?? false),
                      title:
                          const Text('Pin as Top Hero Banner for all students'),
                      contentPadding: EdgeInsets.zero,
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
                    final repo = ref.read(schoolRepositoryProvider);
                    final newAnn = Announcement(
                      id: 'ann-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      body: bodyCtrl.text.trim(),
                      category: category,
                      isPinned: isPinned,
                      targetClassSectionId: selectedTargetClassId == 'all'
                          ? null
                          : selectedTargetClassId,
                      createdAt: DateTime.now(),
                      expiresAt: expiryDays > 0
                          ? DateTime.now().add(Duration(days: expiryDays))
                          : null,
                      authorRole: 'admin',
                      authorName: 'School Administration',
                    );
                    await repo.createAnnouncement(newAnn);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      setState(() {
                        _announcements.removeWhere((a) => a.id == newAnn.id);
                        _announcements.insert(0, newAnn);
                      });
                      await _loadAdminData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Broadcast'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // VIEW 5: TIMETABLE BUILDER
  // ==========================================
  Widget _buildTimetableBuilderView() {
    final activeClassId = _selectedTimetableClassId ??
        (_classes.isNotEmpty ? _classes.first.id : null);
    final selectedClass = _classes.firstWhere(
      (c) => c.id == activeClassId,
      orElse: () => _classes.isNotEmpty
          ? _classes.first
          : const ClassSection(
              id: 'none',
              grade: 0,
              section: '',
              classCode: '',
            ),
    );

    final hasUploadedFile = selectedClass.timetableFileUrl != null &&
        selectedClass.timetableFileUrl!.isNotEmpty;
    final fileDisplay = selectedClass.timetableFileUrl ?? '';
    final fileName = fileDisplay.contains('/')
        ? fileDisplay.split('/').last
        : (fileDisplay.isNotEmpty ? fileDisplay : 'timetable_master.pdf');

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timetable Builder & Master Chart',
                style: AppTypography.headlineSmall),
            Text(
              'Upload official timetable photos/PDFs or configure period-by-period schedules.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.inkSecondary),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Class Selector Card
        BentoCard(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 500;
              final dropdown = SizedBox(
                width: isSmall ? double.infinity : 220,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Select Class / Section',
                    prefixIcon: const Icon(LucideIcons.graduationCap, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _classes.any((c) => c.id == activeClassId)
                          ? activeClassId
                          : (_classes.isNotEmpty ? _classes.first.id : null),
                      isExpanded: true,
                      items: _classes.map((cls) {
                        return DropdownMenuItem<String>(
                          value: cls.id,
                          child: Text(
                            cls.displayName,
                            style: AppTypography.bodyMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTimetableClassId = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              );

              if (isSmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.calendarDays,
                            color: AppColors.brandPrimary, size: 20),
                        const SizedBox(width: 8),
                        Text('Manage Class Timetable',
                            style: AppTypography.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a class to manage or view its master timetable chart.',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 12),
                    if (_classes.isNotEmpty)
                      dropdown
                    else
                      Text('No classes available',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.inkMuted)),
                  ],
                );
              }

              return Row(
                children: [
                  const Icon(LucideIcons.calendarDays,
                      color: AppColors.brandPrimary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manage Class Timetable',
                            style: AppTypography.labelMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Choose a class to manage or view its master timetable chart.',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_classes.isNotEmpty)
                    dropdown
                  else
                    Text('No classes available',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.inkMuted)),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Timetable Management Card for Selected Class
        BentoCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Master Timetable Chart for ${selectedClass.displayName}',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hasUploadedFile
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasUploadedFile
                          ? LucideIcons.checkCircle2
                          : LucideIcons.clock,
                      size: 14,
                      color: hasUploadedFile
                          ? AppColors.success
                          : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasUploadedFile
                          ? 'Uploaded (Document)'
                          : 'Default Schedule Active',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasUploadedFile
                            ? AppColors.success
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Students and parents view this timetable in their daily student schedule and Unified In-App Viewer.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 16),
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.canvasBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasUploadedFile
                            ? LucideIcons.fileCheck2
                            : LucideIcons.image,
                        size: 36,
                        color: hasUploadedFile
                            ? AppColors.success
                            : AppColors.brandPrimary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasUploadedFile
                            ? 'Master Timetable Uploaded (${selectedClass.displayName})'
                            : 'No Custom Timetable Uploaded for ${selectedClass.displayName}',
                        style: AppTypography.bodyMedium,
                      ),
                      Text(
                        hasUploadedFile
                            ? '$fileName • Ready for Students'
                            : 'Upload a PDF, PNG, or JPEG master chart',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: selectedClass.id == 'none'
                        ? null
                        : () async {
                            try {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: [
                                  'png',
                                  'jpg',
                                  'jpeg',
                                  'pdf',
                                  'webp'
                                ],
                              );
                              if (result != null &&
                                  result.files.isNotEmpty) {
                                final file = result.files.first;
                                String savedPath = file.name;
                                try {
                                  final appDir = await getApplicationDocumentsDirectory();
                                  final timetableDir = Directory('${appDir.path}/timetables');
                                  if (!timetableDir.existsSync()) {
                                    await timetableDir.create(recursive: true);
                                  }
                                  final ext = file.extension ?? 'jpg';
                                  final targetFile = File('${timetableDir.path}/timetable_${selectedClass.id}.$ext');
                                  if (file.path != null && File(file.path!).existsSync()) {
                                    await File(file.path!).copy(targetFile.path);
                                    savedPath = targetFile.path;
                                  } else if (file.bytes != null) {
                                    await targetFile.writeAsBytes(file.bytes!);
                                    savedPath = targetFile.path;
                                  }
                                } catch (_) {
                                  if (file.path != null) savedPath = file.path!;
                                }

                                final repo =
                                    ref.read(schoolRepositoryProvider);
                                await repo.updateClassTimetableUrl(
                                    selectedClass.id, savedPath);

                                final idx = _classes.indexWhere(
                                    (c) => c.id == selectedClass.id);
                                if (idx != -1) {
                                  setState(() {
                                    _classes[idx] = _classes[idx].copyWith(
                                        timetableFileUrl: savedPath);
                                  });
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Timetable for ${selectedClass.displayName} uploaded successfully!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Upload failed: $e'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(LucideIcons.uploadCloud, size: 16),
                    label: const Text('Upload Timetable (Image / Document)'),
                  ),
                  OutlinedButton.icon(
                    onPressed: selectedClass.id == 'none'
                        ? null
                        : () {
                            context.push(
                              AppRoutes.studentTimetable,
                              extra: selectedClass.id,
                            );
                          },
                    icon: const Icon(LucideIcons.eye, size: 16),
                    label: const Text('Preview Timetable'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 6: SETTINGS & OTA RELEASE DASHBOARD
  // ==========================================
  Widget _buildSettingsAndOtaView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OTA Update & Release Dashboard',
                style: AppTypography.headlineSmall),
            Text(
              'Monitor distributed APK builds and trigger instant background patches without Play Store delays.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.inkSecondary),
            ),
          ],
        ),
        const SizedBox(height: 20),

        BentoCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.sparkles,
                        color: AppColors.brandPrimary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('School Manager Production Channel',
                            style: AppTypography.titleMedium),
                        Text(
                          'Target: GitHub Releases API (owner/school-management-system)',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'v1.0.0+1',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.cardBorder),
              const SizedBox(height: 16),

              Text('Built-in OTA Capabilities:',
                  style: AppTypography.titleSmall),
              const SizedBox(height: 8),
              _bulletItem(
                  'Semantic version checking on app cold-start via GitHub Releases'),
              _bulletItem(
                  'Background streaming download with real-time percentage progress'),
              _bulletItem(
                  'Silent patch application or graceful sparkly restart snackbar'),
              _bulletItem(
                  'OpenFilex native installer launch for major APK upgrades'),

              const SizedBox(height: 20),

              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.settings),
                    icon: const Icon(LucideIcons.settings, size: 16),
                    label: const Text('Open Settings Screen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(
                  color: AppColors.brandPrimary, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }
}
