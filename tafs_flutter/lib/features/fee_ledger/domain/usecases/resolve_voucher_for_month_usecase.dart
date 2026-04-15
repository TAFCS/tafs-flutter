import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/voucher_resolution.dart';
import '../repositories/fee_ledger_repository.dart';

class ResolveVoucherForMonthUseCase {
  final FeeLedgerRepository repository;

  const ResolveVoucherForMonthUseCase(this.repository);

  Future<Either<Failure, VoucherResolution>> call({
    required int studentCc,
    required String academicYear,
    required int targetMonth,
  }) {
    return repository.resolveVoucherForMonth(
      studentCc: studentCc,
      academicYear: academicYear,
      targetMonth: targetMonth,
    );
  }
}
