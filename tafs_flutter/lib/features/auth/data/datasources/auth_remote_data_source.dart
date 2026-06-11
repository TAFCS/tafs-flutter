import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/parent_dto.dart';
import '../models/staff_user_dto.dart';

abstract class AuthRemoteDataSource {
  Future<ParentDto> login(
    String username,
    String password, {
    String? fcmToken,
    String? deviceType,
  });
  Future<void> logout(String accessToken);
  Future<void> requestAccountDeletion(String accessToken);
  Future<Map<String, dynamic>> verifyCnic(String cnic);
  Future<ParentDto> registerParent(
    String cnic,
    String email,
    String password, {
    String? fcmToken,
    String? deviceType,
  });
  Future<ParentDto> getProfile(String accessToken);
  Future<StaffUserDto> staffLogin(String username, String password);
  Future<void> staffLogout(String accessToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<ParentDto> login(
    String username,
    String password, {
    String? fcmToken,
    String? deviceType,
  }) async {
    final String baseUrl = AppConfig.apiBaseUrl;

    try {
      final response = await dio.post(
        '$baseUrl/auth/parent/login',
        data: {
          "username": username,
          "password": password,
          if (fcmToken != null) "fcmToken": fcmToken,
          if (deviceType != null) "deviceType": deviceType,
        },
        options: Options(
          headers: {'Content-Type': 'application/json', 'accept': '*/*'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return ParentDto.fromJson(response.data);
      } else {
        throw const ServerFailure(
          'Unable to log in right now. Please try again.',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        throw const InvalidCredentialsFailure();
      }
      throw ServerFailure(
        ApiErrorMapper.fromDioException(
          e,
          fallback: 'Unable to log in right now. Please try again.',
        ),
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(
        ApiErrorMapper.fromObject(
          e,
          fallback: 'Unable to log in right now. Please try again.',
        ),
      );
    }
  }

  @override
  Future<void> logout(String accessToken) async {
    final String baseUrl = AppConfig.apiBaseUrl;
    try {
      await dio.post(
        '$baseUrl/auth/parent/logout',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(
        ApiErrorMapper.fromObject(
          e,
          fallback: 'Unable to log out right now. Please try again.',
        ),
      );
    }
  }

  @override
  Future<void> requestAccountDeletion(String accessToken) async {
    final String baseUrl = AppConfig.apiBaseUrl;
    try {
      await dio.post(
        '$baseUrl/auth/parent/account/deletion-request',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
    } on DioException catch (e) {
      throw ServerFailure(
        ApiErrorMapper.fromDioException(
          e,
          fallback:
              'Unable to submit your deletion request right now. Please try again.',
        ),
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(
        ApiErrorMapper.fromObject(
          e,
          fallback:
              'Unable to submit your deletion request right now. Please try again.',
        ),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> verifyCnic(String cnic) async {
    final String baseUrl = AppConfig.apiBaseUrl;

    try {
      final response = await dio.post(
        '$baseUrl/auth/parent/verify-cnic',
        data: {"cnic": cnic},
        options: Options(
          headers: {'Content-Type': 'application/json', 'accept': '*/*'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data =
            response.data['data'] as Map<String, dynamic>? ?? response.data;
        return {
          'exists': data['exists'] ?? false,
          'message': data['message'] ?? '',
          'guardianId': data['guardianId'],
          'guardianName': data['guardianName'],
        };
      } else {
        throw const ServerFailure(
          'Unable to verify CNIC right now. Please try again.',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(
        ApiErrorMapper.fromDioException(
          e,
          fallback: 'Unable to verify CNIC right now. Please try again.',
        ),
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(
        ApiErrorMapper.fromObject(
          e,
          fallback: 'Unable to verify CNIC right now. Please try again.',
        ),
      );
    }
  }

  @override
  Future<ParentDto> registerParent(
    String cnic,
    String email,
    String password, {
    String? fcmToken,
    String? deviceType,
  }) async {
    final String baseUrl = AppConfig.apiBaseUrl;

    try {
      final response = await dio.post(
        '$baseUrl/auth/parent/register',
        data: {
          "cnic": cnic,
          "email": email,
          "password": password,
          if (fcmToken != null) "fcmToken": fcmToken,
          if (deviceType != null) "deviceType": deviceType,
        },
        options: Options(
          headers: {'Content-Type': 'application/json', 'accept': '*/*'},
        ),
      );

      if (response.statusCode == 201 && response.data != null) {
        return ParentDto.fromJson(response.data);
      } else {
        throw const ServerFailure(
          'Unable to create your account right now. Please try again.',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(
        ApiErrorMapper.fromDioException(
          e,
          fallback: 'Unable to create your account right now. Please try again.',
        ),
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(
        ApiErrorMapper.fromObject(
          e,
          fallback: 'Unable to create your account right now. Please try again.',
        ),
      );
    }
  }

  @override
  Future<StaffUserDto> staffLogin(String username, String password) async {
    final String baseUrl = AppConfig.apiBaseUrl;
    try {
      final response = await dio.post(
        '$baseUrl/auth/staff/mobile/login',
        data: {'username': username, 'password': password},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 200 && response.data != null) {
        return StaffUserDto.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ServerFailure('Unable to log in right now. Please try again.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const InvalidCredentialsFailure();
      }
      throw ServerFailure(
        ApiErrorMapper.fromDioException(
          e,
          fallback: 'Unable to log in right now. Please try again.',
        ),
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(ApiErrorMapper.fromObject(e));
    }
  }

  @override
  Future<void> staffLogout(String accessToken) async {
    final String baseUrl = AppConfig.apiBaseUrl;
    try {
      await dio.post(
        '$baseUrl/auth/staff/mobile/logout',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
    } catch (_) {}
  }

  @override
  Future<ParentDto> getProfile(String accessToken) async {
    final String baseUrl = AppConfig.apiBaseUrl;

    try {
      final response = await dio.get(
        '$baseUrl/auth/parent/profile',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        data['accessToken'] = accessToken;
        return ParentDto.fromJson(data);
      } else {
        throw const ServerFailure(
          'Unable to refresh your profile right now. Please try again.',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(
        ApiErrorMapper.fromDioException(
          e,
          fallback: 'Unable to refresh your profile right now. Please try again.',
        ),
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(
        ApiErrorMapper.fromObject(
          e,
          fallback: 'Unable to refresh your profile right now. Please try again.',
        ),
      );
    }
  }
}
