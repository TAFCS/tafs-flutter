import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/unconfirmed_admission.dart';
import '../../domain/repositories/quick_admission_repository.dart';
import '../datasources/quick_admission_remote_data_source.dart';

class QuickAdmissionRepositoryImpl implements QuickAdmissionRepository {
  final QuickAdmissionRemoteDataSource remoteDataSource;

  QuickAdmissionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UnconfirmedAdmission>> createQuickAdmission(Map<String, dynamic> data) async {
    try {
      final result = await remoteDataSource.createQuickAdmission(data);
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadPhoto(int cc, String filePath) async {
    try {
      final url = await remoteDataSource.uploadPhoto(cc, filePath);
      return Right(url);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> getDepositSlipPdf(int cc) async {
    try {
      final pdfBytes = await remoteDataSource.getDepositSlipPdf(cc);
      return Right(pdfBytes);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
