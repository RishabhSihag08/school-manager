enum AttendanceStatus {
  present,
  absent,
  leave,
  late;

  static AttendanceStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'absent':
        return AttendanceStatus.absent;
      case 'leave':
        return AttendanceStatus.leave;
      case 'late':
        return AttendanceStatus.late;
      case 'present':
      default:
        return AttendanceStatus.present;
    }
  }

  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.leave:
        return 'On Leave';
      case AttendanceStatus.late:
        return 'Late';
    }
  }
}

/// Daily Attendance record
class Attendance {
  final String id;
  final String classSectionId;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;
  final String? markedBy;

  const Attendance({
    required this.id,
    required this.classSectionId,
    required this.studentId,
    required this.date,
    required this.status,
    this.markedBy,
  });

  Attendance copyWith({
    String? id,
    String? classSectionId,
    String? studentId,
    DateTime? date,
    AttendanceStatus? status,
    String? markedBy,
  }) {
    return Attendance(
      id: id ?? this.id,
      classSectionId: classSectionId ?? this.classSectionId,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
    );
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as String,
      classSectionId: json['class_section_id'] as String,
      studentId: json['student_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: AttendanceStatus.fromString(json['status'] as String? ?? 'present'),
      markedBy: json['marked_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_section_id': classSectionId,
        'student_id': studentId,
        'date': date.toIso8601String().split('T')[0],
        'status': status.name,
        if (markedBy != null) 'marked_by': markedBy,
      };
}
