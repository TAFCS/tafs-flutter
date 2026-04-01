import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/voucher.dart';

abstract class FeeLedgerRepository {
  Future<Either<Failure, List<Voucher>>> getStudentVouchers(int studentCc);
}
