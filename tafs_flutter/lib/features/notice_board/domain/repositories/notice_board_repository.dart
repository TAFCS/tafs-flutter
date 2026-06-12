import '../entities/attendance_alert.dart';
import '../entities/notice_post.dart';

abstract class NoticeBoardRepository {
  Future<List<NoticePost>> getPosts({int? cursor});
  Future<void> markRead(int postId);
  Future<List<AttendanceAlert>> getAttendanceAlerts({int? cursor});
  Future<void> markAlertRead(int alertId);
}
