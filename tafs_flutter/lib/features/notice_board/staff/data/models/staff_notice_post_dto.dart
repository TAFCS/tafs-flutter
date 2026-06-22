import '../../domain/entities/staff_notice_post.dart';

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.parse(value);
  throw FormatException('Expected int, got $value');
}

class StaffNoticePostDto extends StaffNoticePost {
  const StaffNoticePostDto({
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
    required super.readCount,
  });

  factory StaffNoticePostDto.fromJson(Map<String, dynamic> json) {
    List<int> parseIntList(dynamic v) {
      if (v == null) return [];
      return (v as List<dynamic>).map(_parseInt).toList();
    }

    List<String> parseStringList(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    final count = json['_count'] as Map<String, dynamic>?;
    return StaffNoticePostDto(
      id: _parseInt(json['id']),
      title: json['title'] as String?,
      body: json['body'] as String,
      postedByName:
          (json['users'] as Map<String, dynamic>?)?['full_name'] as String? ??
              'Admin',
      campusIds: parseIntList(json['campus_ids']),
      classIds: parseIntList(json['class_ids']),
      sectionIds: parseIntList(json['section_ids']),
      mediaUrls: parseStringList(json['media_urls']),
      mediaTypes: parseStringList(json['media_types']),
      isPinned: json['is_pinned'] as bool? ?? false,
      postedAt: DateTime.parse(json['posted_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      readCount: count?['post_reads'] != null
          ? _parseInt(count!['post_reads'])
          : 0,
    );
  }
}

class NoticeReadStatsDto extends NoticeReadStats {
  const NoticeReadStatsDto({
    required super.postId,
    required super.totalReached,
    required super.totalRead,
  });

  factory NoticeReadStatsDto.fromJson(Map<String, dynamic> json) {
    return NoticeReadStatsDto(
      postId: _parseInt(json['post_id']),
      totalReached: json['total_reached'] != null
          ? _parseInt(json['total_reached'])
          : 0,
      totalRead:
          json['total_read'] != null ? _parseInt(json['total_read']) : 0,
    );
  }
}

class CampusScopeDto extends CampusScope {
  const CampusScopeDto({
    required super.id,
    required super.name,
    required super.classes,
  });

  factory CampusScopeDto.fromJson(Map<String, dynamic> json) {
    final offered = json['offered_classes'] as List<dynamic>? ?? [];
    final classes = offered.map((raw) {
      final cls = raw as Map<String, dynamic>;
      final sections = (cls['sections'] as List<dynamic>? ?? [])
          .map((s) {
            final section = s as Map<String, dynamic>;
            return CampusSectionOption(
              id: _parseInt(section['id']),
              name: section['description'] as String? ?? '',
            );
          })
          .toList();
      return CampusClassOption(
        id: _parseInt(cls['id']),
        name: cls['description'] as String? ?? '',
        sections: sections,
      );
    }).toList();

    return CampusScopeDto(
      id: _parseInt(json['id']),
      name: json['campus_name'] as String? ?? '',
      classes: classes,
    );
  }
}
