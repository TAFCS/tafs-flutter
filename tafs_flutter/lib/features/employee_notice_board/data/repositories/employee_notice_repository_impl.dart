import '../../domain/entities/employee_notice.dart';
import '../../domain/repositories/employee_notice_repository.dart';
import '../datasources/employee_notice_remote_data_source.dart';

class EmployeeNoticeRepositoryImpl implements EmployeeNoticeRepository {
  final EmployeeNoticeRemoteDataSource remoteDataSource;

  EmployeeNoticeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<EmployeeNotice>> getFeed() => remoteDataSource.getFeed();

  @override
  Future<void> markRead(int postId) => remoteDataSource.markRead(postId);
}
