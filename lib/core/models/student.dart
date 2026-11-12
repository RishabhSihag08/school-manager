/// Student model for School Manager
class Student {
  final String id;
  final int rollNo;
  final String fullName;
  final String? admissionNo;
  final String classSectionId;
  final String parentName;
  final String parentPhone;
  final String house; // Optional/legacy house field, defaults to empty
  final String pinHash;
  final int homeworkStreak;
  final DateTime? lastHomeworkCompletedDate;
  final DateTime? joinedAt;
  final String? avatarUrl;

  const Student({
    required this.id,
    required this.rollNo,
    required this.fullName,
    this.admissionNo,
    required this.classSectionId,
    required this.parentName,
    required this.parentPhone,
    this.house = '',
    required this.pinHash,
    this.homeworkStreak = 0,
    this.lastHomeworkCompletedDate,
    this.joinedAt,
    this.avatarUrl,
  });

  Student copyWith({
    String? id,
    int? rollNo,
    String? fullName,
    String? admissionNo,
    String? classSectionId,
    String parentName = '',
    String parentPhone = '',
    String? house,
    String? pinHash,
    int? homeworkStreak,
    DateTime? lastHomeworkCompletedDate,
    DateTime? joinedAt,
    String? avatarUrl,
  }) {
    return Student(
      id: id ?? this.id,
      rollNo: rollNo ?? this.rollNo,
      fullName: fullName ?? this.fullName,
      admissionNo: admissionNo ?? this.admissionNo,
      classSectionId: classSectionId ?? this.classSectionId,
      parentName: parentName.isNotEmpty ? parentName : this.parentName,
      parentPhone: parentPhone.isNotEmpty ? parentPhone : this.parentPhone,
      house: house ?? this.house,
      pinHash: pinHash ?? this.pinHash,
      homeworkStreak: homeworkStreak ?? this.homeworkStreak,
      lastHomeworkCompletedDate:
          lastHomeworkCompletedDate ?? this.lastHomeworkCompletedDate,
      joinedAt: joinedAt ?? this.joinedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      rollNo: json['roll_no'] as int,
      fullName: json['full_name'] as String,
      admissionNo: json['admission_no'] as String?,
      classSectionId: json['class_section_id'] as String,
      parentName: json['parent_name'] as String? ?? '',
      parentPhone: json['parent_phone'] as String? ?? '',
      house: json['house'] as String? ?? '',
      pinHash: json['pin_hash'] as String? ?? '1234',
      homeworkStreak: json['homework_streak'] as int? ?? 0,
      lastHomeworkCompletedDate: json['last_homework_completed_date'] != null
          ? DateTime.parse(json['last_homework_completed_date'] as String)
          : null,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roll_no': rollNo,
        'full_name': fullName,
        'admission_no': admissionNo,
        'class_section_id': classSectionId,
        'parent_name': parentName,
        'parent_phone': parentPhone,
        'house': house,
        'pin_hash': pinHash,
        'homework_streak': homeworkStreak,
        if (lastHomeworkCompletedDate != null)
          'last_homework_completed_date':
              lastHomeworkCompletedDate!.toIso8601String(),
        if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
}
