import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../models/student.dart';
import '../models/exam_result.dart';

/// Subject mark representation within parsed Excel row
class ExcelSubjectMark {
  final String subjectCode;
  final String subjectName;
  final double? marks;
  final double maxMarks;
  final String status; // 'present', 'absent', 'medical_leave'
  final String grade; // 'A1'..'E' or '-'
  final String? error;
  final String rawValue;

  const ExcelSubjectMark({
    required this.subjectCode,
    required this.subjectName,
    this.marks,
    this.maxMarks = 100.0,
    required this.status,
    required this.grade,
    this.error,
    required this.rawValue,
  });

  bool get hasError => error != null;

  ExcelSubjectMark copyWith({
    String? subjectCode,
    String? subjectName,
    double? marks,
    double? maxMarks,
    String? status,
    String? grade,
    String? error,
    String? rawValue,
    bool clearError = false,
  }) {
    return ExcelSubjectMark(
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      marks: marks ?? this.marks,
      maxMarks: maxMarks ?? this.maxMarks,
      status: status ?? this.status,
      grade: grade ?? this.grade,
      error: clearError ? null : (error ?? this.error),
      rawValue: rawValue ?? this.rawValue,
    );
  }
}

/// Single student row in the interactive validation grid
class ExcelStudentRow {
  final int rowIndex; // 0-based index in data
  final int rollNo;
  final String studentName;
  final String admissionNo;
  final Map<String, ExcelSubjectMark> subjectMarks;
  final String? remarks;
  final List<String> errors;

  const ExcelStudentRow({
    required this.rowIndex,
    required this.rollNo,
    required this.studentName,
    required this.admissionNo,
    required this.subjectMarks,
    this.remarks,
    this.errors = const [],
  });

  bool get isValid =>
      errors.isEmpty && subjectMarks.values.every((m) => !m.hasError);

  ExcelStudentRow copyWith({
    int? rowIndex,
    int? rollNo,
    String? studentName,
    String? admissionNo,
    Map<String, ExcelSubjectMark>? subjectMarks,
    String? remarks,
    List<String>? errors,
  }) {
    return ExcelStudentRow(
      rowIndex: rowIndex ?? this.rowIndex,
      rollNo: rollNo ?? this.rollNo,
      studentName: studentName ?? this.studentName,
      admissionNo: admissionNo ?? this.admissionNo,
      subjectMarks: subjectMarks ?? this.subjectMarks,
      remarks: remarks ?? this.remarks,
      errors: errors ?? this.errors,
    );
  }
}

/// Overall parsed Excel sheet result
class ExcelParseResult {
  final String? examId;
  final String? examName;
  final String? classSectionId;
  final double maxMarks;
  final List<String> subjectCodes;
  final List<ExcelStudentRow> rows;
  final List<String> fileErrors;

  const ExcelParseResult({
    this.examId,
    this.examName,
    this.classSectionId,
    this.maxMarks = 100.0,
    required this.subjectCodes,
    required this.rows,
    this.fileErrors = const [],
  });

  int get totalRows => rows.length;
  int get validRowCount => rows.where((r) => r.isValid).length;
  int get errorRowCount => rows.where((r) => !r.isValid).length;
  bool get hasErrors => fileErrors.isNotEmpty || errorRowCount > 0;
}

/// Service to handle Excel Template generation, parsing, validation, and CBSE grading.
class ExcelService {
  static const String sheetName = 'Marks_Entry';

  /// Calculate CBSE 8-tier grade from percentage
  static String calculateCbseGrade(double? marks, double maxMarks) {
    if (marks == null || maxMarks <= 0) return 'E';
    final percentage = (marks / maxMarks) * 100.0;
    if (percentage >= 91.0) return 'A1';
    if (percentage >= 81.0) return 'A2';
    if (percentage >= 71.0) return 'B1';
    if (percentage >= 61.0) return 'B2';
    if (percentage >= 51.0) return 'C1';
    if (percentage >= 41.0) return 'C2';
    if (percentage >= 33.0) return 'D';
    return 'E';
  }

