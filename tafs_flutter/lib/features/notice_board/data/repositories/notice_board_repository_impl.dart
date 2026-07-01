import '../../domain/entities/attendance_alert.dart';
import '../../domain/entities/calendar_alert.dart';
import '../../domain/entities/voucher_alert.dart';
import '../../domain/entities/notice_post.dart';
import '../../domain/repositories/notice_board_repository.dart';
import '../datasources/notice_board_remote_data_source.dart';

class NoticeBoardRepositoryImpl implements NoticeBoardRepository {
  final NoticeBoardRemoteDataSource remoteDataSource;

  NoticeBoardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<NoticePost>> getPosts({int? cursor}) {
    return remoteDataSource.getPosts(cursor: cursor);
  }

  @override
  Future<void> markRead(int postId) {
    return remoteDataSource.markRead(postId);
  }

  @override
  Future<List<AttendanceAlert>> getAttendanceAlerts({int? cursor}) {
    return remoteDataSource.getAttendanceAlerts(cursor: cursor);
  }

  @override
  Future<void> markAlertRead(int alertId) {
    return remoteDataSource.markAlertRead(alertId);
  }

  @override
  Future<List<CalendarAlert>> getCalendarAlerts({int? cursor}) {
    return remoteDataSource.getCalendarAlerts(cursor: cursor);
  }

  @override
  Future<void> markCalendarAlertRead(int alertId) {
    return remoteDataSource.markCalendarAlertRead(alertId);
  }

  @override
  Future<List<VoucherAlert>> getVoucherAlerts({int? cursor}) {
    return remoteDataSource.getVoucherAlerts(cursor: cursor);
  }

  @override
  Future<void> markVoucherAlertRead(int alertId) {
    return remoteDataSource.markVoucherAlertRead(alertId);
  }
}
