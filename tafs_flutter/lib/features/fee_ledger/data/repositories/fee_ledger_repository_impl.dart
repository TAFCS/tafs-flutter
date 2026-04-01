import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/voucher.dart';
import '../../domain/repositories/fee_ledger_repository.dart';
import '../datasources/fee_ledger_remote_data_source.dart';

class FeeLedgerRepositoryImpl implements FeeLedgerRepository {
  final FeeLedgerRemoteDataSource remoteDataSource;
  const FeeLedgerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Voucher>>> getStudentVouchers(int studentCc) async {
    try {
      final vouchers = await remoteDataSource.getStudentVouchers(studentCc);
      return Right(vouchers);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
