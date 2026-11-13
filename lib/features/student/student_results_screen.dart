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
import '../../core/models/models.dart';
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

  static (Color fg, Color bg, String title, String point) getCbseTier(
      String? grade) {
    switch (grade?.toUpperCase()) {
      case 'A1':
        return (
          const Color(0xFF10B981),
          const Color(0xFFD1FAE5),
          'Outstanding',
          '10.0'
        );
      case 'A2':
        return (
          const Color(0xFF059669),
          const Color(0xFFECFDF5),
          'Excellent',
          '9.0'
        );
      case 'B1':
        return (
          const Color(0xFF4F46E5),
          const Color(0xFFEEF2FF),
          'Very Good',
          '8.0'
        );
      case 'B2':
        return (
          const Color(0xFF2563EB),
          const Color(0xFFDBEAFE),
          'Good',
          '7.0'
        );
      case 'C1':
        return (
          const Color(0xFFF59E0B),
          const Color(0xFFFEF3C7),
          'Fair',
          '6.0'
        );
      case 'C2':
        return (
          const Color(0xFFD97706),
          const Color(0xFFFFFBEB),
          'Average',
          '5.0'
        );
      case 'D':
        return (
          const Color(0xFFEA580C),
          const Color(0xFFFFEDD5),
          'Marginal Pass',
          '4.0'
        );
      case 'E':
      default:
        return (
          const Color(0xFFEF4444),
          const Color(0xFFFEE2E2),
          'Needs Improvement',
          '0.0'
        );
    }
  }

  Future<void> _generateAndDownloadReportCard() async {
    final currentStudent = ref.read(currentStudentProvider);
    final repo = ref.read(schoolRepositoryProvider);
    ClassSection? classSection;
    if (currentStudent?.classSectionId.isNotEmpty == true) {
      try {
        classSection = await repo.getClassSectionById(currentStudent!.classSectionId);
      } catch (_) {}
    }
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
                        pw.Text('Class & Section: ${classSection?.displayName ?? "Class"}'),
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
                        pw.Text('Class Teacher: ${classSection?.classTeacherName ?? "Class Teacher"}'),
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
                              'Class Rank: #${_summary!.rankInClass}${classSection != null ? " in ${classSection.displayName}" : ""}',
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

                    // Report Card Actions: Preview + Download
                    Row(
                      children: [
                        Expanded(
                          child: TactileFeedback(
                            onTap: () => _showReportCardPreviewModal(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.brandPrimary,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.fileSearch,
                                    color: AppColors.brandPrimary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Preview Report Card',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: AppColors.brandPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

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
    final currentStudent = ref.watch(currentStudentProvider);

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
                    '${currentStudent?.fullName != null ? "${currentStudent!.fullName} • " : ""}Academic Session ${AppConfig.currentAcademicYear}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              // CBSE Grade Badge
              CbseGradeBadge(
                grade: summary.overallGrade,
                isLarge: true,
                showDescription: true,
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
                  CbseGradeBadge(grade: item.grade),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showReportCardPreviewModal(BuildContext context) {
    final currentStudent = ref.read(currentStudentProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.96,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Report Card Preview',
                              style: AppTypography.headlineSmall),
                          const SizedBox(height: 2),
                          Text(
                            'CBSE Evaluation Record • $_selectedExam',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BentoCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // School Header
                                Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: AppColors.brandPrimaryLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          LucideIcons.graduationCap,
                                          color: AppColors.brandPrimary,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'CAMPUSVIBE ACADEMY',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: AppColors.brandPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Affiliated with CBSE New Delhi • School Code #20412',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.inkSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondarySurface,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'STUDENT PROGRESS REPORT CARD • $_selectedExam',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.inkPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(
                                    height: 1, color: AppColors.cardBorder),
                                const SizedBox(height: 14),

                                // Student Information
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Student Name',
                                            style: AppTypography.bodySmall),
                                        Text(
                                          currentStudent?.fullName ?? 'Student',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text('Roll Number',
                                            style: AppTypography.bodySmall),
                                        Text(
                                          '${currentStudent?.rollNo ?? 1}',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Academic Year',
                                            style: AppTypography.bodySmall),
                                        Text(
                                          AppConfig.currentAcademicYear,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text('Admission No',
                                            style: AppTypography.bodySmall),
                                        Text(
                                          currentStudent?.admissionNo ??
                                              'ADM2026101',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(
                                    height: 1, color: AppColors.cardBorder),
                                const SizedBox(height: 14),

                                // Subject rows
                                Text(
                                  'ACADEMIC PERFORMANCE (CBSE 8-TIER)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ..._results.map((res) {
                                  final marksStr = res.status == 'present' &&
                                          res.marksObtained != null
                                      ? '${res.marksObtained!.toStringAsFixed(0)} / ${res.maxMarks.toStringAsFixed(0)}'
                                      : res.status == 'medical_leave'
                                          ? 'ML'
                                          : 'AB';
                                  final pctStr = res.marksObtained != null
                                      ? '${((res.marksObtained! / res.maxMarks) * 100).toStringAsFixed(0)}%'
                                      : '-';

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                res.subjectName,
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                res.subjectCode,
                                                style:
                                                    GoogleFonts.jetBrainsMono(
                                                  fontSize: 10,
                                                  color: AppColors.inkMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          marksStr,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          pctStr,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 11,
                                            color: AppColors.inkSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        CbseGradeBadge(grade: res.grade),
                                      ],
                                    ),
                                  );
                                }),

                                if (_summary != null) ...[
                                  const SizedBox(height: 14),
                                  const Divider(
                                      height: 1, color: AppColors.cardBorder),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total: ${_summary!.totalObtained.toStringAsFixed(0)} / ${_summary!.totalMax.toStringAsFixed(0)}',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            'Percentage: ${_summary!.percentage.toStringAsFixed(1)}%',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 11,
                                              color: AppColors.inkSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      CbseGradeBadge(
                                        grade: _summary!.overallGrade,
                                        isLarge: true,
                                        showDescription: true,
                                      ),
                                    ],
                                  ),
                                ],

                                if (_summary?.classTeacherRemarks != null) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondarySurface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(LucideIcons.messageSquare,
                                            size: 14,
                                            color: AppColors.inkSecondary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Teacher Remarks: "${_summary!.classTeacherRemarks}"',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Print & Download CTA
                          TactileFeedback(
                            onTap: () {
                              Navigator.of(context).pop();
                              _generateAndDownloadReportCard();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                                  const Icon(LucideIcons.printer,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Print / Save Official PDF',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
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
}

/// Dedicated CBSE 8-Tier Grade Badge supporting official performance tiers.
class CbseGradeBadge extends StatelessWidget {
  final String? grade;
  final bool isLarge;
  final bool showDescription;

  const CbseGradeBadge({
    super.key,
    required this.grade,
    this.isLarge = false,
    this.showDescription = false,
  });

  @override
  Widget build(BuildContext context) {
    final (fg, bg, desc, gp) = _StudentResultsScreenState.getCbseTier(grade);

    if (isLarge) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fg.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: fg.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.award, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              'Grade ${grade ?? "-"}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
            if (showDescription) ...[
              const SizedBox(width: 6),
              Text(
                '• $desc ($gp GP)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Center(
        child: Text(
          grade ?? '-',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      ),
    );
  }
}
