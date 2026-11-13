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

  String get toDbCategory {
    switch (this) {
      case AnnouncementCategory.holiday:
        return 'holiday';
      case AnnouncementCategory.exam:
        return 'exam';
      case AnnouncementCategory.event:
        return 'event';
      case AnnouncementCategory.urgent:
        return 'urgent';
      case AnnouncementCategory.classNotice:
        return 'class_notice';
      case AnnouncementCategory.general:
        return 'general';
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
  final DateTime? expiresAt;
  final String? authorId;
  final String? authorName;
  final String? authorRole; // 'admin' or 'teacher'

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
    this.expiresAt,
    this.authorId,
    this.authorName,
    this.authorRole = 'admin',
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Announcement copyWith({
    String? id,
    String? title,
    String? body,
    AnnouncementCategory? category,
    bool? isPinned,
    DateTime? eventOrHolidayDate,
    int? targetGrade,
    String? targetClassSectionId,
    List<MediaAttachmentItem>? attachments,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? authorId,
    String? authorName,
    String? authorRole,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      eventOrHolidayDate: eventOrHolidayDate ?? this.eventOrHolidayDate,
      targetGrade: targetGrade ?? this.targetGrade,
      targetClassSectionId: targetClassSectionId ?? this.targetClassSectionId,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
    );
  }

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
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      authorId: json['author_id'] as String? ?? json['created_by'] as String?,
      authorName: json['author_name'] as String?,
      authorRole: json['author_role'] as String? ?? 'admin',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category.toDbCategory,
        'is_pinned': isPinned,
        if (eventOrHolidayDate != null)
          'event_or_holiday_date': eventOrHolidayDate!.toIso8601String().split('T')[0],
        if (targetGrade != null) 'target_grade': targetGrade,
        if (targetClassSectionId != null) 'target_class_section_id': targetClassSectionId,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
        if (authorId != null) 'author_id': authorId,
        if (authorName != null) 'author_name': authorName,
        'author_role': authorRole ?? 'admin',
      };
}
