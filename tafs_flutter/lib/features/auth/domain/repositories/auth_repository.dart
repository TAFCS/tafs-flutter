import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cnic_verification_result.dart';
import '../entities/parent.dart';
import '../entities/staff_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, Parent>> login(
    String username,
    String password, {
    String? fcmToken,
    String? deviceType,
  });
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, void>> requestAccountDeletion({required String reason});
  Future<Either<Failure, Parent?>> getCachedUser();
  Future<Either<Failure, StaffUser?>> getCachedStaff();
  Future<Either<Failure, StaffUser>> staffLogin(String username, String password);

  // Signup methods
  Future<Either<Failure, CnicVerificationResult>> verifyCnic(String cnic);
  Future<Either<Failure, void>> sendSignupOtp(String cnic, String email);
  Future<Either<Failure, Parent>> registerParent(
    String cnic,
    String email,
    String password, {
    required String otp,
    String? fcmToken,
    String? deviceType,
  });

  // Forgot / reset password
  Future<Either<Failure, void>> forgotPassword(String email);
  Future<Either<Failure, void>> resetPassword(String email, String otp, String newPassword);
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required bool isStaff,
  });

  Future<Either<Failure, Parent>> refreshProfile();
  Future<Either<Failure, StaffUser>> refreshStaffSession();
}
