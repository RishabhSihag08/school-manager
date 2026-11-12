/// Timetable period row
class TimetablePeriod {
  final String id;
  final String classSectionId;
  final int dayOfWeek; // 1 = Monday .. 6 = Saturday
  final int periodNo; // 1 to 8
  final String startTime; // e.g. '08:00 AM'
  final String endTime; // e.g. '08:45 AM'
  final bool isBreak;
  final String? breakLabel;
  final String? subjectId;
  final String? subjectName;
  final String? subjectCode;
  final String? teacherName;

  const TimetablePeriod({
    required this.id,
    required this.classSectionId,
    required this.dayOfWeek,
    required this.periodNo,
    required this.startTime,
    required this.endTime,
    this.isBreak = false,
    this.breakLabel,
    this.subjectId,
    this.subjectName,
    this.subjectCode,
    this.teacherName,
  });

  factory TimetablePeriod.fromJson(Map<String, dynamic> json) {
    return TimetablePeriod(
      id: json['id'] as String,
      classSectionId: json['class_section_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      periodNo: json['period_no'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isBreak: json['is_break'] as bool? ?? false,
      breakLabel: json['break_label'] as String?,
      subjectId: json['subject_id'] as String?,
      subjectName: json['subject_name'] as String?,
      subjectCode: json['subject_code'] as String?,
      teacherName: json['teacher_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_section_id': classSectionId,
        'day_of_week': dayOfWeek,
        'period_no': periodNo,
        'start_time': startTime,
        'end_time': endTime,
        'is_break': isBreak,
        if (breakLabel != null) 'break_label': breakLabel,
        if (subjectId != null) 'subject_id': subjectId,
        if (subjectName != null) 'subject_name': subjectName,
        if (subjectCode != null) 'subject_code': subjectCode,
        if (teacherName != null) 'teacher_name': teacherName,
      };
}
