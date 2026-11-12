import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/models/models.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/excel_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/bento_card.dart';
import '../../core/widgets/tactile_feedback.dart';

/// 3-Step Interactive Excel Upload Wizard for Office Staff & Admins:
/// Step 1: Download Pre-filled Template with Class Code Enrolled Students
/// Step 2: Upload / Drag-and-Drop Filled Excel Sheet
/// Step 3: Interactive Validation DataGrid with Cell Error Highlighting, Inline Fixes, and Publish
class ExcelUploadWizard extends ConsumerStatefulWidget {
  const ExcelUploadWizard({super.key});

  @override
  ConsumerState<ExcelUploadWizard> createState() => _ExcelUploadWizardState();
}

class _ExcelUploadWizardState extends ConsumerState<ExcelUploadWizard> {
  final ExcelService _excelService = ExcelService();
  int _currentStep = 0; // 0 = Download, 1 = Upload, 2 = Validate & Publish

  // Step 1 State
  String _selectedExamId = 'exam-half-yearly';
  String _selectedExamName = 'Half Yearly Examination';
  String _selectedClassId = 'class-8b';
  String _selectedClassName = 'Class 8-B';
  double _maxMarks = 100.0;
  bool _isGeneratingTemplate = false;
  Uint8List? _lastGeneratedBytes;

  // Step 2 & 3 State
  String? _uploadedFileName;
  ExcelParseResult? _parsedResult;
  bool _isParsing = false;
  bool _isPublishing = false;

  final List<Map<String, String>> _subjects = [
    {'code': 'MATH', 'name': 'Mathematics'},
    {'code': 'SCI', 'name': 'Science'},
    {'code': 'ENG', 'name': 'English'},
    {'code': 'SST', 'name': 'Social Science'},
    {'code': 'HIN', 'name': 'Hindi'},
  ];

  @override
  void initState() {
    super.initState();
  }

