import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/models/student.dart';
import '../../core/models/syllabus.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/tactile_feedback.dart';
import '../../core/widgets/unified_media_viewer.dart';

class SyllabusVaultScreen extends ConsumerStatefulWidget {
  const SyllabusVaultScreen({super.key});

  @override
  ConsumerState<SyllabusVaultScreen> createState() =>
      _SyllabusVaultScreenState();
}

class _SyllabusVaultScreenState extends ConsumerState<SyllabusVaultScreen>
    with WidgetsBindingObserver {
  String _selectedTerm = 'all';
  List<Syllabus> _syllabi = [];
  bool _isLoading = true;
  final Set<String> _expandedCards = {'syl-math-half', 'syl-sci-half'};

  final List<({String key, String label})> _terms = const [
    (key: 'all', label: 'All Terms'),
    (key: 'unit_test_1', label: 'UT 1'),
    (key: 'half_yearly', label: 'Half Yearly'),
    (key: 'unit_test_2', label: 'UT 2'),
    (key: 'annual_finals', label: 'Finals'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSyllabi();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSyllabi();
    }
  }

  Future<void> _loadSyllabi() async {
    var currentStudent = ref.read(currentStudentProvider);
    if (currentStudent == null && (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST'))) {
      currentStudent = await SessionService.getSavedStudent();
      if (currentStudent != null && mounted) {
        ref.read(currentStudentProvider.notifier).state = currentStudent;
      }
    }
    final classId = currentStudent?.classSectionId ?? '';
    if (classId.isEmpty) {
      if (mounted) {
        setState(() {
          _syllabi = [];
          _isLoading = false;
        });
      }
      return;
    }

    final repo = ref.read(schoolRepositoryProvider);
    final list = await repo.getSyllabiForClass(
      classId,
      examTerm: _selectedTerm == 'all' ? null : _selectedTerm,
    );

    if (!mounted) return;
    setState(() {
      _syllabi = list;
      _isLoading = false;
    });
  }

  void _onTermChanged(String term) {
    if (_selectedTerm == term) return;
    setState(() {
      _selectedTerm = term;
      _isLoading = true;
    });
    _loadSyllabi();
  }

  void _toggleAccordion(String id) {
    setState(() {
      if (_expandedCards.contains(id)) {
        _expandedCards.remove(id);
      } else {
        _expandedCards.add(id);
      }
    });
  }

  void _openSyllabusPdf(Syllabus syllabus) {
    if (syllabus.attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF document attached to this syllabus topic.')),
      );
      return;
    }

    UnifiedMediaViewer.show(context, items: syllabus.attachments);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(appRefreshTriggerProvider, (prev, next) {
      if (next > (prev ?? 0)) {
        _loadSyllabi();
      }
    });
    ref.listen<Student?>(currentStudentProvider, (prev, next) {
      if (next != null && (prev == null || prev.id != next.id)) {
        _loadSyllabi();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Text('Syllabus Vault', style: AppTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.studentHome);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Term Selector Chips
            _buildTermFilterChips(),

            const SizedBox(height: 12),

            // Subject Syllabus List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _syllabi.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount: _syllabi.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final syllabus = _syllabi[index];
                            final isExpanded = _expandedCards.contains(syllabus.id);
                            return _buildSyllabusAccordionCard(syllabus, isExpanded);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermFilterChips() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _terms.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final term = _terms[index];
          final isSelected = _selectedTerm == term.key;

          return TactileFeedback(
            onTap: () => _onTermChanged(term.key),
            child: AnimatedContainer(
              duration: AppMotion.durationFast,
              curve: AppMotion.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandPrimary
                    : AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.brandPrimary
                      : AppColors.cardBorder,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.brandPrimary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  term.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.inkPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyllabusAccordionCard(Syllabus syllabus, bool isExpanded) {
    final (bg, fg) = AppColors.getSubjectColors(syllabus.subjectName);

    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar (Tappable to expand)
          TactileFeedback(
            onTap: () => _toggleAccordion(syllabus.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSubjectIcon(syllabus.subjectCode),
                      color: fg,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              syllabus.subjectName,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                syllabus.termDisplayName,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          syllabus.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: AppMotion.durationFast,
                    curve: AppMotion.easeOut,
                    child: const Icon(
                      LucideIcons.chevronDown,
                      color: AppColors.inkMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content with AnimatedSize
          AnimatedSize(
            duration: AppMotion.durationStandard,
            curve: AppMotion.easeOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(height: 1, color: AppColors.cardBorder),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chapters & Weightage Breakdown',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.secondarySurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                syllabus.chaptersOverview,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.inkPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Open Official Syllabus PDF Button
                            TactileFeedback(
                              onTap: () => _openSyllabusPdf(syllabus),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.brandPrimaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.brandPrimary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      LucideIcons.fileText,
                                      size: 16,
                                      color: AppColors.brandPrimary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Open Syllabus Document & Guidelines (PDF)',
                                      style: AppTypography.labelMedium.copyWith(
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
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.bookOpen, size: 40, color: AppColors.inkMuted),
          const SizedBox(height: 12),
          Text('No syllabus uploaded yet', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Subject teachers will publish terms soon',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  IconData _getSubjectIcon(String? code) {
    final c = code?.toUpperCase() ?? '';
    if (c.contains('MATH')) return LucideIcons.calculator;
    if (c.contains('SCI')) return LucideIcons.flaskConical;
    if (c.contains('ENG')) return LucideIcons.bookOpen;
    if (c.contains('HIN')) return LucideIcons.languages;
    if (c.contains('SST')) return LucideIcons.globe;
    if (c.contains('COMP')) return LucideIcons.laptop;
    return LucideIcons.bookOpen;
  }
}
