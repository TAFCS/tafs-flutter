import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ledger.dart';
import '../repositories/fee_ledger_repository.dart';

class GetLedgerUseCase {
  final FeeLedgerRepository repository;

  GetLedgerUseCase(this.repository);

  Future<Either<Failure, Ledger>> call(int studentCc) async {
    return await repository.getLedger(studentCc);
  }
}
