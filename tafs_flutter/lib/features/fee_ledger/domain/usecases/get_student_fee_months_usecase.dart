import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/fee_month_status.dart';
import '../repositories/fee_ledger_repository.dart';

class GetStudentFeeMonthsUseCase {
  final FeeLedgerRepository repository;

  const GetStudentFeeMonthsUseCase(this.repository);

  Future<Either<Failure, List<FeeMonthStatus>>> call(int studentCc) {
    return repository.getStudentFeeMonths(studentCc);
  }
}
