import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/models/models.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/ota_update_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/ota_update_dialog.dart';
import '../../core/widgets/school_manager_logo.dart';
import '../../core/widgets/tactile_feedback.dart';
import 'excel_upload_wizard.dart';

/// Responsive Desktop & Web Admin Shell with Sidebar Navigation:
/// 1. Classes & Sections
/// 2. Subject Allocation Matrix
/// 3. 3-Step Excel Wizard
/// 4. Announcements Hub
/// 5. Timetable Builder
/// 6. Settings / OTA Release Dashboard
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _selectedNavIndex = 2; // Default to Excel Wizard for immediate demo utility
  bool _isLoading = false;

  final List<ClassSection> _classes = [];
  final List<Announcement> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(schoolRepositoryProvider);
    final classes = await repo.getAllClassSections();
    final announcements = await repo.getAnnouncements();

    if (mounted) {
      setState(() {
        _classes.clear();
        _classes.addAll(classes);
        _announcements.clear();
        _announcements.addAll(announcements);
        _isLoading = false;
      });
    }
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
              title: Text('School Manager Admin', style: AppTypography.titleLarge),
              actions: [
                _buildRoleSwitchChip(),
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: SchoolManagerLogo.horizontal(
            iconSize: 38,
            subtitle: 'Office Admin Shell',
          ),
        ),

        const Divider(height: 1, color: AppColors.cardBorder),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            children: [
              _navItem(0, 'Classes & Sections', LucideIcons.layoutGrid),
              _navItem(1, 'Subject Matrix', LucideIcons.layers),
              _navItem(2, 'Excel Marks Wizard', LucideIcons.fileSpreadsheet,
                  badge: 'Step 1-3'),
              _navItem(3, 'Announcements Hub', LucideIcons.megaphone),
              _navItem(4, 'Timetable Builder', LucideIcons.calendar),
              _navItem(5, 'Settings & OTA Release', LucideIcons.sparkles),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.cardBorder),

        // Bottom User Profile & Switcher
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
              TactileFeedback(
                onTap: () {
                  ref.read(activeRoleProvider.notifier).state = 'teacher';
                  context.go(AppRoutes.teacherDashboard);
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
                      const Icon(LucideIcons.userCheck,
                          size: 14, color: AppColors.brandPrimary),
                      const SizedBox(width: 6),
                      Text('Switch to Teacher Dashboard',
                          style: AppTypography.pillLabel),
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

  Widget _buildRoleSwitchChip() {
    return TactileFeedback(
      onTap: () {
        ref.read(activeRoleProvider.notifier).state = 'teacher';
        context.go(AppRoutes.teacherDashboard);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.userCheck,
                size: 14, color: AppColors.brandPrimary),
            const SizedBox(width: 4),
            Text('Teacher', style: AppTypography.pillLabel),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildClassesAndSectionsView();
      case 1:
        return _buildSubjectAllocationMatrixView();
      case 2:
        return const ExcelUploadWizard();
      case 3:
        return _buildAnnouncementsHubView();
      case 4:
        return _buildTimetableBuilderView();
      case 5:
      default:
        return _buildSettingsAndOtaView();
    }
  }

  // ==========================================
  // VIEW 1: CLASSES & SECTIONS
  // ==========================================
  Widget _buildClassesAndSectionsView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Class Sections are synced with academic year 2026-27.'),
                  ),
                );
              },
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add Class Section'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        ..._classes.map((cls) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BentoCard(
              padding: const EdgeInsets.all(18),
              child: Row(
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
                        '${cls.grade}-${cls.section}',
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
                        Text(cls.displayName, style: AppTypography.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Class Teacher: ${cls.classTeacherName ?? "Unassigned"}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
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
                  const SizedBox(width: 12),
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
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // VIEW 2: SUBJECT ALLOCATION MATRIX
  // ==========================================
  Widget _buildSubjectAllocationMatrixView() {
    final matrixData = [
      {
        'class': 'Class 8-B',
        'math': 'Ramesh Sharma (Homeroom)',
        'sci': 'Sunita Rao',
        'eng': 'Vikram Singh',
        'sst': 'Amit Patel',
        'hin': 'Priya Joshi',
      },
      {
        'class': 'Class 6-A',
        'math': 'Ramesh Sharma',
        'sci': 'Sunita Rao (Homeroom)',
        'eng': 'Neha Kapoor',
        'sst': 'Amit Patel',
        'hin': 'Priya Joshi',
      },
      {
        'class': 'Class 7-C',
        'math': 'Ramesh Sharma',
        'sci': 'Pooja Verma',
        'eng': 'Vikram Singh (Homeroom)',
        'sst': 'Rajeev Nair',
        'hin': 'Priya Joshi',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject Allocation Matrix',
                style: AppTypography.headlineSmall),
            Text(
              'Enforces 1 Homeroom Class Teacher limit and tracks subject teaching load across classes.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.inkSecondary),
            ),
          ],
        ),
        const SizedBox(height: 20),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: BentoCard(
            padding: const EdgeInsets.all(16),
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(AppColors.canvasBackground),
              columns: const [
                DataColumn(label: Text('Class Section')),
                DataColumn(label: Text('Mathematics')),
                DataColumn(label: Text('Science')),
                DataColumn(label: Text('English')),
                DataColumn(label: Text('Social Science')),
                DataColumn(label: Text('Hindi')),
              ],
              rows: matrixData.map((row) {
                return DataRow(
                  cells: [
                    DataCell(Text(row['class']!,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(_matrixCell(row['math']!)),
                    DataCell(_matrixCell(row['sci']!)),
                    DataCell(_matrixCell(row['eng']!)),
                    DataCell(_matrixCell(row['sst']!)),
                    DataCell(_matrixCell(row['hin']!)),
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
    final isHomeroom = teacher.contains('Homeroom');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(teacher.replaceAll(' (Homeroom)', ''),
            style: AppTypography.bodySmall),
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
            Column(
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

        ..._announcements.map((a) {
          final isHoliday = a.category == AnnouncementCategory.holiday;
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isHoliday
                              ? const Color(0xFFFFEDD5)
                              : AppColors.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isHoliday ? '🏖️ HOLIDAY CIRCULAR' : '📢 ${a.category.name.toUpperCase()}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isHoliday
                                ? AppColors.coralStreak
                                : AppColors.brandPrimary,
                          ),
                        ),
                      ),
                      if (a.isPinned)
                        const Row(
                          children: [
                            Icon(LucideIcons.pin,
                                size: 14, color: AppColors.coralStreak),
                            SizedBox(width: 4),
                            Text('PINNED BANNER',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.coralStreak)),
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
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _openCreateAnnouncementDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    bool isPinned = true;
    AnnouncementCategory category = AnnouncementCategory.holiday;

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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Circular Title',
                      hintText: 'e.g. Guru Nanak Jayanti Holiday',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Circular Details / Instructions',
                      hintText: 'School will remain closed on...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: isPinned,
                    onChanged: (val) =>
                        setDialogState(() => isPinned = val ?? false),
                    title: const Text('Pin as Top Hero Banner for all students'),
                    contentPadding: EdgeInsets.zero,
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
                        category: category,
                        isPinned: isPinned,
                        createdAt: DateTime.now(),
                      ),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) _loadAdminData();
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

        BentoCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Master Timetable Chart for Class 8-B',
                  style: AppTypography.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Students can view the interactive timeline or view the full graphic chart in the Unified In-App Viewer.',
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
                      const Icon(LucideIcons.image,
                          size: 36, color: AppColors.brandPrimary),
                      const SizedBox(height: 8),
                      Text('Master Timetable Chart Uploaded (Class 8-B)',
                          style: AppTypography.bodyMedium),
                      Text('timetable_8b_2026.png • 840 KB',
                          style: AppTypography.caption),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      context.push(AppRoutes.studentTimetable);
                    },
                    icon: const Icon(LucideIcons.eye, size: 16),
                    label: const Text('Preview Student Timetable'),
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
                  ElevatedButton.icon(
                    onPressed: () {
                      OtaUpdateDialog.show(
                        context,
                        release: OtaReleaseInfo(
                          version: '1.0.1',
                          title: 'School Manager v1.0.1 Update',
                          changelog:
                              '• Excel Marks Validation DataGrid\n• CBSE Report Card PDF Generator\n• 30-Second Roll Call for Class Teachers',
                          apkDownloadUrl: 'https://example.com/update.apk',
                          apkSizeBytes: 18 * 1024 * 1024,
                          isForced: false,
                          publishedAt: DateTime.now(),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: const Text('Test OTA Update Modal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
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
