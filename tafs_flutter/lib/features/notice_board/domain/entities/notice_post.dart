import 'package:equatable/equatable.dart';

class NoticePost extends Equatable {
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
  final bool isRead;

  const NoticePost({
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
    required this.isRead,
  });

  NoticePost copyWith({bool? isRead}) {
    return NoticePost(
      id: id,
      title: title,
      body: body,
      postedByName: postedByName,
      campusIds: campusIds,
      classIds: classIds,
      sectionIds: sectionIds,
      mediaUrls: mediaUrls,
      mediaTypes: mediaTypes,
      isPinned: isPinned,
      postedAt: postedAt,
      expiresAt: expiresAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, title, body, postedByName, isPinned, postedAt, isRead];
}
