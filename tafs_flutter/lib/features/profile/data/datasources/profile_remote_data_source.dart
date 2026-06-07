import 'package:dio/dio.dart';
import '../../../../core/error/api_error_mapper.dart';
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
      throw ServerFailure(ApiErrorMapper.fromDioException(
        e,
        fallback: 'Unable to submit your request right now. Please try again.',
      ));
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(ApiErrorMapper.fromObject(
        e,
        fallback: 'Unable to submit your request right now. Please try again.',
      ));
    }
  }
}
