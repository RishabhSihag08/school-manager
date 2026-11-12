import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

/// Service to generate official CBSE-compliant printable PDF report cards
class ReportCardPdfService {
  /// Generate printable PDF bytes for a student's exam report card
  static Future<Uint8List> generateReportCardPdf({
    required Student student,
    required ClassSection classSection,
    required String examName,
    required List<ExamResult> results,
    String? classTeacherRemarks,
    double attendancePercentage = 94.2,
    String schoolName = 'ANNUAL ACADEMIC PROGRESS REPORT',
    String schoolAffiliation = 'School Examination & Evaluation Record',
    String schoolAddress = 'Official Academic Record',
    String academicSession = 'Academic Session: 2026-2027',
  }) async {
    final pdf = pw.Document();

    // Calculate totals
    double totalObtained = 0;
    double totalMax = 0;

    for (final res in results) {
      totalMax += res.maxMarks;
      if (res.status == 'present' && res.marksObtained != null) {
        totalObtained += res.marksObtained!;
      }
    }

    final double overallPercentage =
        totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
    final String overallGrade =
        ExamResult.calculateCbseGrade(totalObtained, totalMax);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.indigo900, width: 2),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // 1. School Header & Letterhead
                _buildHeader(
                  schoolName: schoolName,
                  schoolAffiliation: schoolAffiliation,
                  schoolAddress: schoolAddress,
                  academicSession: academicSession,
                  examName: examName,
                ),

                pw.SizedBox(height: 12),
                pw.Divider(thickness: 1.5, color: PdfColors.indigo800),
                pw.SizedBox(height: 8),

                // 2. Student Info Matrix
                _buildStudentInfoGrid(
                  student: student,
                  classSection: classSection,
                  attendancePercentage: attendancePercentage,
                ),

                pw.SizedBox(height: 14),

                // 3. Scholastic Performance Table
                _buildMarksTable(results),

                pw.SizedBox(height: 10),

                // 4. Grand Total & Performance Summary
                _buildTotalSummary(
                  totalObtained: totalObtained,
                  totalMax: totalMax,
                  percentage: overallPercentage,
                  overallGrade: overallGrade,
                ),

                pw.SizedBox(height: 12),

                // 5. Remarks & Grading Legend
                _buildRemarksAndLegend(
                  remarks: classTeacherRemarks ??
                      'Consistent effort, disciplined attitude, and active participation in class.',
                ),

                pw.Spacer(),

