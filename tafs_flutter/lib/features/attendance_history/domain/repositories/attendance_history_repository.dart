import '../entities/attendance_day.dart';

abstract class AttendanceHistoryRepository {
  Future<List<AttendanceDay>> getAttendanceHistory(int studentCc, String month);
}
