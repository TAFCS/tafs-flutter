import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/error/failures.dart';
import '../models/parent_dto.dart';

abstract class AuthRemoteDataSource {
  Future<ParentDto> login(String username, String password);
  Future<void> logout(String accessToken);
  Future<Map<String, dynamic>> verifyCnic(String cnic);
  Future<ParentDto> registerParent(String cnic, String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<ParentDto> login(String username, String password) async {
    final String baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api/v1';

    try {
      final response = await dio.post(
        '$baseUrl/auth/parent/login',
        data: {"username": username, "password": password},
        options: Options(
          headers: {'Content-Type': 'application/json', 'accept': '*/*'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return ParentDto.fromJson(response.data);
      } else {
        throw const ServerFailure(
          'Login failed. Invalid response from server.',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        throw const InvalidCredentialsFailure();
      }
      throw ServerFailure(e.message ?? 'Unknown server error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> logout(String accessToken) async {
    final String baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api/v1';
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
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> verifyCnic(String cnic) async {
    final String baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api/v1';

    try {
      final response = await dio.post(
        '$baseUrl/auth/parent/verify-cnic',
        data: {"cnic": cnic},
        options: Options(
          headers: {'Content-Type': 'application/json', 'accept': '*/*'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Extract the data from the API response
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
          'CNIC verification failed. Invalid response from server.',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Unknown server error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<ParentDto> registerParent(
    String cnic,
    String email,
    String password,
  ) async {
    final String baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api/v1';

    try {
      final response = await dio.post(
        '$baseUrl/auth/parent/register',
        data: {"cnic": cnic, "email": email, "password": password},
        options: Options(
          headers: {'Content-Type': 'application/json', 'accept': '*/*'},
        ),
      );

      if (response.statusCode == 201 && response.data != null) {
        return ParentDto.fromJson(response.data);
      } else {
        throw const ServerFailure(
          'Registration failed. Invalid response from server.',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw const ServerFailure('Email already in use');
      }
      throw ServerFailure(e.message ?? 'Unknown server error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
