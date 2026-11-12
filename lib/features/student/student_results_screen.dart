import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/config/app_config.dart';
import '../../core/models/exam_result.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/tactile_feedback.dart';

class StudentResultsScreen extends ConsumerStatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  ConsumerState<StudentResultsScreen> createState() =>
      _StudentResultsScreenState();
}

class _StudentResultsScreenState extends ConsumerState<StudentResultsScreen> {
  late ConfettiController _confettiController;
  String _selectedExam = 'Half Yearly Examination';
  List<ExamResult> _results = [];
  ExamStudentSummary? _summary;
  bool _isLoading = true;

  final List<String> _exams = const [
    'Unit Test 1',
    'Half Yearly Examination',
    'Unit Test 2',
    'Annual Finals',
  ];

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadResults();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    final currentStudent = ref.read(currentStudentProvider);
    if (currentStudent == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final studentId = currentStudent.id;

    final repo = ref.read(schoolRepositoryProvider);
    final list = await repo.getStudentExamResults(studentId, _selectedExam);
    final summary = await repo.getStudentExamSummary(studentId, _selectedExam);

    if (!mounted) return;
    setState(() {
      _results = list;
      _summary = summary;
      _isLoading = false;
    });

    // Fire celebratory confetti if student achieved A1 or A2 grade!
    if (summary != null &&
        (summary.overallGrade == 'A1' || summary.overallGrade == 'A2')) {
      _confettiController.play();
    }
  }

  void _onExamChanged(String exam) {
    if (_selectedExam == exam) return;
    setState(() {
      _selectedExam = exam;
      _isLoading = true;
    });
    _loadResults();
  }

  Color _getGradeColor(String? grade) {
    switch (grade?.toUpperCase()) {
      case 'A1':
      case 'A2':
        return AppColors.success;
      case 'B1':
      case 'B2':
        return const Color(0xFF2563EB);
      case 'C1':
      case 'C2':
        return AppColors.warning;
      case 'D':
        return const Color(0xFFD97706);
      case 'E':
      default:
        return AppColors.danger;
    }
  }

  Color _getGradeBgColor(String? grade) {
    switch (grade?.toUpperCase()) {
      case 'A1':
      case 'A2':
        return AppColors.successBg;
      case 'B1':
      case 'B2':
        return const Color(0xFFDBEAFE);
      case 'C1':
      case 'C2':
        return AppColors.warningBg;
      case 'D':
        return const Color(0xFFFEF3C7);
      case 'E':
      default:
        return AppColors.dangerBg;
    }
  }

