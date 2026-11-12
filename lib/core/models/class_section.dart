/// ClassSection model representing a Grade and Section (e.g. Class 8-B)
class ClassSection {
  final String id;
  final int grade;
  final String section;
  final String? classTeacherId;
  final String? classTeacherName;
  final String classCode; // e.g. '8B-K9X2'
  final bool isCodeLocked;
  final String academicYear;
  final String? timetableFileUrl;

  const ClassSection({
    required this.id,
    required this.grade,
    required this.section,
    this.classTeacherId,
    this.classTeacherName,
    required this.classCode,
    this.isCodeLocked = false,
    this.academicYear = '2026-2027',
    this.timetableFileUrl,
  });

  String get displayName => 'Class $grade-$section';

  ClassSection copyWith({
    String? id,
    int? grade,
    String? section,
    String? classTeacherId,
    String? classTeacherName,
    String? classCode,
    bool? isCodeLocked,
    String? academicYear,
    String? timetableFileUrl,
  }) {
    return ClassSection(
      id: id ?? this.id,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      classTeacherId: classTeacherId ?? this.classTeacherId,
      classTeacherName: classTeacherName ?? this.classTeacherName,
      classCode: classCode ?? this.classCode,
      isCodeLocked: isCodeLocked ?? this.isCodeLocked,
      academicYear: academicYear ?? this.academicYear,
      timetableFileUrl: timetableFileUrl ?? this.timetableFileUrl,
    );
  }

  factory ClassSection.fromJson(Map<String, dynamic> json) {
    return ClassSection(
      id: json['id'] as String,
      grade: json['grade'] as int,
      section: json['section'] as String,
      classTeacherId: json['class_teacher_id'] as String?,
      classTeacherName: json['class_teacher_name'] as String?,
      classCode: json['class_code'] as String,
      isCodeLocked: json['is_code_locked'] as bool? ?? false,
      academicYear: json['academic_year'] as String? ?? '2026-2027',
      timetableFileUrl: json['timetable_file_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'grade': grade,
        'section': section,
        'class_teacher_id': classTeacherId,
        'class_teacher_name': classTeacherName,
        'class_code': classCode,
        'is_code_locked': isCodeLocked,
        'academic_year': academicYear,
        if (timetableFileUrl != null) 'timetable_file_url': timetableFileUrl,
      };
}
