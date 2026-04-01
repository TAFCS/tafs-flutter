import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/voucher.dart';
import '../repositories/fee_ledger_repository.dart';

class GetStudentVouchersUseCase {
  final FeeLedgerRepository repository;
  const GetStudentVouchersUseCase(this.repository);

  Future<Either<Failure, List<Voucher>>> call(int studentCc) {
    return repository.getStudentVouchers(studentCc);
  }
}
