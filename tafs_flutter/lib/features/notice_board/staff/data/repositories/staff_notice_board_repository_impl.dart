import 'package:image_picker/image_picker.dart';
import '../../domain/entities/staff_notice_post.dart';
import '../../domain/repositories/staff_notice_board_repository.dart';
import '../datasources/staff_notice_board_remote_data_source.dart';

class StaffNoticeBoardRepositoryImpl implements StaffNoticeBoardRepository {
  final StaffNoticeBoardRemoteDataSource remoteDataSource;

  StaffNoticeBoardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<StaffNoticePost>> getPosts({int? cursor}) {
    return remoteDataSource.getPosts(cursor: cursor);
  }

  @override
  Future<NoticeReadStats> getReadStats(int postId) {
    return remoteDataSource.getReadStats(postId);
  }

  @override
  Future<StaffNoticePost> createPost({
    String? title,
    required String body,
    required List<int> campusIds,
    required List<int> classIds,
    required List<int> sectionIds,
    List<int> studentCcs = const [],
    required List<String> mediaUrls,
    required List<String> mediaTypes,
    required bool isPinned,
    DateTime? expiresAt,
  }) {
    return remoteDataSource.createPost({
      if (title != null && title.isNotEmpty) 'title': title,
      'body': body,
      'campus_ids': campusIds,
      'class_ids': classIds,
      'section_ids': sectionIds,
      if (studentCcs.isNotEmpty) 'student_ccs': studentCcs,
      'media_urls': mediaUrls,
      'media_types': mediaTypes,
      'is_pinned': isPinned,
      if (expiresAt != null) 'expires_at': expiresAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> searchStudents(String query) {
    return remoteDataSource.searchStudents(query);
  }

  @override
  Future<StaffNoticePost> togglePin(int postId, bool isPinned) {
    return remoteDataSource.updatePost(postId, {'is_pinned': isPinned});
  }

  @override
  Future<void> deletePost(int postId) {
    return remoteDataSource.deletePost(postId);
  }

  @override
  Future<UploadedNoticeMedia> uploadMedia(XFile file, String displayName) async {
    final result = await remoteDataSource.uploadMedia(file);
    return UploadedNoticeMedia(
      url: result['url']!,
      type: result['type']!,
      name: displayName,
    );
  }

  @override
  Future<List<CampusScope>> getCampuses() {
    return remoteDataSource.getCampuses();
  }
}
