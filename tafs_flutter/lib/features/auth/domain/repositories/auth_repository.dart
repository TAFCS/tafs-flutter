import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/parent.dart';

abstract class AuthRepository {
  Future<Either<Failure, Parent>> login(String username, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, Parent?>> getCachedUser();

  // Signup methods
  Future<Either<Failure, Map<String, dynamic>>> verifyCnic(String cnic);
  Future<Either<Failure, Parent>> registerParent(
    String cnic,
    String email,
    String password,
  );
}
