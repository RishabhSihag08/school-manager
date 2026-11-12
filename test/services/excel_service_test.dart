import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_manager/core/models/student.dart';
import 'package:school_manager/core/services/excel_service.dart';

void main() {
  final service = ExcelService();

  final List<Student> testStudents = [
    const Student(
      id: 'stud-2',
      rollNo: 2,
      fullName: 'Kabir Verma',
      admissionNo: 'ADM2026102',
      classSectionId: 'class-8b',
      parentName: 'Vikram Verma',
      parentPhone: '9876543211',
      pinHash: '1234',
    ),
    const Student(
      id: 'stud-1',
      rollNo: 1,
      fullName: 'Aarav Sharma',
      admissionNo: 'ADM2026101',
      classSectionId: 'class-8b',
      parentName: 'Sanjay Sharma',
      parentPhone: '9876543210',
      pinHash: '1234',
    ),
    const Student(
      id: 'stud-3',
      rollNo: 3,
      fullName: 'Ananya Iyer',
      admissionNo: 'ADM2026103',
      classSectionId: 'class-8b',
      parentName: 'Venkat Iyer',
      parentPhone: '9876543212',
      pinHash: '1234',
    ),
  ];

  final testSubjects = [
    {'code': 'ENG', 'name': 'English'},
    {'code': 'MATH', 'name': 'Mathematics'},
    {'code': 'SCI', 'name': 'Science'},
  ];

  group('ExcelService Template Generation', () {
    test('generates valid .xlsx bytes with sorted student rows and metadata', () {
      final bytes = service.generateTemplate(
        examId: 'exam-hy-2026',
        examName: 'Half Yearly Examination',
        classSectionId: 'sec-8b',
        className: 'Class 8-B',
        students: testStudents,
        subjects: testSubjects,
        maxMarks: 100.0,
      );

      expect(bytes, isNotEmpty);

      // Verify generated workbook structure
      final excel = Excel.decodeBytes(bytes);
      expect(excel.tables.containsKey(ExcelService.sheetName), isTrue);

      final sheet = excel.tables[ExcelService.sheetName]!;
      expect(sheet.maxRows, greaterThanOrEqualTo(5)); // Row 0 (meta), Row 1 (header), Rows 2-4 (students)

      // Row 0 Metadata check
      final metaRow = sheet.rows[0];
      final metaText0 = metaRow[0]?.value?.toString() ?? '';
      final metaText1 = metaRow[1]?.value?.toString() ?? '';
      final metaText2 = metaRow[2]?.value?.toString() ?? '';

      expect(metaText0, contains('EXAM_ID: exam-hy-2026'));
      expect(metaText1, contains('CLASS_SECTION_ID: sec-8b'));
      expect(metaText2, contains('MAX_MARKS: 100'));

      // Row 1 Column Headers check
      final headerRow = sheet.rows[1];
      expect(headerRow[0]?.value?.toString(), equals('Roll_No'));
      expect(headerRow[1]?.value?.toString(), equals('Student_Name'));
      expect(headerRow[2]?.value?.toString(), equals('Admission_No'));
      expect(headerRow[3]?.value?.toString(), contains('ENG'));
      expect(headerRow[4]?.value?.toString(), contains('MATH'));
      expect(headerRow[5]?.value?.toString(), contains('SCI'));
      expect(headerRow[6]?.value?.toString(), equals('Class_Teacher_Remarks'));

      // Student rows must be sorted by Roll_No (1, 2, 3)
      final rowStud1 = sheet.rows[2];
      expect(rowStud1[0]?.value?.toString(), equals('1'));
      expect(rowStud1[1]?.value?.toString(), equals('Aarav Sharma'));

      final rowStud2 = sheet.rows[3];
      expect(rowStud2[0]?.value?.toString(), equals('2'));
      expect(rowStud2[1]?.value?.toString(), equals('Kabir Verma'));

      final rowStud3 = sheet.rows[4];
      expect(rowStud3[0]?.value?.toString(), equals('3'));
      expect(rowStud3[1]?.value?.toString(), equals('Ananya Iyer'));
    });
  });

  group('ExcelService Cell Validation & Parsing', () {
    test('validates valid numeric marks and calculates correct CBSE grades', () {
      final mark95 = ExcelService.validateCell(
        subjectCode: 'MATH',
        rawValue: '95',
        maxMarks: 100.0,
      );
      expect(mark95.hasError, isFalse);
      expect(mark95.marks, equals(95.0));
      expect(mark95.status, equals('present'));
      expect(mark95.grade, equals('A1'));

      final mark85 = ExcelService.validateCell(
        subjectCode: 'SCI',
        rawValue: '  85.5  ', // whitespace trimmed
        maxMarks: 100.0,
      );
      expect(mark85.hasError, isFalse);
      expect(mark85.marks, equals(85.5));
      expect(mark85.grade, equals('A2'));
    });

    test('parses "AB" and "ML" codes (case-insensitive with whitespace)', () {
      // Absent
      final markAb = ExcelService.validateCell(
        subjectCode: 'ENG',
        rawValue: '  ab  ',
        maxMarks: 100.0,
      );
      expect(markAb.hasError, isFalse);
      expect(markAb.marks, isNull);
      expect(markAb.status, equals('absent'));
      expect(markAb.grade, equals('-'));

      // Medical Leave
      final markMl = ExcelService.validateCell(
        subjectCode: 'HIN',
        rawValue: 'Ml',
        maxMarks: 100.0,
      );
      expect(markMl.hasError, isFalse);
      expect(markMl.marks, isNull);
      expect(markMl.status, equals('medical_leave'));
      expect(markMl.grade, equals('-'));
    });

    test('flags out-of-range marks (> maxMarks or < 0) with clear error', () {
      final highMark = ExcelService.validateCell(
        subjectCode: 'MATH',
        rawValue: '105',
        maxMarks: 100.0,
      );
      expect(highMark.hasError, isTrue);
      expect(highMark.error, contains('out of range'));

      final negativeMark = ExcelService.validateCell(
        subjectCode: 'MATH',
        rawValue: '-5',
        maxMarks: 100.0,
      );
      expect(negativeMark.hasError, isTrue);
      expect(negativeMark.error, contains('out of range'));
    });

    test('flags invalid text strings that are neither numbers nor AB/ML', () {
      final invalidText = ExcelService.validateCell(
        subjectCode: 'MATH',
        rawValue: 'Pass',
        maxMarks: 100.0,
      );
      expect(invalidText.hasError, isTrue);
      expect(invalidText.error, contains('Invalid value: use number, AB, or ML'));
    });

    test('flags empty cell as missing marks error', () {
      final emptyMark = ExcelService.validateCell(
        subjectCode: 'MATH',
        rawValue: '   ',
        maxMarks: 100.0,
      );
      expect(emptyMark.hasError, isTrue);
      expect(emptyMark.error, contains('Missing marks'));
    });
  });

  group('ExcelService CBSE Grade Tiers (A1 to E)', () {
    test('verifies all 8 CBSE tiers against official thresholds', () {
      expect(ExcelService.calculateCbseGrade(91.0, 100.0), equals('A1'));
      expect(ExcelService.calculateCbseGrade(100.0, 100.0), equals('A1'));

      expect(ExcelService.calculateCbseGrade(81.0, 100.0), equals('A2'));
      expect(ExcelService.calculateCbseGrade(90.5, 100.0), equals('A2'));

      expect(ExcelService.calculateCbseGrade(71.0, 100.0), equals('B1'));
      expect(ExcelService.calculateCbseGrade(80.0, 100.0), equals('B1'));

      expect(ExcelService.calculateCbseGrade(61.0, 100.0), equals('B2'));
      expect(ExcelService.calculateCbseGrade(70.5, 100.0), equals('B2'));

      expect(ExcelService.calculateCbseGrade(51.0, 100.0), equals('C1'));
      expect(ExcelService.calculateCbseGrade(60.0, 100.0), equals('C1'));

      expect(ExcelService.calculateCbseGrade(41.0, 100.0), equals('C2'));
      expect(ExcelService.calculateCbseGrade(50.0, 100.0), equals('C2'));

      expect(ExcelService.calculateCbseGrade(33.0, 100.0), equals('D'));
      expect(ExcelService.calculateCbseGrade(40.5, 100.0), equals('D'));

      expect(ExcelService.calculateCbseGrade(32.9, 100.0), equals('E'));
      expect(ExcelService.calculateCbseGrade(0.0, 100.0), equals('E'));
      expect(ExcelService.calculateCbseGrade(null, 100.0), equals('E'));
    });
  });

  group('ExcelService End-to-End Workbook Roundtrip', () {
    test('generates template, fills valid & special entries, and parses back accurately', () {
      // 1. Generate template
      final templateBytes = service.generateTemplate(
        examId: 'exam-final-2026',
        examName: 'Annual Finals',
        classSectionId: 'sec-8b',
        className: 'Class 8-B',
        students: testStudents,
        subjects: testSubjects,
        maxMarks: 100.0,
      );

      // 2. Simulate user filling in values in Excel
      final excel = Excel.decodeBytes(templateBytes);
      final sheet = excel.tables[ExcelService.sheetName]!;

      // Student 1 (Aarav): ENG=92, MATH=98, SCI=91, Remarks="Excellent performance"
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 2)).value = TextCellValue('92');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 2)).value = TextCellValue('98');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 2)).value = TextCellValue('91');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 2)).value = TextCellValue('Excellent performance');

      // Student 2 (Kabir): ENG=75, MATH=AB, SCI=80, Remarks="Missed Math exam"
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 3)).value = TextCellValue('75');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 3)).value = TextCellValue('AB');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 3)).value = TextCellValue('80');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 3)).value = TextCellValue('Missed Math exam');

      // Student 3 (Ananya): ENG=88, MATH=ML, SCI=84, Remarks="Medical leave for Math"
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 4)).value = TextCellValue('88');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 4)).value = TextCellValue('ML');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 4)).value = TextCellValue('84');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 4)).value = TextCellValue('Medical leave for Math');

      final filledBytes = Uint8List.fromList(excel.encode()!);

      // 3. Parse filled bytes
      final parsed = service.parseExcel(filledBytes);

      expect(parsed.hasErrors, isFalse);
      expect(parsed.examId, equals('exam-final-2026'));
      expect(parsed.classSectionId, equals('sec-8b'));
      expect(parsed.totalRows, equals(3));
      expect(parsed.validRowCount, equals(3));
      expect(parsed.errorRowCount, equals(0));

      // Check Student 1
      final row1 = parsed.rows[0];
      expect(row1.rollNo, equals(1));
      expect(row1.studentName, equals('Aarav Sharma'));
      expect(row1.subjectMarks['MATH']!.marks, equals(98.0));
      expect(row1.subjectMarks['MATH']!.grade, equals('A1'));
      expect(row1.remarks, equals('Excellent performance'));

      // Check Student 2 (Absent in Math)
      final row2 = parsed.rows[1];
      expect(row2.rollNo, equals(2));
      expect(row2.subjectMarks['MATH']!.status, equals('absent'));
      expect(row2.subjectMarks['MATH']!.marks, isNull);
      expect(row2.subjectMarks['MATH']!.grade, equals('-'));

      // Check Student 3 (Medical Leave in Math)
      final row3 = parsed.rows[2];
      expect(row3.rollNo, equals(3));
      expect(row3.subjectMarks['MATH']!.status, equals('medical_leave'));
      expect(row3.subjectMarks['MATH']!.marks, isNull);
      expect(row3.subjectMarks['MATH']!.grade, equals('-'));
    });
  });
}
