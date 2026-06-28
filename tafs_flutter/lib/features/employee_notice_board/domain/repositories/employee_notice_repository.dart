import '../entities/employee_notice.dart';

abstract class EmployeeNoticeRepository {
  Future<List<EmployeeNotice>> getFeed();
  Future<void> markRead(int postId);
}
