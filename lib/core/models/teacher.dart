/// Teacher / Faculty model for School Manager
class Teacher {
  final String id;
  final String fullName;
  final String loginCode;
  final String pin;
  final String role; // 'teacher'
  final String phone;
  final String? email;
  final String? homeroomClassId;
  final String? homeroomClassName;
  final String? homeroomClassCode;
  final String? subjectName;
  final String? subjectCode;
  final List<String> teachingClassIds;
  final DateTime? createdAt;
  final String? avatarUrl;

  const Teacher({
    required this.id,
    required this.fullName,
    required this.loginCode,
    required this.pin,
    this.role = 'teacher',
    this.phone = '',
    this.email,
    this.homeroomClassId,
    this.homeroomClassName,
    this.homeroomClassCode,
    this.subjectName,
    this.subjectCode,
    this.teachingClassIds = const [],
    this.createdAt,
    this.avatarUrl,
  });

  bool get isClassTeacher =>
      homeroomClassId != null && homeroomClassId!.trim().isNotEmpty;

  Teacher copyWith({
    String? id,
    String? fullName,
    String? loginCode,
    String? pin,
    String? role,
    String? phone,
    String? email,
    String? homeroomClassId,
    String? homeroomClassName,
    String? homeroomClassCode,
    String? subjectName,
    String? subjectCode,
    List<String>? teachingClassIds,
    DateTime? createdAt,
    String? avatarUrl,
  }) {
    return Teacher(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      loginCode: loginCode ?? this.loginCode,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      homeroomClassId: homeroomClassId ?? this.homeroomClassId,
      homeroomClassName: homeroomClassName ?? this.homeroomClassName,
      homeroomClassCode: homeroomClassCode ?? this.homeroomClassCode,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      teachingClassIds: teachingClassIds ?? this.teachingClassIds,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory Teacher.fromJson(Map<String, dynamic> json) {
    final rawClassIds = json['teaching_class_ids'];
    List<String> teachingClassIds = [];
    if (rawClassIds is List) {
      teachingClassIds = rawClassIds.map((e) => e.toString()).toList();
    }

    return Teacher(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      loginCode: json['login_code'] as String? ?? '',
      pin: json['pin'] as String? ?? json['pin_hash'] as String? ?? '',
      role: json['role'] as String? ?? 'teacher',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      homeroomClassId: json['homeroom_class_id'] as String?,
      homeroomClassName: json['homeroom_class_name'] as String?,
      homeroomClassCode: json['homeroom_class_code'] as String?,
      subjectName: json['subject_name'] as String?,
      subjectCode: json['subject_code'] as String?,
      teachingClassIds: teachingClassIds,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'login_code': loginCode,
      'pin': pin,
      'role': role,
      'phone': phone,
      'email': email,
      'homeroom_class_id': homeroomClassId,
      'homeroom_class_name': homeroomClassName,
      'homeroom_class_code': homeroomClassCode,
      'subject_name': subjectName,
      'subject_code': subjectCode,
      'teaching_class_ids': teachingClassIds,
      'created_at': createdAt?.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }
}
