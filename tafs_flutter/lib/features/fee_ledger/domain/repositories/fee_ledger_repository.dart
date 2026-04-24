import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/fee_month_status.dart';
import '../entities/ledger.dart';
import '../entities/voucher.dart';
import '../entities/voucher_resolution.dart';

abstract class FeeLedgerRepository {
  Future<Either<Failure, List<Voucher>>> getStudentVouchers(int studentCc);
  Future<Either<Failure, List<FeeMonthStatus>>> getStudentFeeMonths(
    int studentCc,
  );
  Future<Either<Failure, Ledger>> getLedger(int studentCc);
  Future<Either<Failure, VoucherResolution>> resolveVoucherForMonth({
    required int studentCc,
    required String academicYear,
    required int targetMonth,
  });
}
