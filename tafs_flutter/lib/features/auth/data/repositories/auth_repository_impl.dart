import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/parent.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, Parent>> login(
    String username,
    String password,
  ) async {
    try {
      final parentDto = await remoteDataSource.login(username, password);
      await localDataSource.cacheParent(parentDto);
      return Right(parentDto);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      try {
        // Read the cached access token so the server can revoke the refresh token
        final cached = await localDataSource.getCachedParent();
        if (cached != null) {
          await remoteDataSource.logout(cached.accessToken);
        }
      } catch (e) {
        // We still want to clear local cache even if remote fails (e.g. no internet)
      }
      await localDataSource.clearCache();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to logout locally'));
    }
  }

  @override
  Future<Either<Failure, Parent?>> getCachedUser() async {
    try {
      final parentDto = await localDataSource.getCachedParent();
      return Right(parentDto);
    } catch (e) {
      return Left(CacheFailure('Failed to get cached user'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> verifyCnic(String cnic) async {
    try {
      final result = await remoteDataSource.verifyCnic(cnic);
      return Right(result);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Parent>> registerParent(
    String cnic,
    String email,
    String password,
  ) async {
    try {
      final parentDto = await remoteDataSource.registerParent(
        cnic,
        email,
        password,
      );
      await localDataSource.cacheParent(parentDto);
      return Right(parentDto);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Parent>> refreshProfile() async {
    try {
      final cached = await localDataSource.getCachedParent();
      if (cached == null) {
        return Left(CacheFailure('No cached user found. Please login again.'));
      }

      final parentDto = await remoteDataSource.getProfile(cached.accessToken);
      
      // Merge with existing refresh token since remote getProfile doesn't provide it
      final updatedParent = parentDto.copyWith(
        refreshToken: cached.refreshToken,
      );

      await localDataSource.cacheParent(updatedParent);
      return Right(updatedParent);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
