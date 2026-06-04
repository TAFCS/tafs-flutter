import 'package:dartz/dartz.dart';
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
      return Left(ServerFailure(e.toString()));
    }
  }
}
