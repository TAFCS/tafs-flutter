import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/fee_summary.dart';
import '../../domain/repositories/fee_summary_repository.dart';
import '../datasources/fee_summary_remote_data_source.dart';

class FeeSummaryRepositoryImpl implements FeeSummaryRepository {
  final FeeSummaryRemoteDataSource remoteDataSource;
  const FeeSummaryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, FeeSummary>> getStudentFeeSummary(int studentCc) async {
    try {
      final summary = await remoteDataSource.getStudentFeeSummary(studentCc);
      return Right(summary);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
