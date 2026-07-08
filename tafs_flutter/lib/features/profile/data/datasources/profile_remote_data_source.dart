import 'package:dio/dio.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../../../core/error/failures.dart';

abstract class ProfileRemoteDataSource {
  Future<void> submitGuardianChangeRequest({
    required int guardianId,
    required int familyId,
    required Map<String, String> changes,
  });

  Future<void> submitStudentChangeRequest({
    required int guardianId,
    required int familyId,
    required int studentCc,
    required Map<String, dynamic> changes,
  });

  Future<String> uploadStudentPhoto({
    required int studentCc,
    required String filePath,
  });

  Future<String> uploadGuardianPhoto({
    required int guardianId,
    required String filePath,
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

  @override
  Future<void> submitStudentChangeRequest({
    required int guardianId,
    required int familyId,
    required int studentCc,
    required Map<String, dynamic> changes,
  }) async {
    try {
      await dio.post(
        '/parent-change-requests',
        data: {
          'guardian_id': guardianId,
          'family_id': familyId,
          'requested_data': {
            'request_type': 'STUDENT_UPDATE',
            'student_cc': studentCc,
            'changes': changes,
          },
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

  @override
  Future<String> uploadStudentPhoto({
    required int studentCc,
    required String filePath,
  }) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        '/media/student/$studentCc/photo/standard?temp=true',
        data: formData,
      );

      if (response.data != null) {
        return response.data['url'] as String;
      }
      throw const ServerFailure('Invalid response from server');
    } on DioException catch (e) {
      throw ServerFailure(ApiErrorMapper.fromDioException(
        e,
        fallback: 'Unable to upload photo right now. Please try again.',
      ));
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(ApiErrorMapper.fromObject(
        e,
        fallback: 'Unable to upload photo right now. Please try again.',
      ));
    }
  }

  @override
  Future<String> uploadGuardianPhoto({
    required int guardianId,
    required String filePath,
  }) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        '/media/guardian/$guardianId/photo?temp=true',
        data: formData,
      );

      if (response.data != null) {
        return response.data['url'] as String;
      }
      throw const ServerFailure('Invalid response from server');
    } on DioException catch (e) {
      throw ServerFailure(ApiErrorMapper.fromDioException(
        e,
        fallback: 'Unable to upload photo right now. Please try again.',
      ));
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(ApiErrorMapper.fromObject(
        e,
        fallback: 'Unable to upload photo right now. Please try again.',
      ));
    }
  }
}
