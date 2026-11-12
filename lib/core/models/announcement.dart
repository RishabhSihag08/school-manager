import '../widgets/unified_media_viewer.dart';

/// Announcement category
enum AnnouncementCategory {
  holiday,
  exam,
  event,
  urgent,
  general,
  classNotice;

  static AnnouncementCategory fromString(String val) {
    switch (val.toLowerCase()) {
      case 'holiday':
        return AnnouncementCategory.holiday;
      case 'exam':
        return AnnouncementCategory.exam;
      case 'event':
        return AnnouncementCategory.event;
      case 'urgent':
        return AnnouncementCategory.urgent;
      case 'class_notice':
        return AnnouncementCategory.classNotice;
      case 'general':
      default:
        return AnnouncementCategory.general;
    }
  }

  String get label {
    switch (this) {
      case AnnouncementCategory.holiday:
        return 'Holiday 🏖️';
      case AnnouncementCategory.exam:
        return 'Exam Alert 📝';
      case AnnouncementCategory.event:
        return 'Event 🎉';
      case AnnouncementCategory.urgent:
        return 'Urgent 🚨';
      case AnnouncementCategory.classNotice:
        return 'Class Notice 📢';
      case AnnouncementCategory.general:
        return 'General 📢';
    }
  }
}

/// School-wide or Class Notice Announcement
class Announcement {
  final String id;
  final String title;
  final String body;
  final AnnouncementCategory category;
  final bool isPinned;
  final DateTime? eventOrHolidayDate;
  final int? targetGrade;
  final String? targetClassSectionId;
  final List<MediaAttachmentItem> attachments;
  final DateTime createdAt;
  final String? authorName;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.isPinned = false,
    this.eventOrHolidayDate,
    this.targetGrade,
    this.targetClassSectionId,
    this.attachments = const [],
    required this.createdAt,
    this.authorName,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    var rawAttachments = json['attachments'];
    List<MediaAttachmentItem> parsedAttachments = [];
    if (rawAttachments is List) {
      parsedAttachments = rawAttachments
          .map((item) => MediaAttachmentItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: AnnouncementCategory.fromString(json['category'] as String? ?? 'general'),
      isPinned: json['is_pinned'] as bool? ?? false,
      eventOrHolidayDate: json['event_or_holiday_date'] != null
          ? DateTime.parse(json['event_or_holiday_date'] as String)
          : null,
      targetGrade: json['target_grade'] as int?,
      targetClassSectionId: json['target_class_section_id'] as String?,
      attachments: parsedAttachments,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      authorName: json['author_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category.name,
        'is_pinned': isPinned,
        if (eventOrHolidayDate != null)
          'event_or_holiday_date': eventOrHolidayDate!.toIso8601String().split('T')[0],
        if (targetGrade != null) 'target_grade': targetGrade,
        if (targetClassSectionId != null) 'target_class_section_id': targetClassSectionId,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        if (authorName != null) 'author_name': authorName,
      };
}
