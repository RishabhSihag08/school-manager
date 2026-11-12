import '../widgets/unified_media_viewer.dart';

/// Homework model for assignments published by teachers
class Homework {
  final String id;
  final String classSectionId;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String? teacherId;
  final String? teacherName;
  final String title;
  final String? description;
  final DateTime dueDate;
  final List<MediaAttachmentItem> attachments;
  final bool isCompleted;

  const Homework({
    required this.id,
    required this.classSectionId,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    this.teacherId,
    this.teacherName,
    required this.title,
    this.description,
    required this.dueDate,
    this.attachments = const [],
    this.isCompleted = false,
  });

  Homework copyWith({
    String? id,
    String? classSectionId,
    String? subjectId,
    String? subjectName,
    String? subjectCode,
    String? teacherId,
    String? teacherName,
    String? title,
    String? description,
    DateTime? dueDate,
    List<MediaAttachmentItem>? attachments,
    bool? isCompleted,
  }) {
    return Homework(
      id: id ?? this.id,
      classSectionId: classSectionId ?? this.classSectionId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      attachments: attachments ?? this.attachments,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory Homework.fromJson(Map<String, dynamic> json) {
    var rawAttachments = json['attachments'];
    List<MediaAttachmentItem> parsedAttachments = [];
    if (rawAttachments is List) {
      parsedAttachments = rawAttachments
          .map((item) => MediaAttachmentItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Homework(
      id: json['id'] as String,
      classSectionId: json['class_section_id'] as String,
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String? ?? 'Subject',
      subjectCode: json['subject_code'] as String? ?? 'SUB',
      teacherId: json['teacher_id'] as String?,
      teacherName: json['teacher_name'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      attachments: parsedAttachments,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_section_id': classSectionId,
        'subject_id': subjectId,
        'subject_name': subjectName,
        'subject_code': subjectCode,
        'teacher_id': teacherId,
        'teacher_name': teacherName,
        'title': title,
        'description': description,
        'due_date': dueDate.toIso8601String().split('T')[0],
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'is_completed': isCompleted,
      };
}