  Future<void> _generateAndDownloadReportCard() async {
    final currentStudent = ref.read(currentStudentProvider);
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 16),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'STUDENT ACADEMIC PERFORMANCE REPORT',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.indigo900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Official Evaluation Record • Academic Session ${AppConfig.currentAcademicYear}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          'Official Student Progress Report Card • Academic Year ${AppConfig.currentAcademicYear}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.indigo50,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        _selectedExam,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Student Info Grid
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Student Name: ${currentStudent?.fullName ?? "Student"}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Class & Section: Class 8-B'),
                        pw.SizedBox(height: 4),
                        pw.Text('Roll No: ${currentStudent?.rollNo ?? 1}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Admission No: ${currentStudent?.admissionNo ?? "ADM2026101"}',
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Class Teacher: Mr. Ramesh Sharma'),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // Marks Table
              pw.Text(
                'ACADEMIC PERFORMANCE & EVALUATION',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                headers: [
                  'Subject Code',
                  'Subject Name',
                  'Max Marks',
                  'Marks Obtained',
                  'Percentage',
                  'CBSE Grade',
                ],
                data: _results.map((res) {
                  final marksStr = res.status == 'present' && res.marksObtained != null
                      ? res.marksObtained!.toStringAsFixed(0)
                      : res.status == 'medical_leave'
                          ? 'ML'
                          : 'AB';
                  final pctStr = res.marksObtained != null
                      ? '${((res.marksObtained! / res.maxMarks) * 100).toStringAsFixed(1)}%'
                      : '-';
                  return [
                    res.subjectCode,
                    res.subjectName,
                    res.maxMarks.toStringAsFixed(0),
                    marksStr,
                    pctStr,
                    res.grade ?? '-',
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 20),

              // Summary Box
              if (_summary != null)
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Total Marks: ${_summary!.totalObtained.toStringAsFixed(0)} / ${_summary!.totalMax.toStringAsFixed(0)}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Percentage: ${_summary!.percentage.toStringAsFixed(1)}%   |   Overall Grade: ${_summary!.overallGrade}',
                            style: const pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.indigo900,
                            ),
                          ),
                          if (_summary!.rankInClass != null) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Class Rank: #${_summary!.rankInClass} in Class 8-B',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Status: PASS',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                              color: PdfColors.green700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              pw.SizedBox(height: 16),

              // Remarks
              if (_summary?.classTeacherRemarks != null)
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'Class Teacher Remarks: ${_summary!.classTeacherRemarks}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.brown900),
                  ),
                ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Class Teacher',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Examination Controller',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 6),
                      pw.Text('Principal', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Report_Card_${currentStudent?.fullName.replaceAll(' ', '_') ?? "Student"}_$_selectedExam.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Text('Exam Results', style: AppTypography.titleLarge),
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
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Exam Selector Strip
                  _buildExamSelectorStrip(),

                  const SizedBox(height: 18),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_summary == null && _results.isEmpty)
                    _buildEmptyResultsState()
                  else ...[
                    // Overall Summary Bento Card
                    if (_summary != null) _buildSummaryBentoCard(_summary!),

                    const SizedBox(height: 18),

                    // Performance Comparison Graph (fl_chart)
                    _buildPerformanceGraph(),

                    const SizedBox(height: 18),

                    // Subject Breakdown Table
                    _buildSubjectMarksTable(),

                    const SizedBox(height: 20),

                    // 1-Tap Official PDF Report Card Download CTA
                    TactileFeedback(
                      onTap: _generateAndDownloadReportCard,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x334F46E5),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.fileSpreadsheet,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Download Official CBSE Report Card (PDF)',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),

          // Confetti explosion overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 28,
              gravity: 0.25,
              colors: const [
                AppColors.brandPrimary,
                AppColors.coralStreak,
                AppColors.success,
                Color(0xFFF59E0B),
                Color(0xFF2563EB),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResultsState() {
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.secondarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.award,
                size: 40,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No exam has been taken yet.',
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Results and official report cards will appear here once published by school administration.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamSelectorStrip() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _exams.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final exam = _exams[index];
          final isSelected = _selectedExam == exam;

          return TactileFeedback(
            onTap: () => _onExamChanged(exam),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandPrimary : AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.brandPrimary : AppColors.cardBorder,
                ),
              ),
              child: Center(
                child: Text(
                  exam,
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

  Widget _buildSummaryBentoCard(ExamStudentSummary summary) {
    final gradeColor = _getGradeColor(summary.overallGrade);
    final gradeBg = _getGradeBgColor(summary.overallGrade);

    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedExam,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Class 8-B • Academic Year 2026–2027',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              // CBSE Grade Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: gradeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.award, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'Grade ${summary.overallGrade}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: gradeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricPill(
                'Total Marks',
                '${summary.totalObtained.toStringAsFixed(0)} / ${summary.totalMax.toStringAsFixed(0)}',
              ),
              _metricPill(
                'Percentage',
                '${summary.percentage.toStringAsFixed(1)}%',
              ),
              _metricPill(
                'Class Rank',
                summary.rankInClass != null ? 'Rank #${summary.rankInClass}' : 'Top 5%',
              ),
            ],
          ),
          if (summary.classTeacherRemarks != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.messageSquare,
                    size: 16,
                    color: AppColors.inkSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Class Teacher: "${summary.classTeacherRemarks}"',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricPill(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.inkPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceGraph() {
    if (_results.isEmpty) return const SizedBox.shrink();

    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subject Scores vs 100 Max', style: AppTypography.titleMedium),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('Obtained', style: AppTypography.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.inkPrimary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = _results[groupIndex];
                      return BarTooltipItem(
                        '${item.subjectName}: ${rod.toY.toInt()} / 100\nGrade: ${item.grade}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < _results.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _results[idx].subjectCode,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: AppColors.inkMuted,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.cardBorder,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _results.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final marks = item.marksObtained ?? 0.0;

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: marks,
                        color: marks >= 90
                            ? AppColors.success
                            : marks >= 75
                                ? AppColors.brandPrimary
                                : AppColors.warning,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectMarksTable() {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subject Breakdown', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          ..._results.map((item) {
            final gradeColor = _getGradeColor(item.grade);
            final gradeBg = _getGradeBgColor(item.grade);
            final marksStr = item.status == 'present' && item.marksObtained != null
                ? '${item.marksObtained!.toStringAsFixed(0)} / ${item.maxMarks.toStringAsFixed(0)}'
                : item.status == 'medical_leave'
                    ? 'Medical Leave'
                    : 'Absent';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  // Code pill
                  Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        item.subjectCode,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Subject Name & remarks
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subjectName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.subjectRemarks != null)
                          Text(
                            item.subjectRemarks!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Marks
                  Text(
                    marksStr,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Grade Badge
                  Container(
                    width: 38,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: gradeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        item.grade ?? '-',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: gradeColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
