import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/fcm_registration_service.dart';
import '../../domain/entities/cnic_verification_result.dart';
import '../../domain/entities/parent.dart';
import '../../domain/entities/staff_user.dart';
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
    String password, {
    String? fcmToken,
    String? deviceType,
  }) async {
    try {
      final parentDto = await remoteDataSource.login(
        username,
        password,
        fcmToken: fcmToken,
        deviceType: deviceType,
      );
      await localDataSource.clearStaffCache();
      await localDataSource.cacheParent(parentDto);
      return Right(parentDto);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final fcmToken = await FcmRegistrationService.instance.getToken();
      try {
        final staff = await localDataSource.getCachedStaff();
        if (staff != null) {
          await remoteDataSource.staffLogout(
            staff.accessToken,
            fcmToken: fcmToken,
          );
        } else {
          final cached = await localDataSource.getCachedParent();
          if (cached != null) {
            await remoteDataSource.logout(
              cached.accessToken,
              fcmToken: fcmToken,
            );
          }
        }
      } catch (e) {
        debugPrint('[AuthRepository] remote logout failed: $e');
      }

      await FcmRegistrationService.instance.unregisterLocally();
      await localDataSource.clearCache();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to logout locally'));
    }
  }

  @override
  Future<Either<Failure, StaffUser>> staffLogin(
    String username,
    String password,
  ) async {
    try {
      final staffDto = await remoteDataSource.staffLogin(username, password);
      await localDataSource.clearParentCache();
      await localDataSource.cacheStaff(staffDto);
      return Right(staffDto);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
    }
  }

  @override
  Future<Either<Failure, StaffUser?>> getCachedStaff() async {
    try {
      final staff = await localDataSource.getCachedStaff();
      return Right(staff);
    } catch (e) {
      return Left(CacheFailure('Failed to get cached staff'));
    }
  }

  @override
  Future<Either<Failure, void>> requestAccountDeletion({required String reason}) async {
    try {
      final cached = await localDataSource.getCachedParent();
      if (cached == null) {
        return Left(CacheFailure('No cached user found. Please login again.'));
      }

      await remoteDataSource.requestAccountDeletion(cached.accessToken, reason);
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
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
  Future<Either<Failure, CnicVerificationResult>> verifyCnic(String cnic) async {
    try {
      final result = await remoteDataSource.verifyCnic(cnic);
      return Right(CnicVerificationResult(
        exists: result['exists'] as bool? ?? false,
        guardianName: result['guardianName'] as String?,
        message: result['message'] as String?,
      ));
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
    }
  }

  @override
  Future<Either<Failure, void>> sendSignupOtp(String cnic, String email) async {
    try {
      await remoteDataSource.sendSignupOtp(cnic, email);
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
    }
  }

  @override
  Future<Either<Failure, Parent>> registerParent(
    String cnic,
    String email,
    String password, {
    required String otp,
    String? fcmToken,
    String? deviceType,
  }) async {
    try {
      final parentDto = await remoteDataSource.registerParent(
        cnic,
        email,
        password,
        otp: otp,
        fcmToken: fcmToken,
        deviceType: deviceType,
      );
      return Right(parentDto);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await remoteDataSource.forgotPassword(email);
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      await remoteDataSource.resetPassword(email, otp, newPassword);
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required bool isStaff,
  }) async {
    try {
      if (isStaff) {
        final staff = await localDataSource.getCachedStaff();
        if (staff == null) {
          return Left(CacheFailure('No cached staff session found.'));
        }
        await remoteDataSource.changePassword(
          staff.accessToken,
          currentPassword: currentPassword,
          newPassword: newPassword,
          staff: true,
        );
      } else {
        final cached = await localDataSource.getCachedParent();
        if (cached == null) {
          return Left(CacheFailure('No cached user found. Please login again.'));
        }
        await remoteDataSource.changePassword(
          cached.accessToken,
          currentPassword: currentPassword,
          newPassword: newPassword,
          staff: false,
        );
      }
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
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

      final updatedParent = parentDto.copyWith(
        refreshToken: cached.refreshToken,
      );

      await localDataSource.cacheParent(updatedParent);
      return Right(updatedParent);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
    }
  }

  @override
  Future<Either<Failure, StaffUser>> refreshStaffSession() async {
    try {
      final cached = await localDataSource.getCachedStaff();
      if (cached == null) {
        return Left(CacheFailure('No cached staff session found.'));
      }

      final staffDto = await remoteDataSource.staffRefresh(cached.refreshToken);
      await localDataSource.cacheStaff(staffDto);
      return Right(staffDto);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(ApiErrorMapper.fromObject(e)));
    }
  }
}
