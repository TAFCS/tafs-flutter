import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class ProfileRepository {
  Future<Either<Failure, void>> submitGuardianChangeRequest({
    required int guardianId,
    required int familyId,
    required Map<String, String> changes,
  });

  Future<Either<Failure, void>> submitStudentChangeRequest({
    required int guardianId,
    required int familyId,
    required int studentCc,
    required Map<String, dynamic> changes,
  });

  Future<Either<Failure, String>> uploadStudentPhoto({
    required int studentCc,
    required String filePath,
  });

  Future<Either<Failure, String>> uploadGuardianPhoto({
    required int guardianId,
    required String filePath,
  });
}
