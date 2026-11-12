import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/models/timetable.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/tactile_feedback.dart';
import '../../core/widgets/unified_media_viewer.dart';

class TimetableViewScreen extends ConsumerStatefulWidget {
  const TimetableViewScreen({super.key});

  @override
  ConsumerState<TimetableViewScreen> createState() =>
      _TimetableViewScreenState();
}

class _TimetableViewScreenState extends ConsumerState<TimetableViewScreen> {
  late int _selectedDayOfWeek; // 1 = Mon .. 6 = Sat
  List<TimetablePeriod> _periods = [];
  bool _isLoading = true;

  final List<({int dayIndex, String shortName, String fullName})> _days = const [
    (dayIndex: 1, shortName: 'Mon', fullName: 'Monday'),
    (dayIndex: 2, shortName: 'Tue', fullName: 'Tuesday'),
    (dayIndex: 3, shortName: 'Wed', fullName: 'Wednesday'),
    (dayIndex: 4, shortName: 'Thu', fullName: 'Thursday'),
    (dayIndex: 5, shortName: 'Fri', fullName: 'Friday'),
    (dayIndex: 6, shortName: 'Sat', fullName: 'Saturday'),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-select today or default to Monday if Sunday
    final weekday = DateTime.now().weekday;
    _selectedDayOfWeek = (weekday >= 1 && weekday <= 6) ? weekday : 1;
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    final currentStudent = ref.read(currentStudentProvider);
    final classId = currentStudent?.classSectionId ?? 'class-8b';

    final repo = ref.read(schoolRepositoryProvider);
    final list = await repo.getTimetableForDay(classId, _selectedDayOfWeek);

    if (!mounted) return;
    setState(() {
      _periods = list;
      _isLoading = false;
    });
  }

  void _onDaySelected(int day) {
    if (_selectedDayOfWeek == day) return;
    setState(() {
      _selectedDayOfWeek = day;
      _isLoading = true;
    });
    _loadTimetable();
  }

  void _openMasterChartViewer() {
    UnifiedMediaViewer.show(
      context,
      items: const [
        MediaAttachmentItem(
          title: 'Class 8-B Master Timetable (Academic Year 2026-27)',
          url:
              'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=1200',
          type: 'image',
          sizeKb: 650,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Text('Class Timetable', style: AppTypography.titleLarge),
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
        actions: [
          TactileFeedback(
            onTap: _openMasterChartViewer,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brandPrimaryLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.brandPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.image,
                    size: 15,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Master Chart',
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
      body: SafeArea(
        child: Column(
          children: [
            // Floating Day Selector Strip
            _buildDaySelectorStrip(),

            const SizedBox(height: 12),

            // Timetable Periods List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _periods.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount: _periods.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final period = _periods[index];
                            if (period.isBreak) {
                              return _buildBreakBanner(period);
                            }
                            return _buildPeriodCard(period);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelectorStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.canvasBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _days.map((day) {
          final isSelected = _selectedDayOfWeek == day.dayIndex;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: TactileFeedback(
                onTap: () => _onDaySelected(day.dayIndex),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brandPrimary
                          : AppColors.cardBorder,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(
                              color: Color(0x334F46E5),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      day.shortName,
                      style: GoogleFonts.plusJakartaSans(
                        color: isSelected ? Colors.white : AppColors.inkPrimary,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodCard(TimetablePeriod period) {
    final (bg, fg) = AppColors.getSubjectColors(period.subjectName);

    return BentoCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Left Period & Time Badge
          SizedBox(
            width: 78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Period ${period.periodNo}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  period.startTime,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkPrimary,
                  ),
                ),
                Text(
                  period.endTime,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),

          // Vertical divider line
          Container(
            height: 44,
            width: 1,
            color: AppColors.cardBorder,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // Subject Pill & Teacher Details
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSubjectIcon(period.subjectCode),
                    color: fg,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        period.subjectName ?? 'Subject',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        period.teacherName ?? 'Teacher',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakBanner(TimetablePeriod period) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.houseYellowBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.houseYellow.withValues(alpha: 0.4),
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.coffee, color: AppColors.houseYellow, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.breakLabel ?? '🍱 Recess / Lunch Break',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF92400E),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${period.startTime} – ${period.endTime} • Rest & Refreshment',
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFFB45309),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
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
          const Icon(LucideIcons.calendarOff, size: 40, color: AppColors.inkMuted),
          const SizedBox(height: 12),
          Text('No periods scheduled', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text('Classes resume on next school day', style: AppTypography.bodySmall),
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
