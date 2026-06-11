import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/staff_user.dart';
import '../repositories/auth_repository.dart';

class StaffLoginUseCase {
  final AuthRepository repository;

  StaffLoginUseCase(this.repository);

  Future<Either<Failure, StaffUser>> call(String username, String password) {
    return repository.staffLogin(username, password);
  }
}
