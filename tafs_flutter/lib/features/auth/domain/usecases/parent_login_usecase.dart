import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/parent.dart';
import '../repositories/auth_repository.dart';

class ParentLoginUseCase {
  final AuthRepository repository;

  ParentLoginUseCase(this.repository);

  Future<Either<Failure, Parent>> call(String username, String password) async {
    return await repository.login(username, password);
  }
}
