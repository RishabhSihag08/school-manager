/// Exam Result item for a student in a specific exam & subject
class ExamResult {
  final String id;
  final String examId;
  final String examName;
  final String studentId;
  final int? studentRollNo;
  final String? studentName;
  final String classSectionId;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final double? marksObtained; // null if absent or medical leave
  final double maxMarks;
  final String status; // 'present', 'absent', 'medical_leave'
  final String? grade; // 'A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'D', 'E'
  final String? subjectRemarks;

  const ExamResult({
    required this.id,
    required this.examId,
    required this.examName,
    required this.studentId,
    this.studentRollNo,
    this.studentName,
    required this.classSectionId,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    this.marksObtained,
    this.maxMarks = 100.0,
    this.status = 'present',
    this.grade,
    this.subjectRemarks,
  });

  /// CBSE 8-tier automatic grading calculation
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

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    final marks = (json['marks_obtained'] as num?)?.toDouble();
    final max = (json['max_marks'] as num?)?.toDouble() ?? 100.0;
    final status = json['status'] as String? ?? 'present';
    final grade = json['grade'] as String? ??
        (status == 'present' && marks != null
            ? calculateCbseGrade(marks, max)
            : '-');

    return ExamResult(
      id: json['id'] as String,
      examId: json['exam_id'] as String,
      examName: json['exam_name'] as String? ?? 'Examination',
      studentId: json['student_id'] as String,
      studentRollNo: json['student_roll_no'] as int?,
      studentName: json['student_name'] as String?,
      classSectionId: json['class_section_id'] as String,
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String? ?? 'Subject',
      subjectCode: json['subject_code'] as String? ?? 'SUB',
      marksObtained: marks,
      maxMarks: max,
      status: status,
      grade: grade,
      subjectRemarks: json['subject_remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_id': examId,
        'exam_name': examName,
        'student_id': studentId,
        if (studentRollNo != null) 'student_roll_no': studentRollNo,
        if (studentName != null) 'student_name': studentName,
        'class_section_id': classSectionId,
        'subject_id': subjectId,
        'subject_name': subjectName,
        'subject_code': subjectCode,
        'marks_obtained': marksObtained,
        'max_marks': maxMarks,
        'status': status,
        'grade': grade,
        if (subjectRemarks != null) 'subject_remarks': subjectRemarks,
      };
}

/// Overall summary for a student in an exam
class ExamStudentSummary {
  final String examId;
  final String examName;
  final String studentId;
  final double totalObtained;
  final double totalMax;
  final double percentage;
  final String overallGrade;
  final int? rankInClass;
  final String? classTeacherRemarks;

  const ExamStudentSummary({
    required this.examId,
    required this.examName,
    required this.studentId,
    required this.totalObtained,
    required this.totalMax,
    required this.percentage,
    required this.overallGrade,
    this.rankInClass,
    this.classTeacherRemarks,
  });
}
