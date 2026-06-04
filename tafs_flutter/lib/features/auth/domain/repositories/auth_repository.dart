import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cnic_verification_result.dart';
import '../entities/parent.dart';

abstract class AuthRepository {
  Future<Either<Failure, Parent>> login(
    String username,
    String password, {
    String? fcmToken,
    String? deviceType,
  });
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, void>> deleteAccount();
  Future<Either<Failure, Parent?>> getCachedUser();

  // Signup methods
  Future<Either<Failure, CnicVerificationResult>> verifyCnic(String cnic);
  Future<Either<Failure, Parent>> registerParent(
    String cnic,
    String email,
    String password, {
    String? fcmToken,
    String? deviceType,
  });
  Future<Either<Failure, Parent>> refreshProfile();
}