  // ==========================================
  // STEP 1: GENERATE & DOWNLOAD TEMPLATE
  // ==========================================
  Future<void> _generateTemplate() async {
    setState(() => _isGeneratingTemplate = true);
    HapticFeedback.lightImpact();

    final repo = ref.read(schoolRepositoryProvider);
    final students = await repo.getStudentsForClass(_selectedClassId);

    final bytes = _excelService.generateTemplate(
      examId: _selectedExamId,
      examName: _selectedExamName,
      classSectionId: _selectedClassId,
      className: _selectedClassName,
      students: students,
      subjects: _subjects,
      maxMarks: _maxMarks,
    );

    setState(() {
      _lastGeneratedBytes = bytes;
      _isGeneratingTemplate = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.fileSpreadsheet,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pre-filled template generated for $_selectedClassName (${students.length} students enrolled)!',
                style: AppTypography.bodySmall.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.brandPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==========================================
  // STEP 2: UPLOAD OR LOAD DEMO EXCEL FILE
  // ==========================================
  Future<void> _pickExcelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          _processUploadedBytes(file.bytes!, file.name);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File picker error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _loadDemoFilledSheet({bool includeError = true}) {
    HapticFeedback.selectionClick();
    setState(() => _isParsing = true);

    // Create a demo Excel sheet with Indian student results
    final demoTemplate = _excelService.generateTemplate(
      examId: _selectedExamId,
      examName: _selectedExamName,
      classSectionId: _selectedClassId,
      className: _selectedClassName,
      students: const [
        Student(
          id: 'student-aarav',
          rollNo: 1,
          fullName: 'Aarav Sharma',
          admissionNo: 'ADM2026101',
          classSectionId: 'class-8b',
          parentName: 'Rajesh Sharma',
          parentPhone: '+919876540001',
          pinHash: '1234',
        ),
        Student(
          id: 'student-kabir',
          rollNo: 2,
          fullName: 'Kabir Verma',
          admissionNo: 'ADM2026102',
          classSectionId: 'class-8b',
          parentName: 'Sanjay Verma',
          parentPhone: '+919876540002',
          pinHash: '1234',
        ),
        Student(
          id: 'student-ananya',
          rollNo: 3,
          fullName: 'Ananya Gupta',
          admissionNo: 'ADM2026103',
          classSectionId: 'class-8b',
          parentName: 'Meera Gupta',
          parentPhone: '+919876540003',
          pinHash: '1234',
        ),
        Student(
          id: 'student-rohan',
          rollNo: 4,
          fullName: 'Rohan Mehta',
          admissionNo: 'ADM2026104',
          classSectionId: 'class-8b',
          parentName: 'Nitin Mehta',
          parentPhone: '+919876540004',
          pinHash: '1234',
        ),
      ],
      subjects: _subjects,
      maxMarks: _maxMarks,
    );

    // Parse bytes
    final parsed = _excelService.parseExcel(
      demoTemplate,
      expectedExamId: _selectedExamId,
      expectedExamName: _selectedExamName,
      expectedClassSectionId: _selectedClassId,
      defaultMaxMarks: _maxMarks,
    );

    // Populate mock marks with one intentional error for UI demo if requested
    final updatedRows = <ExcelStudentRow>[];
    for (int i = 0; i < parsed.rows.length; i++) {
      final r = parsed.rows[i];
      final marks = <String, ExcelSubjectMark>{};

      if (r.rollNo == 1) {
        // Aarav: High achiever
        marks['MATH'] = ExcelService.validateCell(
            subjectCode: 'MATH', rawValue: '95', maxMarks: _maxMarks);
        marks['SCI'] = ExcelService.validateCell(
            subjectCode: 'SCI', rawValue: '91', maxMarks: _maxMarks);
        marks['ENG'] = ExcelService.validateCell(
            subjectCode: 'ENG', rawValue: '88', maxMarks: _maxMarks);
        marks['SST'] = ExcelService.validateCell(
            subjectCode: 'SST', rawValue: '84', maxMarks: _maxMarks);
        marks['HIN'] = ExcelService.validateCell(
            subjectCode: 'HIN', rawValue: '89', maxMarks: _maxMarks);
      } else if (r.rollNo == 2) {
        // Kabir: Absent in Maths ('AB')
        marks['MATH'] = ExcelService.validateCell(
            subjectCode: 'MATH', rawValue: 'AB', maxMarks: _maxMarks);
        marks['SCI'] = ExcelService.validateCell(
            subjectCode: 'SCI', rawValue: '81', maxMarks: _maxMarks);
        marks['ENG'] = ExcelService.validateCell(
            subjectCode: 'ENG', rawValue: '76', maxMarks: _maxMarks);
        marks['SST'] = ExcelService.validateCell(
            subjectCode: 'SST', rawValue: '72', maxMarks: _maxMarks);
        marks['HIN'] = ExcelService.validateCell(
            subjectCode: 'HIN', rawValue: '79', maxMarks: _maxMarks);
      } else if (r.rollNo == 3) {
        // Ananya: All-rounder
        marks['MATH'] = ExcelService.validateCell(
            subjectCode: 'MATH', rawValue: '98', maxMarks: _maxMarks);
        marks['SCI'] = ExcelService.validateCell(
            subjectCode: 'SCI', rawValue: '96', maxMarks: _maxMarks);
        marks['ENG'] = ExcelService.validateCell(
            subjectCode: 'ENG', rawValue: '92', maxMarks: _maxMarks);
        marks['SST'] = ExcelService.validateCell(
            subjectCode: 'SST', rawValue: '94', maxMarks: _maxMarks);
        marks['HIN'] = ExcelService.validateCell(
            subjectCode: 'HIN', rawValue: '95', maxMarks: _maxMarks);
      } else if (r.rollNo == 4) {
        // Rohan: Has intentional out-of-range mark (105) for validation demo
        final mathRaw = includeError ? '105' : '85';
        marks['MATH'] = ExcelService.validateCell(
            subjectCode: 'MATH', rawValue: mathRaw, maxMarks: _maxMarks);
        marks['SCI'] = ExcelService.validateCell(
            subjectCode: 'SCI', rawValue: '74', maxMarks: _maxMarks);
        marks['ENG'] = ExcelService.validateCell(
            subjectCode: 'ENG', rawValue: 'ML', maxMarks: _maxMarks); // Medical Leave
        marks['SST'] = ExcelService.validateCell(
            subjectCode: 'SST', rawValue: '68', maxMarks: _maxMarks);
        marks['HIN'] = ExcelService.validateCell(
            subjectCode: 'HIN', rawValue: '70', maxMarks: _maxMarks);
      }

      updatedRows.add(r.copyWith(subjectMarks: marks));
    }

    final validatedResult = ExcelParseResult(
      examId: parsed.examId,
      examName: _selectedExamName,
      classSectionId: parsed.classSectionId,
      maxMarks: parsed.maxMarks,
      subjectCodes: parsed.subjectCodes,
      rows: updatedRows,
    );

    setState(() {
      _uploadedFileName = 'Class_8B_HalfYearly_Marks_Filled.xlsx';
      _parsedResult = validatedResult;
      _isParsing = false;
      _currentStep = 2; // Move straight to Step 3 Validation DataGrid
    });
  }

  void _processUploadedBytes(Uint8List bytes, String fileName) {
    setState(() => _isParsing = true);
    final parsed = _excelService.parseExcel(
      bytes,
      expectedExamId: _selectedExamId,
      expectedExamName: _selectedExamName,
      expectedClassSectionId: _selectedClassId,
      defaultMaxMarks: _maxMarks,
    );

    setState(() {
      _uploadedFileName = fileName;
      _parsedResult = parsed;
      _isParsing = false;
      _currentStep = 2; // Advance to Step 3 Validation Grid
    });
  }

  // ==========================================
  // STEP 3: INLINE EDIT & PUBLISH
  // ==========================================
  void _editCell(ExcelStudentRow row, String subjectCode) {
    final mark = row.subjectMarks[subjectCode];
    final controller = TextEditingController(text: mark?.rawValue ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Edit $subjectCode Mark for ${row.studentName}',
            style: AppTypography.titleMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter numeric marks (0 - ${_maxMarks.toInt()}), "AB" for Absent, or "ML" for Medical Leave.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Marks / Status',
                  filled: true,
                  fillColor: AppColors.canvasBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final input = controller.text.trim();
                _updateCellValue(row.rowIndex, subjectCode, input);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update & Validate'),
            ),
          ],
        );
      },
    );
  }

  void _updateCellValue(int rowIndex, String subjectCode, String rawValue) {
    if (_parsedResult == null) return;

    final rows = List<ExcelStudentRow>.from(_parsedResult!.rows);
    final row = rows[rowIndex];

    final updatedMark = ExcelService.validateCell(
      subjectCode: subjectCode,
      rawValue: rawValue,
      maxMarks: _maxMarks,
    );

    final updatedMarks = Map<String, ExcelSubjectMark>.from(row.subjectMarks);
    updatedMarks[subjectCode] = updatedMark;

    final updatedRow = ExcelService.revalidateRow(
      row: row.copyWith(subjectMarks: updatedMarks),
      maxMarks: _maxMarks,
    );

    rows[rowIndex] = updatedRow;

    setState(() {
      _parsedResult = ExcelParseResult(
        examId: _parsedResult!.examId,
        examName: _parsedResult!.examName,
        classSectionId: _parsedResult!.classSectionId,
        maxMarks: _parsedResult!.maxMarks,
        subjectCodes: _parsedResult!.subjectCodes,
        rows: rows,
        fileErrors: _parsedResult!.fileErrors,
      );
    });

    HapticFeedback.lightImpact();
  }

  Future<void> _publishResults() async {
    if (_parsedResult == null) return;

    if (_parsedResult!.errorRowCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot publish: Please fix ${_parsedResult!.errorRowCount} error row(s) highlighted in red.',
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);
    HapticFeedback.heavyImpact();

    final repo = ref.read(schoolRepositoryProvider);
    final students = await repo.getStudentsForClass(_selectedClassId);
    final rollMap = {for (final s in students) s.rollNo: s};

    final examResults = ExcelService.convertToExamResults(
      parsed: _parsedResult!,
      examId: _selectedExamId,
      examName: _selectedExamName,
      classSectionId: _selectedClassId,
      rollToStudentMap: rollMap,
    );

    await repo.publishExamResults(
      examName: _selectedExamName,
      classSectionId: _selectedClassId,
      results: examResults,
    );

    if (!mounted) return;
    setState(() => _isPublishing = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(LucideIcons.checkCircle,
                  color: AppColors.success, size: 28),
              const SizedBox(width: 10),
              Text('Results Published!', style: AppTypography.titleLarge),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Successfully published results for ${examResults.length} subject entries across ${_parsedResult!.totalRows} students in $_selectedClassName.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Students and parents will see their updated marks, CBSE A1-E grades, and can download their official CBSE PDF Report Card.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.inkSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _currentStep = 0;
                  _parsedResult = null;
                  _uploadedFileName = null;
                });
              },
              child: const Text('Back to Wizard'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.studentResults);
              },
              icon: const Icon(LucideIcons.award, size: 16),
              label: const Text('View Student Results'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: AppColors.canvasBackground,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Excel Results Wizard', style: AppTypography.titleLarge),
            Text(
              '3-Step Linear / Airtable Style Exam Marks Workflow',
              style:
                  AppTypography.caption.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw,
                size: 20, color: AppColors.inkSecondary),
            tooltip: 'Reset Wizard',
            onPressed: () {
              setState(() {
                _currentStep = 0;
                _parsedResult = null;
                _uploadedFileName = null;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 3-Step Wizard Navigation Stepper
          _buildStepBreadcrumbs(),

          // Active Step View
          Expanded(
            child: _buildActiveStepContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBreadcrumbs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _stepChip(0, 'Step 1', 'Download Template', LucideIcons.download),
          _stepDivider(),
          _stepChip(1, 'Step 2', 'Upload Excel', LucideIcons.uploadCloud),
          _stepDivider(),
          _stepChip(2, 'Step 3', 'Validate & Publish', LucideIcons.checkSquare),
        ],
      ),
    );
  }

  Widget _stepChip(
      int index, String stepNo, String title, IconData icon) {
    final isActive = _currentStep == index;
    final isDone = _currentStep > index;

    Color bg = AppColors.canvasBackground;
    Color border = AppColors.cardBorder;
    Color textColor = AppColors.inkMuted;
    Color iconColor = AppColors.inkMuted;

    if (isActive) {
      bg = AppColors.brandPrimaryLight;
      border = AppColors.brandPrimary;
      textColor = AppColors.brandPrimary;
      iconColor = AppColors.brandPrimary;
    } else if (isDone) {
      bg = const Color(0xFFD1FAE5);
      border = AppColors.success;
      textColor = AppColors.success;
      iconColor = AppColors.success;
    }

    return Expanded(
      child: TactileFeedback(
        onTap: () {
          if (index <= _currentStep || _parsedResult != null) {
            setState(() => _currentStep = index);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isDone ? LucideIcons.check : icon,
                      size: 14, color: iconColor),
                  const SizedBox(width: 4),
                  Text(
                    stepNo,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.inkPrimary : AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepDivider() {
    return Container(
      width: 16,
      height: 1.5,
      color: AppColors.cardBorder,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildActiveStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Download();
      case 1:
        return _buildStep2Upload();
      case 2:
      default:
        return _buildStep3ValidationDataGrid();
    }
  }

  // ==========================================
  // VIEW: STEP 1
  // ==========================================
  Widget _buildStep1Download() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
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
                    child: const Icon(LucideIcons.download,
                        color: AppColors.brandPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Step 1: Download Pre-filled Template',
                            style: AppTypography.titleLarge),
                        Text(
                          'Generates an .xlsx file with enrolled Class Code students pre-populated in Roll No order.',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.inkSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Exam Selection
              Text('Select Examination', style: AppTypography.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedExamId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.canvasBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'exam-ut1',
                    child: Text('Unit Test 1 (Max: 50)'),
                  ),
                  DropdownMenuItem(
                    value: 'exam-half-yearly',
                    child: Text('Half Yearly Examination (Max: 100)'),
                  ),
                  DropdownMenuItem(
                    value: 'exam-ut2',
                    child: Text('Unit Test 2 (Max: 50)'),
                  ),
                  DropdownMenuItem(
                    value: 'exam-finals',
                    child: Text('Annual Final Examination (Max: 100)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedExamId = val;
                      if (val.contains('ut')) {
                        _maxMarks = 50.0;
                      } else {
                        _maxMarks = 100.0;
                      }
                      if (val == 'exam-ut1') {
                        _selectedExamName = 'Unit Test 1';
                      } else if (val == 'exam-half-yearly') {
                        _selectedExamName = 'Half Yearly Examination';
                      } else if (val == 'exam-ut2') {
                        _selectedExamName = 'Unit Test 2';
                      } else {
                        _selectedExamName = 'Annual Final Examination';
                      }
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Class Section Selection
              Text('Select Class & Section', style: AppTypography.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedClassId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.canvasBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'class-8b',
                    child: Text('Class 8-B (Class Teacher: Ramesh Sharma)'),
                  ),
                  DropdownMenuItem(
                    value: 'class-6a',
                    child: Text('Class 6-A (Class Teacher: Sunita Rao)'),
                  ),
                  DropdownMenuItem(
                    value: 'class-7c',
                    child: Text('Class 7-C (Class Teacher: Vikram Singh)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedClassId = val;
                      if (val == 'class-8b') {
                        _selectedClassName = 'Class 8-B';
                      } else if (val == 'class-6a') {
                        _selectedClassName = 'Class 6-A';
                      } else {
                        _selectedClassName = 'Class 7-C';
                      }
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              // Pre-populated Columns Preview Pill
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvasBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto-generated Columns in .xlsx:',
                        style: AppTypography.caption
                            .copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tag('Roll_No', isSystem: true),
                        _tag('Student_Name', isSystem: true),
                        _tag('Admission_No', isSystem: true),
                        _tag('ENG (${_maxMarks.toInt()})'),
                        _tag('MATH (${_maxMarks.toInt()})'),
                        _tag('SCI (${_maxMarks.toInt()})'),
                        _tag('SST (${_maxMarks.toInt()})'),
                        _tag('HIN (${_maxMarks.toInt()})'),
                        _tag('Class_Teacher_Remarks', isSystem: true),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Download Button
              TactileFeedback(
                onTap: _isGeneratingTemplate ? null : _generateTemplate,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isGeneratingTemplate
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.fileSpreadsheet,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Generate & Download .xlsx',
                                style: AppTypography.button
                                    .copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              if (_lastGeneratedBytes != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _currentStep = 1),
                    icon: const Icon(LucideIcons.arrowRight, size: 16),
                    label: const Text('Proceed to Step 2: Upload Excel'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _tag(String label, {bool isSystem = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSystem ? AppColors.cardSurface : AppColors.brandPrimaryLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSystem ? AppColors.cardBorder : AppColors.brandPrimary,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSystem ? AppColors.inkSecondary : AppColors.brandPrimary,
        ),
      ),
    );
  }

  // ==========================================
  // VIEW: STEP 2
  // ==========================================
  Widget _buildStep2Upload() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        BentoCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Drag and drop zone
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 36),
                decoration: BoxDecoration(
                  color: AppColors.canvasBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.brandPrimary,
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.brandPrimaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.uploadCloud,
                            color: AppColors.brandPrimary, size: 28),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Drag & Drop Filled .xlsx File Here',
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supports numbers, "AB" for Absent, and "ML" for Medical Leave',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 18),
                    if (_isParsing)
                      const CircularProgressIndicator(color: AppColors.brandPrimary)
                    else
                      ElevatedButton.icon(
                        onPressed: _pickExcelFile,
                        icon: const Icon(LucideIcons.folderOpen, size: 16),
                        label: const Text('Browse Files'),
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
              ),

              const SizedBox(height: 20),

              // OR Demo Preset Buttons
              Row(
                children: [
                  const Expanded(
                      child: Divider(color: AppColors.cardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR TEST WITH 1-CLICK DEMO DATA',
                        style: AppTypography.caption.copyWith(fontSize: 10)),
                  ),
                  const Expanded(
                      child: Divider(color: AppColors.cardBorder)),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _loadDemoFilledSheet(includeError: true),
                      icon: const Icon(LucideIcons.alertTriangle,
                          color: AppColors.warning, size: 16),
                      label: const Text(
                        'Load Demo (with 1 Error)',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.warning),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _loadDemoFilledSheet(includeError: false),
                      icon: const Icon(LucideIcons.checkCheck,
                          color: AppColors.success, size: 16),
                      label: const Text(
                        'Load All Valid Demo',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.success),
                      ),
                    ),
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
  // VIEW: STEP 3: INTERACTIVE VALIDATION DATAGRID
  // ==========================================
  Widget _buildStep3ValidationDataGrid() {
    if (_parsedResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.fileSpreadsheet,
                size: 40, color: AppColors.inkMuted),
            const SizedBox(height: 12),
            Text('No parsed sheet data available.',
                style: AppTypography.bodyMedium),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text('Back to Upload'),
            ),
          ],
        ),
      );
    }

    final total = _parsedResult!.totalRows;
    final valid = _parsedResult!.validRowCount;
    final errors = _parsedResult!.errorRowCount;

    return Column(
      children: [
        if (_uploadedFileName != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                const Icon(LucideIcons.fileSpreadsheet,
                    size: 14, color: AppColors.brandPrimary),
                const SizedBox(width: 6),
                Text('Loaded File: $_uploadedFileName',
                    style: AppTypography.caption),
              ],
            ),
          ),
        // Summary Counters & Actions Bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              // Total Counter
              _counterChip('Total Students', total.toString(),
                  AppColors.inkPrimary, AppColors.canvasBackground),
              const SizedBox(width: 8),
              // Valid Counter
              _counterChip('Valid Rows', valid.toString(),
                  AppColors.success, const Color(0xFFD1FAE5)),
              const SizedBox(width: 8),
              // Errors Counter
              _counterChip(
                  'Errors',
                  errors.toString(),
                  errors > 0 ? AppColors.danger : AppColors.inkMuted,
                  errors > 0 ? const Color(0xFFFEE2E2) : AppColors.canvasBackground),

              const Spacer(),

              // Publish Button
              TactileFeedback(
                onTap: _isPublishing || errors > 0 ? null : _publishResults,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: errors == 0
                        ? AppColors.brandPrimary
                        : AppColors.inkMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.send,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Publish Results',
                        style: AppTypography.button
                            .copyWith(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (errors > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.alertCircle,
                    color: AppColors.danger, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Validation alert: $errors cell error(s) flagged in red. Tap any cell to edit & fix inline!',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Interactive DataGrid
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 780,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                itemCount: _parsedResult!.rows.length + 1, // +1 for header
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildGridHeader();
                  }
                  final row = _parsedResult!.rows[index - 1];
                  return _buildDataGridRow(row);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _counterChip(
      String label, String count, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            count,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B), // Deep Slate Navy
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _headerCell('Roll #', width: 60),
          _headerCell('Student Name', width: 140),
          _headerCell('MATH', width: 85),
          _headerCell('SCI', width: 85),
          _headerCell('ENG', width: 85),
          _headerCell('SST', width: 85),
          _headerCell('HIN', width: 85),
          _headerCell('Status', width: 85),
        ],
      ),
    );
  }

  Widget _headerCell(String title, {required double width}) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDataGridRow(ExcelStudentRow row) {
    final hasRowError = !row.isValid;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasRowError
            ? const Color(0xFFFFF1F2) // Light red tint
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasRowError
              ? AppColors.danger.withValues(alpha: 0.5)
              : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          // Roll No
          SizedBox(
            width: 60,
            child: Text(
              row.rollNo.toString(),
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.inkPrimary,
              ),
            ),
          ),

          // Student Name
          SizedBox(
            width: 140,
            child: Text(
              row.studentName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSmall.copyWith(fontSize: 12),
            ),
          ),

          // Subjects
          _buildSubjectCell(row, 'MATH'),
          _buildSubjectCell(row, 'SCI'),
          _buildSubjectCell(row, 'ENG'),
          _buildSubjectCell(row, 'SST'),
          _buildSubjectCell(row, 'HIN'),

          // Row status
          SizedBox(
            width: 85,
            child: hasRowError
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ERROR',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'VALID',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCell(ExcelStudentRow row, String subjectCode) {
    final mark = row.subjectMarks[subjectCode];
    final isError = mark?.hasError ?? false;
    final isAbsent = mark?.status == 'absent';
    final isMedical = mark?.status == 'medical_leave';

    Color cellBg = AppColors.canvasBackground;
    Color cellBorder = AppColors.cardBorder;
    Color textColor = AppColors.inkPrimary;

    if (isError) {
      cellBg = const Color(0xFFFEE2E2);
      cellBorder = AppColors.danger;
      textColor = AppColors.danger;
    } else if (isAbsent) {
      cellBg = const Color(0xFFFEE2E2);
      cellBorder = AppColors.danger.withValues(alpha: 0.3);
      textColor = AppColors.danger;
    } else if (isMedical) {
      cellBg = const Color(0xFFFEF3C7);
      cellBorder = AppColors.warning;
      textColor = AppColors.warning;
    }

    final displayText = isAbsent
        ? 'AB'
        : (isMedical
            ? 'ML'
            : (mark?.marks != null
                ? mark!.marks!.toStringAsFixed(0)
                : mark?.rawValue ?? '-'));

    return SizedBox(
      width: 85,
      child: Tooltip(
        message: isError
            ? mark!.error!
            : '$subjectCode: $displayText • Grade: ${mark?.grade ?? '-'} (Tap to edit)',
        child: TactileFeedback(
          onTap: () => _editCell(row, subjectCode),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: cellBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cellBorder, width: isError ? 1.5 : 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayText,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (!isError && mark?.grade != null && mark!.grade != '-')
                  Text(
                    mark.grade,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkMuted,
                    ),
                  ),
                if (isError)
                  const Icon(LucideIcons.alertCircle,
                      size: 12, color: AppColors.danger),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
