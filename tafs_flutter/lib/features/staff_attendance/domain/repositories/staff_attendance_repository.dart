import '../entities/staff_attendance_period.dart';

abstract class StaffAttendanceRepository {
  Future<StaffAttendancePeriod> getMyAttendance(String period);
  Future<void> submitObjection({
    required DateTime attendanceDate,
    int? scanId,
    required DateTime claimedTime,
    required String reason,
  });
  Future<List<Map<String, dynamic>>> getMyObjections();
}
