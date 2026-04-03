import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/fee_summary.dart';

abstract class FeeSummaryRepository {
  Future<Either<Failure, FeeSummary>> getStudentFeeSummary(int studentCc);
}
