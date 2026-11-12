import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/models/attendance.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';

class StudentAttendanceCalendarScreen extends ConsumerStatefulWidget {
  const StudentAttendanceCalendarScreen({super.key});

  @override
  ConsumerState<StudentAttendanceCalendarScreen> createState() =>
      _StudentAttendanceCalendarScreenState();
}

class _StudentAttendanceCalendarScreenState
    extends ConsumerState<StudentAttendanceCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Attendance> _studentAttendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final currentStudent = ref.read(currentStudentProvider);
    if (currentStudent == null) {
      setState(() => _isLoading = false);
      return;
    }

    final repo = ref.read(schoolRepositoryProvider);
    final records = await repo.getAttendanceForStudent(currentStudent.id);

    if (!mounted) return;
    setState(() {
      _studentAttendance = records;
      _isLoading = false;
    });
  }

  Attendance? _getAttendanceForDate(DateTime day) {
    for (final record in _studentAttendance) {
      if (record.date.year == day.year &&
          record.date.month == day.month &&
          record.date.day == day.day) {
        return record;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedRecord = _getAttendanceForDate(_selectedDay);

    int totalPresent = 0;
    int totalAbsent = 0;
    int totalLeave = 0;

    for (final rec in _studentAttendance) {
      if (rec.status == AttendanceStatus.present) totalPresent++;
      if (rec.status == AttendanceStatus.absent) totalAbsent++;
      if (rec.status == AttendanceStatus.leave) totalLeave++;
    }

    final totalTracked = totalPresent + totalAbsent + totalLeave;
    final percentage = totalTracked > 0
        ? ((totalPresent / totalTracked) * 100).toStringAsFixed(1)
        : '92.4';

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Text('Monthly Attendance', style: AppTypography.titleLarge),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Stats Bento
                    _buildSummaryStats(percentage, totalPresent, totalAbsent, totalLeave),

                    const SizedBox(height: 18),

                    // Calendar Bento Card
                    _buildCalendarCard(),

                    const SizedBox(height: 16),

                    // Selected Day Detail Card
                    _buildSelectedDayDetail(selectedRecord),

                    const SizedBox(height: 16),

                    // Legend Strip
                    _buildLegendStrip(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryStats(
    String percentage,
    int present,
    int absent,
    int leave,
  ) {
    final isGood = double.tryParse(percentage) != null &&
        double.parse(percentage) >= 75.0;

    return BentoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overall Attendance', style: AppTypography.bodySmall),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$percentage%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isGood ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isGood ? AppColors.successBg : AppColors.warningBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isGood ? 'CBSE Compliant (≥75%)' : 'Short Attendance',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isGood ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isGood ? AppColors.successBg : AppColors.warningBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGood ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                  color: isGood ? AppColors.success : AppColors.warning,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Present', '$present Days', AppColors.success),
              _statItem('Absent', '$absent Days', AppColors.danger),
              _statItem('Leave', '$leave Days', AppColors.warning),
              _statItem('Weekends', 'Sundays', AppColors.brandPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }

  Widget _buildCalendarCard() {
    return BentoCard(
      padding: const EdgeInsets.all(14),
      child: TableCalendar(
        firstDay: DateTime.utc(2026, 1, 1),
        lastDay: DateTime.utc(2027, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
          leftChevronIcon: const Icon(LucideIcons.chevronLeft, size: 20),
          rightChevronIcon: const Icon(LucideIcons.chevronRight, size: 20),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: AppColors.inkSecondary,
          ),
          weekendStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: AppColors.danger,
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: AppColors.brandPrimaryLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.brandPrimary, width: 1.5),
          ),
          todayTextStyle: GoogleFonts.inter(
            color: AppColors.brandPrimary,
            fontWeight: FontWeight.w700,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.brandPrimary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final record = _getAttendanceForDate(date);
            if (date.weekday == DateTime.sunday) {
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF60A5FA), // Holiday blue
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }

            if (record != null) {
              Color markerColor = AppColors.success;
              if (record.status == AttendanceStatus.absent) {
                markerColor = AppColors.danger;
              } else if (record.status == AttendanceStatus.leave) {
                markerColor = AppColors.warning;
              }

              return Positioned(
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildSelectedDayDetail(Attendance? record) {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay);
    final isSunday = _selectedDay.weekday == DateTime.sunday;

    String statusText = 'Working Day (Not Marked)';
    Color statusColor = AppColors.inkMuted;
    Color statusBg = AppColors.secondarySurface;
    IconData statusIcon = LucideIcons.circle;

    if (isSunday) {
      statusText = 'Sunday (Weekly Holiday)';
      statusColor = const Color(0xFF2563EB);
      statusBg = const Color(0xFFDBEAFE);
      statusIcon = LucideIcons.sun;
    } else if (record != null) {
      if (record.status == AttendanceStatus.present) {
        statusText = 'Present in School';
        statusColor = AppColors.success;
        statusBg = AppColors.successBg;
        statusIcon = LucideIcons.checkCircle2;
      } else if (record.status == AttendanceStatus.absent) {
        statusText = 'Absent';
        statusColor = AppColors.danger;
        statusBg = AppColors.dangerBg;
        statusIcon = LucideIcons.xCircle;
      } else if (record.status == AttendanceStatus.leave) {
        statusText = 'Approved Medical Leave';
        statusColor = AppColors.warning;
        statusBg = AppColors.warningBg;
        statusIcon = LucideIcons.clock;
      }
    }

    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusBg,
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (record != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Homeroom roll call by Mr. Ramesh Sharma',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendStrip() {
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem(AppColors.success, 'Present'),
          _legendItem(AppColors.danger, 'Absent'),
          _legendItem(AppColors.warning, 'Leave'),
          _legendItem(const Color(0xFF60A5FA), 'Holiday'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }
}
