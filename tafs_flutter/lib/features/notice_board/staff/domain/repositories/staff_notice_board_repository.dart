import 'package:image_picker/image_picker.dart';
import '../../domain/entities/staff_notice_post.dart';

abstract class StaffNoticeBoardRepository {
  Future<List<StaffNoticePost>> getPosts({int? cursor});
  Future<NoticeReadStats> getReadStats(int postId);
  Future<StaffNoticePost> createPost({
    String? title,
    required String body,
    required List<int> campusIds,
    required List<int> classIds,
    required List<int> sectionIds,
    required List<String> mediaUrls,
    required List<String> mediaTypes,
    required bool isPinned,
    DateTime? expiresAt,
  });
  Future<StaffNoticePost> togglePin(int postId, bool isPinned);
  Future<void> deletePost(int postId);
  Future<UploadedNoticeMedia> uploadMedia(XFile file, String displayName);
  Future<List<CampusScope>> getCampuses();
}
