import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/fee_summary.dart';
import '../repositories/fee_summary_repository.dart';

class GetFeeSummaryUseCase {
  final FeeSummaryRepository repository;
  const GetFeeSummaryUseCase(this.repository);

  Future<Either<Failure, FeeSummary>> call(int studentCc) async {
    return await repository.getStudentFeeSummary(studentCc);
  }
}
