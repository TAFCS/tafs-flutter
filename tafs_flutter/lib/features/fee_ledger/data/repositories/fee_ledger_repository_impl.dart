import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/fee_month_status.dart';
import '../../domain/entities/voucher.dart';
import '../../domain/entities/voucher_resolution.dart';
import '../../domain/repositories/fee_ledger_repository.dart';
import '../datasources/fee_ledger_remote_data_source.dart';

class FeeLedgerRepositoryImpl implements FeeLedgerRepository {
  final FeeLedgerRemoteDataSource remoteDataSource;
  const FeeLedgerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Voucher>>> getStudentVouchers(
    int studentCc,
  ) async {
    try {
      final vouchers = await remoteDataSource.getStudentVouchers(studentCc);
      return Right(vouchers);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FeeMonthStatus>>> getStudentFeeMonths(
    int studentCc,
  ) async {
    try {
      final months = await remoteDataSource.getStudentFeeMonths(studentCc);
      return Right(months);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VoucherResolution>> resolveVoucherForMonth({
    required int studentCc,
    required String academicYear,
    required int targetMonth,
  }) async {
    try {
      final result = await remoteDataSource.resolveVoucherForMonth(
        studentCc: studentCc,
        academicYear: academicYear,
        targetMonth: targetMonth,
      );
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
