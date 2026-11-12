import '../widgets/unified_media_viewer.dart';

/// Syllabus model for a subject term
class Syllabus {
  final String id;
  final String classSectionId;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String examTerm; // 'unit_test_1', 'half_yearly', 'unit_test_2', 'annual_finals', 'full_year'
  final String title;
  final String chaptersOverview; // Markdown bullet points
  final List<MediaAttachmentItem> attachments;
  final DateTime? updatedAt;

  const Syllabus({
    required this.id,
    required this.classSectionId,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    this.examTerm = 'full_year',
    required this.title,
    required this.chaptersOverview,
    this.attachments = const [],
    this.updatedAt,
  });

  String get termDisplayName {
    switch (examTerm) {
      case 'unit_test_1':
        return 'Unit Test 1';
      case 'half_yearly':
        return 'Half Yearly';
      case 'unit_test_2':
        return 'Unit Test 2';
      case 'annual_finals':
        return 'Annual Finals';
      default:
        return 'Full Year';
    }
  }

  factory Syllabus.fromJson(Map<String, dynamic> json) {
    var rawAttachments = json['attachments'];
    List<MediaAttachmentItem> parsedAttachments = [];
    if (rawAttachments is List) {
      parsedAttachments = rawAttachments
          .map((item) => MediaAttachmentItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Syllabus(
      id: json['id'] as String,
      classSectionId: json['class_section_id'] as String,
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String? ?? 'Subject',
      subjectCode: json['subject_code'] as String? ?? 'SUB',
      examTerm: json['exam_term'] as String? ?? 'full_year',
      title: json['title'] as String,
      chaptersOverview: json['chapters_overview'] as String? ?? '',
      attachments: parsedAttachments,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_section_id': classSectionId,
        'subject_id': subjectId,
        'subject_name': subjectName,
        'subject_code': subjectCode,
        'exam_term': examTerm,
        'title': title,
        'chapters_overview': chaptersOverview,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}
