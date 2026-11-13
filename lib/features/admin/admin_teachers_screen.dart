import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/models.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/tactile_feedback.dart';

/// Admin Console screen to view, search, add, edit, and delete teachers.
/// Can be used as an embedded view inside AdminShell or as a standalone route.
class AdminTeachersScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;

  const AdminTeachersScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<AdminTeachersScreen> createState() =>
      _AdminTeachersScreenState();
}

class _AdminTeachersScreenState extends ConsumerState<AdminTeachersScreen> {
  bool _isLoading = true;
  final List<Teacher> _teachers = [];
  final List<ClassSection> _classes = [];

  String _searchQuery = '';
  String _filter = 'all'; // 'all', 'homeroom', 'subject'
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _revealedPins = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(schoolRepositoryProvider);
    final teachers = await repo.getAllTeachers();
    final classes = await repo.getAllClassSections();

    if (mounted) {
      setState(() {
        _teachers.clear();
        _teachers.addAll(teachers);
        _classes.clear();
        _classes.addAll(classes);
        _isLoading = false;
      });
    }
  }

  List<Teacher> get _filteredTeachers {
    return _teachers.where((t) {
      if (_filter == 'homeroom' && !t.isClassTeacher) return false;
      if (_filter == 'subject' && (t.subjectName == null || t.subjectName!.isEmpty)) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final nameMatch = t.fullName.toLowerCase().contains(q);
        final codeMatch = t.loginCode.toLowerCase().contains(q);
        final phoneMatch = t.phone.toLowerCase().contains(q);
        final subMatch = (t.subjectName ?? '').toLowerCase().contains(q);
        final hrMatch = (t.homeroomClassName ?? '').toLowerCase().contains(q);
        return nameMatch || codeMatch || phoneMatch || subMatch || hrMatch;
      }
      return true;
    }).toList();
  }

  String _getClassName(String classId) {
    for (final c in _classes) {
      if (c.id == classId) return c.displayName;
    }
    return classId;
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.brandPrimary),
          )
        : RefreshIndicator(
            color: AppColors.brandPrimary,
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 14),
                _buildStatsStrip(),
                const SizedBox(height: 14),
                _buildSearchAndFilterBar(),
                const SizedBox(height: 14),
                _buildTeachersList(),
              ],
            ),
          );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: AppColors.canvasBackground,
        elevation: 0,
        title: Text('Teachers Management', style: AppTypography.titleLarge),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(child: content),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Header Section
  // ---------------------------------------------------------------------------
  Widget _buildHeaderSection() {
    return BentoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Faculty & Teachers Directory',
                        style: AppTypography.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'View, edit login credentials, change homeroom in-charges, assign subjects, or delete teacher accounts.',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TactileFeedback(
                onTap: _openAddTeacherDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandPrimary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.userPlus,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Add Teacher',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Stats Strip
  // ---------------------------------------------------------------------------
  Widget _buildStatsStrip() {
    final totalTeachers = _teachers.length;
    final homeroomTeachers =
        _teachers.where((t) => t.isClassTeacher).length;
    final distinctSubjects = _teachers
        .map((t) => t.subjectName)
        .where((s) => s != null && s.isNotEmpty)
        .toSet()
        .length;

    return Row(
      children: [
        Expanded(
          child: BentoCard(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.users,
                        size: 14, color: AppColors.brandPrimary),
                    const SizedBox(width: 6),
                    Text('Total Staff', style: AppTypography.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalTeachers',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: BentoCard(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.crown,
                        size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Text('Class In-Charge', style: AppTypography.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$homeroomTeachers',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: BentoCard(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.bookOpen,
                        size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Text('Subjects', style: AppTypography.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$distinctSubjects',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Search and Filter Bar
  // ---------------------------------------------------------------------------
  Widget _buildSearchAndFilterBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(LucideIcons.search,
                  size: 16, color: AppColors.inkMuted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by teacher name, code (T-101), phone, or subject...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTypography.bodyMedium,
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _filterChip('all', 'All Teachers (${_teachers.length})'),
              const SizedBox(width: 8),
              _filterChip('homeroom', 'Class In-Charge (${_teachers.where((t) => t.isClassTeacher).length})'),
              const SizedBox(width: 8),
              _filterChip('subject', 'Subject Specialists'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _filter == key;
    return TactileFeedback(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimaryLight
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.brandPrimary : AppColors.inkSecondary,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Teachers List
  // ---------------------------------------------------------------------------
  Widget _buildTeachersList() {
    final filtered = _filteredTeachers;

    if (filtered.isEmpty) {
      return BentoCard(
        padding: const EdgeInsets.all(32),
        child: AppEmptyState(
          icon: LucideIcons.userX,
          title: _searchQuery.isNotEmpty
              ? 'No matching teachers found'
              : 'No Teachers Registered',
          subtitle: _searchQuery.isNotEmpty
              ? 'Try modifying your search query or clear the filter.'
              : 'Add your first faculty member using the "Add Teacher" button above.',
          ctaLabel: _searchQuery.isNotEmpty ? 'Clear Search' : 'Add First Teacher',
          onCtaPressed: _searchQuery.isNotEmpty
              ? () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _filter = 'all';
                  });
                }
              : _openAddTeacherDialog,
        ),
      );
    }

    return Column(
      children: filtered.map((teacher) => _buildTeacherCard(teacher)).toList(),
    );
  }

  Widget _buildTeacherCard(Teacher teacher) {
    final isPinRevealed = _revealedPins.contains(teacher.id);
    final (bg, fg) = AppColors.getSubjectColors(teacher.subjectName ?? 'Teacher');

    return BentoCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with subject color
              CircleAvatar(
                radius: 20,
                backgroundColor: bg,
                child: Text(
                  teacher.fullName.isNotEmpty
                      ? teacher.fullName.substring(0, 1).toUpperCase()
                      : 'T',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: fg,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(teacher.fullName,
                            style: AppTypography.titleMedium),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.canvasBackground,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            teacher.loginCode.toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandPrimary,
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
                        // PIN chip with reveal toggle
                        TactileFeedback(
                          onTap: () {
                            setState(() {
                              if (isPinRevealed) {
                                _revealedPins.remove(teacher.id);
                              } else {
                                _revealedPins.add(teacher.id);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySurface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPinRevealed
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.keyRound,
                                  size: 11,
                                  color: AppColors.inkSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPinRevealed
                                      ? 'PIN: ${teacher.pin}'
                                      : 'PIN: ••••',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10.5,
                                    color: AppColors.inkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Phone chip
                        if (teacher.phone.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.phone,
                                  size: 12, color: AppColors.inkSecondary),
                              const SizedBox(width: 4),
                              Text(
                                teacher.phone,
                                style: GoogleFonts.inter(
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
              // Action buttons: Edit and Delete
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TactileFeedback(
                    onTap: () => _openEditTeacherDialog(teacher),
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
                              size: 12, color: AppColors.brandPrimary),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TactileFeedback(
                    onTap: () => _confirmDeleteTeacher(teacher),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.trash2,
                        size: 14,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 8),
          // Homeroom & Subject Badges
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Homeroom In-Charge Tag
              if (teacher.isClassTeacher)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.crown,
                          size: 12, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Text(
                        '${teacher.homeroomClassName ?? _getClassName(teacher.homeroomClassId!)} In-Charge',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'No Homeroom Assigned',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
              // Subject Tag
              if (teacher.subjectName != null &&
                  teacher.subjectName!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.bookOpen, size: 12, color: fg),
                      const SizedBox(width: 4),
                      Text(
                        '${teacher.subjectName} (${teacher.subjectCode ?? "SUB"})',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                ),
              // Teaching Classes List
              if (teacher.teachingClassIds.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.graduationCap,
                        size: 12, color: AppColors.inkSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Teaches: ${teacher.teachingClassIds.map(_getClassName).join(", ")}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Add Teacher Dialog
  // ---------------------------------------------------------------------------
  void _openAddTeacherDialog() {
    final nameCtrl = TextEditingController();
    // Suggest next code: T-101, T-102 etc.
    int nextNum = 101;
    for (final t in _teachers) {
      final match = RegExp(r'[tT]-?(\d+)').firstMatch(t.loginCode);
      if (match != null) {
        final n = int.tryParse(match.group(1)!);
        if (n != null && n >= nextNum) nextNum = n + 1;
      }
    }
    final codeCtrl = TextEditingController(text: 'T-$nextNum');
    final pinCtrl = TextEditingController(
        text: (1000 + Random().nextInt(9000)).toString());
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String? selectedHomeroomId;
    String selectedSubjectName = 'Mathematics';
    String selectedSubjectCode = 'MATH';
    final selectedClassIds = <String>{};
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.userPlus,
                            size: 18, color: AppColors.brandPrimary),
                      ),
                      const SizedBox(width: 10),
                      Text('Register New Teacher',
                          style: AppTypography.titleLarge),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Full Name
                        Text('Full Name *', style: AppTypography.titleSmall),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Sunita Sharma',
                            prefixIcon: Icon(LucideIcons.user, size: 18),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Login Code & Security PIN
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Login Code *',
                                      style: AppTypography.titleSmall),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: codeCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. T-101',
                                      prefixIcon: Icon(LucideIcons.badge, size: 18),
                                    ),
                                    style: GoogleFonts.jetBrainsMono(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('4-Digit PIN *',
                                      style: AppTypography.titleSmall),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: pinCtrl,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    decoration: InputDecoration(
                                      hintText: '1234',
                                      counterText: '',
                                      prefixIcon:
                                          const Icon(LucideIcons.keyRound, size: 18),
                                      suffixIcon: IconButton(
                                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                                        tooltip: 'Generate Random PIN',
                                        onPressed: () {
                                          setSheetState(() {
                                            pinCtrl.text = (1000 + Random().nextInt(9000)).toString();
                                          });
                                        },
                                      ),
                                    ),
                                    style: GoogleFonts.jetBrainsMono(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Phone & Email
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Phone Number',
                                      style: AppTypography.titleSmall),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. 9876543210',
                                      prefixIcon: Icon(LucideIcons.phone, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Email Address',
                                      style: AppTypography.titleSmall),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      hintText: 'teacher@school.in',
                                      prefixIcon: Icon(LucideIcons.mail, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Homeroom Class In-Charge Dropdown
                        Text('Homeroom Class In-Charge (Optional)',
                            style: AppTypography.titleSmall),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.secondarySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: selectedHomeroomId,
                              isExpanded: true,
                              hint: const Text('None (Subject Specialist Only)'),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('None (Subject Specialist Only)'),
                                ),
                                ..._classes.map((cls) {
                                  return DropdownMenuItem<String?>(
                                    value: cls.id,
                                    child: Text(
                                        '${cls.displayName} (Code: ${cls.classCode})'),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setSheetState(() {
                                  selectedHomeroomId = val;
                                  if (val != null) selectedClassIds.add(val);
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Primary Subject Selection
                        Text('Primary Subject Specialization',
                            style: AppTypography.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ('Mathematics', 'MATH'),
                            ('Science', 'SCI'),
                            ('English', 'ENG'),
                            ('Social Science', 'SST'),
                            ('Hindi', 'HIN'),
                            ('Computer Science', 'CS'),
                            ('Physical Education', 'PE'),
                            ('Art & Music', 'ART'),
                          ].map((sub) {
                            final isSel = selectedSubjectName == sub.$1;
                            return ChoiceChip(
                              label: Text(sub.$1),
                              selected: isSel,
                              onSelected: (val) {
                                if (val) {
                                  setSheetState(() {
                                    selectedSubjectName = sub.$1;
                                    selectedSubjectCode = sub.$2;
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Teaching Classes Multi-Select
                        Text('Teaching Classes (Where this teacher takes periods)',
                            style: AppTypography.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _classes.map((cls) {
                            final isSel = selectedClassIds.contains(cls.id);
                            return FilterChip(
                              label: Text(cls.displayName),
                              selected: isSel,
                              onSelected: (val) {
                                setSheetState(() {
                                  if (val) {
                                    selectedClassIds.add(cls.id);
                                  } else {
                                    selectedClassIds.remove(cls.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final name = nameCtrl.text.trim();
                                  final code = codeCtrl.text.trim();
                                  final pin = pinCtrl.text.trim();

                                  if (name.isEmpty || code.isEmpty || pin.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please provide Teacher Name, Login Code, and PIN'),
                                      ),
                                    );
                                    return;
                                  }

                                  setSheetState(() => isSaving = true);
                                  try {
                                    final repo = ref.read(schoolRepositoryProvider);
                                    String? hrName;
                                    if (selectedHomeroomId != null) {
                                      hrName = _getClassName(selectedHomeroomId!);
                                    }

                                    await repo.registerStaff(
                                      fullName: name,
                                      role: 'teacher',
                                      loginCode: code,
                                      pin: pin,
                                      phone: phoneCtrl.text.trim(),
                                      homeroomClassId: selectedHomeroomId,
                                      homeroomClassName: hrName,
                                      subjectName: selectedSubjectName,
                                      subjectCode: selectedSubjectCode,
                                      teachingClassIds: selectedClassIds.toList(),
                                    );

                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Registered $name ($code) successfully!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                      _loadData();
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error adding teacher: $e'),
                                          backgroundColor: AppColors.danger,
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(LucideIcons.check, size: 18),
                          label: Text(
                            isSaving ? 'Registering Teacher...' : 'Save & Register Teacher',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Edit Teacher Dialog ("Change everything about a teacher")
  // ---------------------------------------------------------------------------
  void _openEditTeacherDialog(Teacher teacher) {
    final nameCtrl = TextEditingController(text: teacher.fullName);
    final codeCtrl = TextEditingController(text: teacher.loginCode);
    final pinCtrl = TextEditingController(text: teacher.pin);
    final phoneCtrl = TextEditingController(text: teacher.phone);
    final emailCtrl = TextEditingController(text: teacher.email ?? '');

    String? selectedHomeroomId = teacher.homeroomClassId;
    String selectedSubjectName = teacher.subjectName ?? 'Mathematics';
    String selectedSubjectCode = teacher.subjectCode ?? 'MATH';
    final selectedClassIds = Set<String>.from(teacher.teachingClassIds);
    if (selectedHomeroomId != null) selectedClassIds.add(selectedHomeroomId);

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.pencil,
                            size: 18, color: AppColors.brandPrimary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit Teacher Profile',
                                style: AppTypography.titleLarge),
                            Text(
                              'Update name, code, credentials, homeroom, and subjects',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Full Name
                        Text('Full Name *', style: AppTypography.titleSmall),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Sunita Sharma',
                            prefixIcon: Icon(LucideIcons.user, size: 18),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Login Code & Security PIN
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Login Code *',
                                      style: AppTypography.titleSmall),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: codeCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. T-101',
                                      prefixIcon: Icon(LucideIcons.badge, size: 18),
                                    ),
                                    style: GoogleFonts.jetBrainsMono(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Security PIN *',
                                      style: AppTypography.titleSmall),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: pinCtrl,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    decoration: InputDecoration(
                                      hintText: '1234',
                                      counterText: '',
                                      prefixIcon:
                                          const Icon(LucideIcons.keyRound, size: 18),
                                      suffixIcon: IconButton(
                                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                                        tooltip: 'Generate Random PIN',
                                        onPressed: () {
                                          setSheetState(() {
                                            pinCtrl.text = (1000 + Random().nextInt(9000)).toString();
                                          });
                                        },
                                      ),
                                    ),
                                    style: GoogleFonts.jetBrainsMono(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Phone & Email
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Phone Number',
                                      style: AppTypography.titleSmall),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. 9876543210',
                                      prefixIcon: Icon(LucideIcons.phone, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Email Address',
                                      style: AppTypography.titleSmall),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      hintText: 'teacher@school.in',
                                      prefixIcon: Icon(LucideIcons.mail, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Homeroom Class In-Charge Dropdown
                        Text('Homeroom Class In-Charge',
                            style: AppTypography.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          'The Class Teacher can lock student join codes and access the Class Homeroom Banner.',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.secondarySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: selectedHomeroomId,
                              isExpanded: true,
                              hint: const Text('None (Subject Specialist Only)'),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('None (Subject Specialist Only)'),
                                ),
                                ..._classes.map((cls) {
                                  return DropdownMenuItem<String?>(
                                    value: cls.id,
                                    child: Text(
                                        '${cls.displayName} (Code: ${cls.classCode})'),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setSheetState(() {
                                  selectedHomeroomId = val;
                                  if (val != null) selectedClassIds.add(val);
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Primary Subject Selection
                        Text('Primary Subject Specialization',
                            style: AppTypography.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ('Mathematics', 'MATH'),
                            ('Science', 'SCI'),
                            ('English', 'ENG'),
                            ('Social Science', 'SST'),
                            ('Hindi', 'HIN'),
                            ('Computer Science', 'CS'),
                            ('Physical Education', 'PE'),
                            ('Art & Music', 'ART'),
                          ].map((sub) {
                            final isSel = selectedSubjectName == sub.$1;
                            return ChoiceChip(
                              label: Text(sub.$1),
                              selected: isSel,
                              onSelected: (val) {
                                if (val) {
                                  setSheetState(() {
                                    selectedSubjectName = sub.$1;
                                    selectedSubjectCode = sub.$2;
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Teaching Classes Multi-Select
                        Text('Teaching Classes Allocation',
                            style: AppTypography.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Select all class sections where this teacher conducts classes:',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _classes.map((cls) {
                            final isSel = selectedClassIds.contains(cls.id);
                            return FilterChip(
                              label: Text(cls.displayName),
                              selected: isSel,
                              onSelected: (val) {
                                setSheetState(() {
                                  if (val) {
                                    selectedClassIds.add(cls.id);
                                  } else {
                                    selectedClassIds.remove(cls.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Actions Row: Delete and Save
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      Navigator.pop(ctx);
                                      _confirmDeleteTeacher(teacher);
                                    },
                              icon: const Icon(LucideIcons.trash2,
                                  size: 16, color: AppColors.danger),
                              label: const Text('Delete Account',
                                  style: TextStyle(color: AppColors.danger)),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final name = nameCtrl.text.trim();
                                      final code = codeCtrl.text.trim();
                                      final pin = pinCtrl.text.trim();

                                      if (name.isEmpty || code.isEmpty || pin.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Teacher name, code, and PIN are required'),
                                          ),
                                        );
                                        return;
                                      }

                                      setSheetState(() => isSaving = true);
                                      try {
                                        final repo = ref.read(schoolRepositoryProvider);
                                        String? hrName;
                                        if (selectedHomeroomId != null) {
                                          hrName = _getClassName(selectedHomeroomId!);
                                        }

                                        await repo.updateTeacher(
                                          teacherId: teacher.id,
                                          fullName: name,
                                          loginCode: code,
                                          pin: pin,
                                          phone: phoneCtrl.text.trim(),
                                          email: emailCtrl.text.trim(),
                                          homeroomClassId: selectedHomeroomId,
                                          homeroomClassName: hrName,
                                          subjectName: selectedSubjectName,
                                          subjectCode: selectedSubjectCode,
                                          teachingClassIds: selectedClassIds.toList(),
                                        );

                                        if (ctx.mounted) Navigator.pop(ctx);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Updated teacher details for $name!'),
                                              backgroundColor: AppColors.success,
                                            ),
                                          );
                                          _loadData();
                                        }
                                      } catch (e) {
                                        setSheetState(() => isSaving = false);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error updating teacher: $e'),
                                              backgroundColor: AppColors.danger,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(LucideIcons.check, size: 16),
                              label: Text(
                                isSaving ? 'Saving...' : 'Save Changes',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Delete Confirmation Dialog
  // ---------------------------------------------------------------------------
  void _confirmDeleteTeacher(Teacher teacher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.alertTriangle,
                  color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delete Teacher Account?',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete the account for ${teacher.fullName} (${teacher.loginCode.toUpperCase()})?',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info,
                      size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will revoke their login access and unassign them from any homeroom classes or subject allocations.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(schoolRepositoryProvider);
                await repo.deleteTeacher(teacher.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted teacher ${teacher.fullName}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting teacher: $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            icon: const Icon(LucideIcons.trash2, size: 14),
            label: const Text('Delete Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
