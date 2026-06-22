import '../entities/attendance_alert.dart';
import '../entities/calendar_alert.dart';
import '../entities/notice_post.dart';

abstract class NoticeBoardRepository {
  Future<List<NoticePost>> getPosts({int? cursor});
  Future<void> markRead(int postId);
  Future<List<AttendanceAlert>> getAttendanceAlerts({int? cursor});
  Future<void> markAlertRead(int alertId);
  Future<List<CalendarAlert>> getCalendarAlerts({int? cursor});
  Future<void> markCalendarAlertRead(int alertId);
}
