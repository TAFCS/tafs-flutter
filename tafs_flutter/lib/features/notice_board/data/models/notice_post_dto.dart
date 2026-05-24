import '../../domain/entities/notice_post.dart';

class NoticePostDto extends NoticePost {
  const NoticePostDto({
    required super.id,
    super.title,
    required super.body,
    required super.postedByName,
    required super.campusIds,
    required super.classIds,
    required super.sectionIds,
    required super.mediaUrls,
    required super.mediaTypes,
    required super.isPinned,
    required super.postedAt,
    super.expiresAt,
    required super.isRead,
  });

  factory NoticePostDto.fromJson(Map<String, dynamic> json) {
    final reads = json['post_reads'] as List<dynamic>?;
    final isRead = reads != null && reads.isNotEmpty;

    List<int> parseIntList(dynamic v) {
      if (v == null) return [];
      return (v as List<dynamic>).map((e) => e as int).toList();
    }

    List<String> parseStringList(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    return NoticePostDto(
      id: json['id'] as int,
      title: json['title'] as String?,
      body: json['body'] as String,
      postedByName: (json['users'] as Map<String, dynamic>?)?['full_name'] as String? ?? 'Admin',
      campusIds: parseIntList(json['campus_ids']),
      classIds: parseIntList(json['class_ids']),
      sectionIds: parseIntList(json['section_ids']),
      mediaUrls: parseStringList(json['media_urls']),
      mediaTypes: parseStringList(json['media_types']),
      isPinned: json['is_pinned'] as bool? ?? false,
      postedAt: DateTime.parse(json['posted_at'] as String),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      isRead: isRead,
    );
  }
}