  /// Step 1: Generate pre-filled Excel template (.xlsx)
  Uint8List generateTemplate({
    required String examId,
    required String examName,
    required String classSectionId,
    required String className,
    required List<Student> students,
    required List<Map<String, String>> subjects, // [{'code': 'MATH', 'name': 'Mathematics'}]
    double maxMarks = 100.0,
    DateTime? declarationDate,
  }) {
    final excel = Excel.createExcel();
    // Default sheet is usually Sheet1, create our target sheet
    final sheet = excel[sheetName];
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Row 1: Metadata (Locked/Reference)
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = TextCellValue('EXAM_ID: $examId');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
        .value = TextCellValue('CLASS_SECTION_ID: $classSectionId');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
        .value = TextCellValue('MAX_MARKS: ${maxMarks.toInt()}');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0))
        .value = TextCellValue(
            'NOTE: Enter numeric marks, "AB" for Absent, or "ML" for Medical Leave');
    if (declarationDate != null) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0))
          .value = TextCellValue('DECLARATION_DATE: ${declarationDate.toIso8601String().split('T').first}');
    }

    // Row 2: Column Headers
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
        .value = TextCellValue('Roll_No');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1))
        .value = TextCellValue('Student_Name');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1))
        .value = TextCellValue('Admission_No');

    int colIndex = 3;
    for (final sub in subjects) {
      final code = sub['code'] ?? 'SUB';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 1))
          .value = TextCellValue('$code (${maxMarks.toInt()})');
      colIndex++;
    }

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 1))
        .value = TextCellValue('Class_Teacher_Remarks');

    // Sort students by Roll No
    final sortedStudents = List<Student>.from(students)
      ..sort((a, b) => a.rollNo.compareTo(b.rollNo));

    // Rows 3+: Student rows
    for (int i = 0; i < sortedStudents.length; i++) {
      final s = sortedStudents[i];
      final rowIndex = i + 2;

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = IntCellValue(s.rollNo);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(s.fullName);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(s.admissionNo ?? '');

      // Subject mark columns initially blank
      for (int c = 3; c < 3 + subjects.length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex))
            .value = TextCellValue('');
      }

      // Remarks column initially blank
      sheet
          .cell(CellIndex.indexByColumnRow(
              columnIndex: 3 + subjects.length, rowIndex: rowIndex))
          .value = TextCellValue('');
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? []);
  }

  /// Save generated Excel template bytes to disk
  Future<File> saveExcelFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    Directory dir;
    try {
      dir = await getTemporaryDirectory();
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Open an Excel spreadsheet in native system viewer
  Future<OpenResult> openExcelFile(String filePath) async {
    return await OpenFilex.open(
      filePath,
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  /// Step 2 & 3: Parse and validate uploaded Excel file bytes
  ExcelParseResult parseExcel(
    List<int> bytes, {
    String? expectedExamId,
    String? expectedExamName,
    String? expectedClassSectionId,
    double defaultMaxMarks = 100.0,
  }) {
    final excel = Excel.decodeBytes(bytes);

    // Prefer Marks_Entry sheet, or fall back to first available sheet
    Sheet? sheet = excel.tables[sheetName];
    if (sheet == null && excel.tables.isNotEmpty) {
      sheet = excel.tables.values.first;
    }

    if (sheet == null || sheet.maxRows < 2) {
      return const ExcelParseResult(
        subjectCodes: [],
        rows: [],
        fileErrors: ['Excel sheet is empty or contains insufficient rows.'],
      );
    }

    // Parse Metadata from Row 1
    String? examId = expectedExamId;
    String? classSectionId = expectedClassSectionId;
    double maxMarks = defaultMaxMarks;

    final row0 = sheet.rows.isNotEmpty ? sheet.rows[0] : <Data?>[];
    for (final cell in row0) {
      final text = _extractString(cell?.value);
      if (text.startsWith('EXAM_ID:')) {
        examId = text.replaceFirst('EXAM_ID:', '').trim();
      } else if (text.startsWith('CLASS_SECTION_ID:')) {
        classSectionId = text.replaceFirst('CLASS_SECTION_ID:', '').trim();
      } else if (text.startsWith('MAX_MARKS:')) {
        final parsed = double.tryParse(
          text.replaceFirst('MAX_MARKS:', '').trim(),
        );
        if (parsed != null && parsed > 0) {
          maxMarks = parsed;
        }
      }
    }

    // Parse Headers from Row 2
    if (sheet.maxRows < 2) {
      return ExcelParseResult(
        examId: examId,
        classSectionId: classSectionId,
        maxMarks: maxMarks,
        subjectCodes: const [],
        rows: const [],
        fileErrors: const ['Missing column headers on row 2.'],
      );
    }

    final row1 = sheet.rows[1];
    final subjectCols = <int, String>{}; // colIndex -> subjectCode
    int? remarksColIndex;

    for (int c = 0; c < row1.length; c++) {
      final text = _extractString(row1[c]?.value);
      if (c == 0 || c == 1 || c == 2) continue; // Roll_No, Student_Name, Admission_No

      if (text.toLowerCase().contains('remark')) {
        remarksColIndex = c;
      } else if (text.isNotEmpty) {
        // e.g. "ENG (100)" -> "ENG" or "MATH"
        final cleanCode = text.split('(').first.trim().toUpperCase();
        if (cleanCode.isNotEmpty) {
          subjectCols[c] = cleanCode;
        }
      }
    }

    final subjectCodes = subjectCols.values.toList();
    final parsedRows = <ExcelStudentRow>[];
    final fileErrors = <String>[];

    // Parse Rows starting from Row 3 (index 2)
    for (int r = 2; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      if (row.isEmpty) continue;

      final rollStr = _extractString(row.isNotEmpty ? row[0]?.value : null);
      final nameStr = _extractString(row.length > 1 ? row[1]?.value : null);
      final admStr = _extractString(row.length > 2 ? row[2]?.value : null);

      // Skip completely empty trailing rows
      if (rollStr.isEmpty && nameStr.isEmpty && admStr.isEmpty) continue;

      final rowErrors = <String>[];
      final rollNo = int.tryParse(rollStr);
      if (rollNo == null) {
        rowErrors.add('Invalid Roll Number: "$rollStr"');
      }

      final subjectMarks = <String, ExcelSubjectMark>{};

      for (final entry in subjectCols.entries) {
        final col = entry.key;
        final subCode = entry.value;
        final rawVal = col < row.length ? _extractString(row[col]?.value) : '';

        final mark = validateCell(
          subjectCode: subCode,
          rawValue: rawVal,
          maxMarks: maxMarks,
        );
        subjectMarks[subCode] = mark;
      }

      String? remarks;
      if (remarksColIndex != null && remarksColIndex < row.length) {
        remarks = _extractString(row[remarksColIndex]?.value);
        if (remarks.isEmpty) remarks = null;
      }

      parsedRows.add(
        ExcelStudentRow(
          rowIndex: r - 2,
          rollNo: rollNo ?? 0,
          studentName: nameStr,
          admissionNo: admStr,
          subjectMarks: subjectMarks,
          remarks: remarks,
          errors: rowErrors,
        ),
      );
    }

    if (parsedRows.isEmpty) {
      fileErrors.add('No student data rows found in sheet.');
    }

    return ExcelParseResult(
      examId: examId,
      examName: expectedExamName,
      classSectionId: classSectionId,
      maxMarks: maxMarks,
      subjectCodes: subjectCodes,
      rows: parsedRows,
      fileErrors: fileErrors,
    );
  }

  /// Validate individual subject cell mark
  static ExcelSubjectMark validateCell({
    required String subjectCode,
    required String rawValue,
    required double maxMarks,
    String? subjectName,
  }) {
    final trimmed = rawValue.trim();
    final name = subjectName ?? _resolveSubjectName(subjectCode);

    if (trimmed.isEmpty) {
      return ExcelSubjectMark(
        subjectCode: subjectCode,
        subjectName: name,
        maxMarks: maxMarks,
        status: 'present',
        grade: 'E',
        error: 'Missing marks for $subjectCode',
        rawValue: rawValue,
      );
    }

    final upper = trimmed.toUpperCase();
    if (upper == 'AB') {
      return ExcelSubjectMark(
        subjectCode: subjectCode,
        subjectName: name,
        marks: null,
        maxMarks: maxMarks,
        status: 'absent',
        grade: '-',
        rawValue: trimmed,
      );
    }

    if (upper == 'ML') {
      return ExcelSubjectMark(
        subjectCode: subjectCode,
        subjectName: name,
        marks: null,
        maxMarks: maxMarks,
        status: 'medical_leave',
        grade: '-',
        rawValue: trimmed,
      );
    }

    final numVal = double.tryParse(trimmed);
    if (numVal == null) {
      return ExcelSubjectMark(
        subjectCode: subjectCode,
        subjectName: name,
        marks: null,
        maxMarks: maxMarks,
        status: 'present',
        grade: 'E',
        error: 'Invalid value: use number, AB, or ML',
        rawValue: trimmed,
      );
    }

    if (numVal < 0 || numVal > maxMarks) {
      return ExcelSubjectMark(
        subjectCode: subjectCode,
        subjectName: name,
        marks: numVal,
        maxMarks: maxMarks,
        status: 'present',
        grade: 'E',
        error: 'Marks out of range (0 - ${maxMarks.toInt()})',
        rawValue: trimmed,
      );
    }

    // Valid numeric mark
    final grade = calculateCbseGrade(numVal, maxMarks);
    return ExcelSubjectMark(
      subjectCode: subjectCode,
      subjectName: name,
      marks: numVal,
      maxMarks: maxMarks,
      status: 'present',
      grade: grade,
      rawValue: trimmed,
    );
  }

  /// Re-validate a single row after inline edit
  static ExcelStudentRow revalidateRow({
    required ExcelStudentRow row,
    required double maxMarks,
  }) {
    final updatedMarks = <String, ExcelSubjectMark>{};
    for (final entry in row.subjectMarks.entries) {
      final mark = validateCell(
        subjectCode: entry.key,
        rawValue: entry.value.rawValue,
        maxMarks: maxMarks,
        subjectName: entry.value.subjectName,
      );
      updatedMarks[entry.key] = mark;
    }

    final errors = <String>[];
    if (row.rollNo <= 0) {
      errors.add('Roll number must be greater than 0');
    }
    if (row.studentName.trim().isEmpty) {
      errors.add('Student name is required');
    }

    return row.copyWith(
      subjectMarks: updatedMarks,
      errors: errors,
    );
  }

  /// Helper to convert parsed valid rows into domain ExamResult items
  static List<ExamResult> convertToExamResults({
    required ExcelParseResult parsed,
    required String examId,
    required String examName,
    required String classSectionId,
    required Map<int, Student> rollToStudentMap,
  }) {
    final results = <ExamResult>[];

    for (final row in parsed.rows) {
      if (!row.isValid) continue;

      final student = rollToStudentMap[row.rollNo];
      final studentId = student?.id ?? 'student-roll-${row.rollNo}';

      for (final mark in row.subjectMarks.values) {
        results.add(
          ExamResult(
            id: 'res-$examId-$studentId-${mark.subjectCode.toLowerCase()}',
            examId: examId,
            examName: examName,
            studentId: studentId,
            studentRollNo: row.rollNo,
            studentName: row.studentName,
            classSectionId: classSectionId,
            subjectId: 'sub-${mark.subjectCode.toLowerCase()}',
            subjectName: mark.subjectName,
            subjectCode: mark.subjectCode,
            marksObtained: mark.marks,
            maxMarks: mark.maxMarks,
            status: mark.status,
            grade: mark.grade,
            subjectRemarks: row.remarks,
          ),
        );
      }
    }

    return results;
  }

  /// Helper to extract clean text from excel cell
  static String _extractString(dynamic val) {
    if (val == null) return '';
    if (val is TextCellValue) {
      return val.value.toString().trim();
    }
    if (val is IntCellValue) {
      return val.value.toString().trim();
    }
    if (val is DoubleCellValue) {
      final d = val.value;
      return (d % 1 == 0) ? d.toInt().toString() : d.toString().trim();
    }
    return val.toString().trim();
  }

  static String _resolveSubjectName(String code) {
    switch (code.toUpperCase()) {
      case 'MATH':
      case 'MAT':
        return 'Mathematics';
      case 'SCI':
        return 'Science';
      case 'ENG':
        return 'English';
      case 'HIN':
        return 'Hindi';
      case 'SST':
      case 'SOC':
        return 'Social Science';
      case 'COMP':
        return 'Computer Science';
      case 'SAN':
        return 'Sanskrit';
      default:
        return code;
    }
  }
}
