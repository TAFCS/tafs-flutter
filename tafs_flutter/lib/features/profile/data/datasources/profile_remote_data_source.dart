import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';

abstract class ProfileRemoteDataSource {
  Future<void> submitGuardianChangeRequest({
    required int guardianId,
    required int familyId,
    required Map<String, String> changes,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio dio;

  ProfileRemoteDataSourceImpl(this.dio);

  @override
  Future<void> submitGuardianChangeRequest({
    required int guardianId,
    required int familyId,
    required Map<String, String> changes,
  }) async {
    try {
      await dio.post(
        '/parent-change-requests',
        data: {
          'guardian_id': guardianId,
          'family_id': familyId,
          'requested_data': changes,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String?
          ?? e.message
          ?? 'Failed to submit change request';
      throw ServerFailure(message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