                // 6. Signatures and Official Stamp Blocks
                _buildSignatureRow(
                  classTeacherName:
                      classSection.classTeacherName ?? 'Mr. Ramesh Sharma',
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Launch in-app PDF preview or system print dialog
  static Future<void> printOrShareReportCard({
    required Student student,
    required ClassSection classSection,
    required String examName,
    required List<ExamResult> results,
    String? classTeacherRemarks,
    double attendancePercentage = 94.2,
  }) async {
    final pdfBytes = await generateReportCardPdf(
      student: student,
      classSection: classSection,
      examName: examName,
      results: results,
      classTeacherRemarks: classTeacherRemarks,
      attendancePercentage: attendancePercentage,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name:
          'Report_Card_${student.fullName.replaceAll(' ', '_')}_${classSection.displayName}.pdf',
    );
  }

  static pw.Widget _buildHeader({
    required String schoolName,
    required String schoolAffiliation,
    required String schoolAddress,
    required String academicSession,
    required String examName,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Container(
              width: 38,
              height: 38,
              decoration: const pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: PdfColors.indigo900,
              ),
              child: pw.Center(
                child: pw.Text(
                  'SM',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  schoolName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  schoolAffiliation,
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  schoolAddress,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColors.indigo50,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.indigo200),
          ),
          child: pw.Text(
            'OFFICIAL REPORT CARD • $examName.toUpperCase() ($academicSession)',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStudentInfoGrid({
    required Student student,
    required ClassSection classSection,
    required double attendancePercentage,
  }) {
    pw.Widget infoCell(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 90,
              child: pw.Text(
                '$label:',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                infoCell('Student Name', student.fullName),
                infoCell('Roll Number', student.rollNo.toString()),
                infoCell('Class & Section', classSection.displayName),
                infoCell('House', '${student.house.toUpperCase()} HOUSE'),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                infoCell('Admission No', student.admissionNo ?? 'N/A'),
                infoCell('Parent Name', student.parentName),
                infoCell('Attendance', '${attendancePercentage.toStringAsFixed(1)}%'),
                infoCell('Class Teacher', classSection.classTeacherName ?? 'Mr. Ramesh Sharma'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMarksTable(List<ExamResult> results) {
    const tableHeaders = [
      'Subject Code',
      'Subject Name',
      'Max Marks',
      'Marks Obtained',
      'Percentage',
      'Grade',
      'Remarks',
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(2.5),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(1.3),
        5: pw.FlexColumnWidth(1.0),
        6: pw.FlexColumnWidth(2.6),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
          children: tableHeaders.map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              child: pw.Text(
                header,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8.5,
                ),
              ),
            );
          }).toList(),
        ),

        // Data Rows
        ...results.map((r) {
          final isAbsent = r.status == 'absent';
          final isMedical = r.status == 'medical_leave';
          final obtainedStr = isAbsent
              ? 'AB (Absent)'
              : (isMedical
                  ? 'ML (Leave)'
                  : (r.marksObtained != null
                      ? r.marksObtained!.toStringAsFixed(1)
                      : '-'));

          final pctStr = (r.marksObtained != null && r.maxMarks > 0)
              ? '${((r.marksObtained! / r.maxMarks) * 100).toStringAsFixed(1)}%'
              : '-';

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isAbsent
                  ? PdfColors.red50
                  : (isMedical ? PdfColors.amber50 : PdfColors.white),
            ),
            children: [
              _cell(r.subjectCode, align: pw.TextAlign.center, isMono: true),
              _cell(r.subjectName, isBold: true),
              _cell(r.maxMarks.toInt().toString(), align: pw.TextAlign.center),
              _cell(
                obtainedStr,
                align: pw.TextAlign.center,
                isBold: true,
                color: isAbsent
                    ? PdfColors.red800
                    : (isMedical ? PdfColors.amber800 : PdfColors.black),
              ),
              _cell(pctStr, align: pw.TextAlign.center),
              _cell(
                r.grade ?? '-',
                align: pw.TextAlign.center,
                isBold: true,
                color: (r.grade == 'A1' || r.grade == 'A2')
                    ? PdfColors.green800
                    : (r.grade == 'E' ? PdfColors.red800 : PdfColors.black),
              ),
              _cell(r.subjectRemarks ?? 'Good effort', fontSize: 7.5),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
    bool isMono = false,
    double fontSize = 8.5,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _buildTotalSummary({
    required double totalObtained,
    required double totalMax,
    required double percentage,
    required String overallGrade,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.indigo300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'GRAND TOTAL: ${totalObtained.toStringAsFixed(1)} / ${totalMax.toInt()}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
          pw.Text(
            'OVERALL PERCENTAGE: ${percentage.toStringAsFixed(1)}%',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
          pw.Text(
            'OVERALL GRADE: $overallGrade',
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.Text(
            percentage >= 33 ? 'RESULT: PASSED' : 'RESULT: NEEDS IMPROVEMENT',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: percentage >= 33 ? PdfColors.green900 : PdfColors.red800,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRemarksAndLegend({required String remarks}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Teacher Remarks Box
        pw.Expanded(
          flex: 6,
          child: pw.Container(
            height: 64,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CLASS TEACHER REMARKS:',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  remarks,
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        // CBSE Grading Scale
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(3),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CBSE 8-TIER GRADING SCALE:',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'A1 (91-100) • A2 (81-90) • B1 (71-80) • B2 (61-70)\n'
                  'C1 (51-60) • C2 (41-50) • D (33-40) • E (<33 Needs Imp.)',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSignatureRow({required String classTeacherName}) {
    pw.Widget signatureLine(String title, {String? subtitle}) {
      return pw.Column(
        children: [
          pw.Container(
            width: 120,
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (subtitle != null)
            pw.Text(
              subtitle,
              style: const pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey600,
              ),
            ),
        ],
      );
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          signatureLine('Class Teacher', subtitle: classTeacherName),
          pw.Container(
            width: 60,
            height: 40,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, style: pw.BorderStyle.dashed),
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: pw.Center(
              child: pw.Text(
                'OFFICIAL\nSEAL',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey500),
              ),
            ),
          ),
          signatureLine('Exam In-Charge'),
          signatureLine('Principal / Headmaster'),
        ],
      ),
    );
  }
}
