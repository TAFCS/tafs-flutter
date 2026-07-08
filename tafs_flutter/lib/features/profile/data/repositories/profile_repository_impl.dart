import 'package:dartz/dartz.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> submitGuardianChangeRequest({
    required int guardianId,
    required int familyId,
    required Map<String, String> changes,
  }) async {
    try {
      await remoteDataSource.submitGuardianChangeRequest(
        guardianId: guardianId,
        familyId: familyId,
        changes: changes,
      );
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
    }
  }

  @override
  Future<Either<Failure, void>> submitStudentChangeRequest({
    required int guardianId,
    required int familyId,
    required int studentCc,
    required Map<String, dynamic> changes,
  }) async {
    try {
      await remoteDataSource.submitStudentChangeRequest(
        guardianId: guardianId,
        familyId: familyId,
        studentCc: studentCc,
        changes: changes,
      );
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
    }
  }

  @override
  Future<Either<Failure, String>> uploadStudentPhoto({
    required int studentCc,
    required String filePath,
  }) async {
    try {
      final url = await remoteDataSource.uploadStudentPhoto(
        studentCc: studentCc,
        filePath: filePath,
      );
      return Right(url);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
    }
  }

  @override
  Future<Either<Failure, String>> uploadGuardianPhoto({
    required int guardianId,
    required String filePath,
  }) async {
    try {
      final url = await remoteDataSource.uploadGuardianPhoto(
        guardianId: guardianId,
        filePath: filePath,
      );
      return Right(url);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
    }
  }
}
