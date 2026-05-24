import '../entities/notice_post.dart';

abstract class NoticeBoardRepository {
  Future<List<NoticePost>> getPosts({int? cursor});
  Future<void> markRead(int postId);
}
