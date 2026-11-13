import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/tactile_feedback.dart';
import '../../core/widgets/unified_media_viewer.dart';

class TimetablePeriod {
  final int periodNumber;
  final String time;
  final String subject;
  final String teacher;
  final String room;
  final String? notes;

  const TimetablePeriod({
    required this.periodNumber,
    required this.time,
    required this.subject,
    required this.teacher,
    required this.room,
    this.notes,
  });
}

class TimetableViewScreen extends ConsumerStatefulWidget {
  final String? classSectionId;
  const TimetableViewScreen({super.key, this.classSectionId});

  @override
  ConsumerState<TimetableViewScreen> createState() =>
      _TimetableViewScreenState();
}

class _TimetableViewScreenState extends ConsumerState<TimetableViewScreen> {
  bool _isLoading = true;
  String? _className;
  String? _timetableFileUrl;
  int _rotationQuarterTurns = 0;
  String _selectedDay = 'Mon';

  final List<({String key, String label, String full})> _days = const [
    (key: 'Mon', label: 'Mon', full: 'Monday'),
    (key: 'Tue', label: 'Tue', full: 'Tuesday'),
    (key: 'Wed', label: 'Wed', full: 'Wednesday'),
    (key: 'Thu', label: 'Thu', full: 'Thursday'),
    (key: 'Fri', label: 'Fri', full: 'Friday'),
    (key: 'Sat', label: 'Sat', full: 'Saturday'),
  ];

  @override
  void initState() {
    super.initState();
    _initDay();
    _loadTimetable();
  }

