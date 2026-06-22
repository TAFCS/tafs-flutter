class StaffNoticePost {
  final int id;
  final String? title;
  final String body;
  final String postedByName;
  final List<int> campusIds;
  final List<int> classIds;
  final List<int> sectionIds;
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final bool isPinned;
  final DateTime postedAt;
  final DateTime? expiresAt;
  final int readCount;

  const StaffNoticePost({
    required this.id,
    this.title,
    required this.body,
    required this.postedByName,
    required this.campusIds,
    required this.classIds,
    required this.sectionIds,
    required this.mediaUrls,
    required this.mediaTypes,
    required this.isPinned,
    required this.postedAt,
    this.expiresAt,
    required this.readCount,
  });

  bool get isSchoolWide =>
      campusIds.isEmpty && classIds.isEmpty && sectionIds.isEmpty;
}

class NoticeReadStats {
  final int postId;
  final int totalReached;
  final int totalRead;

  const NoticeReadStats({
    required this.postId,
    required this.totalReached,
    required this.totalRead,
  });

  double get readRate =>
      totalReached > 0 ? totalRead / totalReached : 0;
}

class CampusClassOption {
  final int id;
  final String name;
  final List<CampusSectionOption> sections;

  const CampusClassOption({
    required this.id,
    required this.name,
    this.sections = const [],
  });
}

class CampusSectionOption {
  final int id;
  final String name;

  const CampusSectionOption({required this.id, required this.name});
}

class CampusScope {
  final int id;
  final String name;
  final List<CampusClassOption> classes;

  const CampusScope({
    required this.id,
    required this.name,
    required this.classes,
  });
}

class UploadedNoticeMedia {
  final String url;
  final String type;
  final String name;

  const UploadedNoticeMedia({
    required this.url,
    required this.type,
    required this.name,
  });
}
