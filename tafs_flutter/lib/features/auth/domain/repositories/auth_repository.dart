import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/parent.dart';

abstract class AuthRepository {
  Future<Either<Failure, Parent>> login(String username, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, Parent?>> getCachedUser();
}