  void _initDay() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday:
        _selectedDay = 'Mon';
        break;
      case DateTime.tuesday:
        _selectedDay = 'Tue';
        break;
      case DateTime.wednesday:
        _selectedDay = 'Wed';
        break;
      case DateTime.thursday:
        _selectedDay = 'Thu';
        break;
      case DateTime.friday:
        _selectedDay = 'Fri';
        break;
      case DateTime.saturday:
        _selectedDay = 'Sat';
        break;
      default:
        _selectedDay = 'Mon';
    }
  }

  Future<void> _loadTimetable() async {
    final currentStudent = ref.read(currentStudentProvider);
    final classId =
        widget.classSectionId ?? currentStudent?.classSectionId ?? '';

    if (classId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final repo = ref.read(schoolRepositoryProvider);
    final cls = await repo.getClassSectionById(classId);

    if (!mounted) return;
    setState(() {
      _className = cls?.displayName;
      _timetableFileUrl = cls?.timetableFileUrl;
      _isLoading = false;
    });
  }

  void _openFullScreenViewer() {
    if (_timetableFileUrl == null || _timetableFileUrl!.isEmpty) return;
    UnifiedMediaViewer.show(
      context,
      items: [
        MediaAttachmentItem(
          title: _className != null
              ? '$_className Timetable'
              : 'Class Timetable',
          url: _timetableFileUrl!,
          type: 'image',
        ),
      ],
    );
  }

  void _rotateImage() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  ImageProvider _resolveImageProvider(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    final file = File(url);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return AssetImage(url);
  }

  void _showMasterTimetableModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            final hasPhoto =
                _timetableFileUrl != null && _timetableFileUrl!.isNotEmpty;

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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Master Class Timetable',
                              style: AppTypography.headlineSmall),
                          const SizedBox(height: 2),
                          Text(
                            _className != null
                                ? '$_className Official Schedule'
                                : 'Official Schedule',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (hasPhoto) ...[
                            IconButton(
                              icon: const Icon(LucideIcons.rotateCw, size: 20),
                              tooltip: 'Rotate 90°',
                              onPressed: _rotateImage,
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.maximize2, size: 20),
                              tooltip: 'Full Screen',
                              onPressed: () {
                                Navigator.of(context).pop();
                                _openFullScreenViewer();
                              },
                            ),
                          ],
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: hasPhoto
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: RotatedBox(
                              quarterTurns: _rotationQuarterTurns,
                              child: PhotoView(
                                imageProvider:
                                    _resolveImageProvider(_timetableFileUrl!),
                                minScale: PhotoViewComputedScale.contained,
                                maxScale: PhotoViewComputedScale.covered * 3.0,
                                initialScale: PhotoViewComputedScale.contained,
                                backgroundDecoration: const BoxDecoration(
                                  color: AppColors.cardSurface,
                                ),
                              ),
                            ),
                          )
                        : _buildMasterOverviewMatrix(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMasterOverviewMatrix() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          BentoCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.secondarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.calendarCheck,
                    size: 32,
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Weekly Master Matrix Active',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Digital schedule is synchronized with homeroom faculty. Official signed photo document will appear here when uploaded by administration.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Days summary list
          ..._days.map((day) {
            final periods = _getPeriodsForDay(day.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: BentoCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(day.full, style: AppTypography.titleSmall),
                        Text(
                          '${periods.length} Periods',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: periods.map((p) {
                        final (bg, fg) = AppColors.getSubjectColors(p.subject);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'P${p.periodNumber}: ${p.subject}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: fg,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<TimetablePeriod> _getPeriodsForDay(String day) {
    switch (day) {
      case 'Mon':
        return const [
          TimetablePeriod(
            periodNumber: 1,
            time: '08:00 - 08:45 AM',
            subject: 'Mathematics',
            teacher: 'Mr. R. Sharma',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 2,
            time: '08:45 - 09:30 AM',
            subject: 'English Literature',
            teacher: 'Mrs. P. Verma',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 3,
            time: '09:30 - 10:15 AM',
            subject: 'Science',
            teacher: 'Dr. A. Gupta',
            room: 'Physics Lab',
          ),
          TimetablePeriod(
            periodNumber: 4,
            time: '10:15 - 11:00 AM',
            subject: 'Hindi',
            teacher: 'Ms. S. Pandey',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 5,
            time: '11:40 - 12:25 PM',
            subject: 'Social Science',
            teacher: 'Mr. K. Joshi',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 6,
            time: '12:25 - 01:10 PM',
            subject: 'Computer Science',
            teacher: 'Mrs. N. Sen',
            room: 'IT Lab',
          ),
          TimetablePeriod(
            periodNumber: 7,
            time: '01:10 - 01:50 PM',
            subject: 'Physical Education',
            teacher: 'Coach Rawat',
            room: 'Ground',
          ),
        ];
      case 'Tue':
        return const [
          TimetablePeriod(
            periodNumber: 1,
            time: '08:00 - 08:45 AM',
            subject: 'Science',
            teacher: 'Dr. A. Gupta',
            room: 'Chem Lab',
          ),
          TimetablePeriod(
            periodNumber: 2,
            time: '08:45 - 09:30 AM',
            subject: 'Mathematics',
            teacher: 'Mr. R. Sharma',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 3,
            time: '09:30 - 10:15 AM',
            subject: 'Social Science',
            teacher: 'Mr. K. Joshi',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 4,
            time: '10:15 - 11:00 AM',
            subject: 'English',
            teacher: 'Mrs. P. Verma',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 5,
            time: '11:40 - 12:25 PM',
            subject: 'Hindi',
            teacher: 'Ms. S. Pandey',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 6,
            time: '12:25 - 01:10 PM',
            subject: 'Mathematics Tutorial',
            teacher: 'Mr. R. Sharma',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 7,
            time: '01:10 - 01:50 PM',
            subject: 'Arts & Music',
            teacher: 'Ms. Ananya',
            room: 'Art Studio',
          ),
        ];
      case 'Wed':
        return const [
          TimetablePeriod(
            periodNumber: 1,
            time: '08:00 - 08:45 AM',
            subject: 'English Literature',
            teacher: 'Mrs. P. Verma',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 2,
            time: '08:45 - 09:30 AM',
            subject: 'Science',
            teacher: 'Dr. A. Gupta',
            room: 'Bio Lab',
          ),
          TimetablePeriod(
            periodNumber: 3,
            time: '09:30 - 10:15 AM',
            subject: 'Mathematics',
            teacher: 'Mr. R. Sharma',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 4,
            time: '10:15 - 11:00 AM',
            subject: 'Computer Science',
            teacher: 'Mrs. N. Sen',
            room: 'IT Lab',
          ),
          TimetablePeriod(
            periodNumber: 5,
            time: '11:40 - 12:25 PM',
            subject: 'Social Science',
            teacher: 'Mr. K. Joshi',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 6,
            time: '12:25 - 01:10 PM',
            subject: 'Hindi',
            teacher: 'Ms. S. Pandey',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 7,
            time: '01:10 - 01:50 PM',
            subject: 'Library & Reading',
            teacher: 'Mrs. Rita',
            room: 'Library',
          ),
        ];
      case 'Thu':
        return const [
          TimetablePeriod(
            periodNumber: 1,
            time: '08:00 - 08:45 AM',
            subject: 'Mathematics',
            teacher: 'Mr. R. Sharma',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 2,
            time: '08:45 - 09:30 AM',
            subject: 'Science',
            teacher: 'Dr. A. Gupta',
            room: 'Physics Lab',
          ),
          TimetablePeriod(
            periodNumber: 3,
            time: '09:30 - 10:15 AM',
            subject: 'Social Science',
            teacher: 'Mr. K. Joshi',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 4,
            time: '10:15 - 11:00 AM',
            subject: 'English',
            teacher: 'Mrs. P. Verma',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 5,
            time: '11:40 - 12:25 PM',
            subject: 'Hindi',
            teacher: 'Ms. S. Pandey',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 6,
            time: '12:25 - 01:10 PM',
            subject: 'Science Practical',
            teacher: 'Dr. A. Gupta',
            room: 'Lab 2',
          ),
          TimetablePeriod(
            periodNumber: 7,
            time: '01:10 - 01:50 PM',
            subject: 'Yoga & Wellness',
            teacher: 'Coach Rawat',
            room: 'Ground',
          ),
        ];
      case 'Fri':
        return const [
          TimetablePeriod(
            periodNumber: 1,
            time: '08:00 - 08:45 AM',
            subject: 'Science',
            teacher: 'Dr. A. Gupta',
            room: 'Physics Lab',
          ),
          TimetablePeriod(
            periodNumber: 2,
            time: '08:45 - 09:30 AM',
            subject: 'Mathematics',
            teacher: 'Mr. R. Sharma',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 3,
            time: '09:30 - 10:15 AM',
            subject: 'English',
            teacher: 'Mrs. P. Verma',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 4,
            time: '10:15 - 11:00 AM',
            subject: 'Social Science',
            teacher: 'Mr. K. Joshi',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 5,
            time: '11:40 - 12:25 PM',
            subject: 'Computer Science',
            teacher: 'Mrs. N. Sen',
            room: 'IT Lab',
          ),
          TimetablePeriod(
            periodNumber: 6,
            time: '12:25 - 01:10 PM',
            subject: 'Hindi',
            teacher: 'Ms. S. Pandey',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 7,
            time: '01:10 - 01:50 PM',
            subject: 'Club Activities',
            teacher: 'Activity Staff',
            room: 'Hall',
          ),
        ];
      case 'Sat':
      default:
        return const [
          TimetablePeriod(
            periodNumber: 1,
            time: '08:00 - 08:45 AM',
            subject: 'Mathematics Doubt Clearing',
            teacher: 'Mr. R. Sharma',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 2,
            time: '08:45 - 09:30 AM',
            subject: 'Science Quiz & Project',
            teacher: 'Dr. A. Gupta',
            room: 'Lab 2',
          ),
          TimetablePeriod(
            periodNumber: 3,
            time: '09:30 - 10:15 AM',
            subject: 'English Debate & Quiz',
            teacher: 'Mrs. P. Verma',
            room: 'Room 204',
          ),
          TimetablePeriod(
            periodNumber: 4,
            time: '10:15 - 11:00 AM',
            subject: 'House Assembly & Sports',
            teacher: 'House Masters',
            room: 'School Ground',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final periods = _getPeriodsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Text(
          _className != null ? '$_className Timetable' : 'Class Timetable',
          style: AppTypography.titleLarge,
        ),
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
          // Master Timetable Modal CTA
          IconButton(
            icon: const Icon(LucideIcons.calendarRange, size: 20),
            tooltip: 'Master Timetable',
            onPressed: _showMasterTimetableModal,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.brandPrimary,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Horizontal Floating Day Pills (Mon-Sat)
                  _buildFloatingDayPills(),

                  const SizedBox(height: 12),

                  // Master Timetable Quick Strip
                  _buildMasterTimetableQuickBar(),

                  const SizedBox(height: 8),

                  // Period Timeline List
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: periods.length > 4 ? periods.length + 1 : periods.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        // Insert Lunch Break separator after period 4
                        if (periods.length > 4 && index == 4) {
                          return _buildLunchBreakSeparator();
                        }

                        final periodIndex =
                            (periods.length > 4 && index > 4) ? index - 1 : index;
                        final period = periods[periodIndex];
                        return _buildPeriodTimelineCard(period);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFloatingDayPills() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = _selectedDay == day.key;

          return TactileFeedback(
            onTap: () {
              setState(() => _selectedDay = day.key);
            },
            child: AnimatedContainer(
              duration: AppMotion.durationFast,
              curve: AppMotion.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandPrimary
                    : AppColors.cardSurface,
                borderRadius: BorderRadius.circular(24),
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
                  day.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
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

  Widget _buildMasterTimetableQuickBar() {
    final currentDayFull =
        _days.firstWhere((d) => d.key == _selectedDay, orElse: () => _days.first).full;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.clock,
                size: 15,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                '$currentDayFull Schedule',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          TactileFeedback(
            onTap: _showMasterTimetableModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.sheet,
                    size: 13,
                    color: AppColors.inkSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Master Timetable',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTimelineCard(TimetablePeriod period) {
    final (bg, fg) = AppColors.getSubjectColors(period.subject);

    return BentoCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Number Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Center(
              child: Text(
                '${period.periodNumber}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Period Info
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
                        period.subject,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ),
                    Text(
                      period.time,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.user,
                      size: 13,
                      color: AppColors.inkMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      period.teacher,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      LucideIcons.mapPin,
                      size: 13,
                      color: AppColors.inkMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      period.room,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.inkSecondary,
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

  Widget _buildLunchBreakSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.warningBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.utensils,
              color: AppColors.warning,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lunch Break & Recess',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                  ),
                ),
                Text(
                  'Cafeteria & Ground • 40 Mins',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '11:00 - 11:40 AM',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
