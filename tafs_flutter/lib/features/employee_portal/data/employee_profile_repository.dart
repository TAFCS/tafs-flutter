import 'package:dio/dio.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../domain/entities/employee_profile.dart';

class EmployeeProfileRepository {
  final Dio dio;

  EmployeeProfileRepository({required this.dio});

  Future<EmployeeProfile> getMyProfile() async {
    try {
      final res = await dio.get('/hr/employees/me');
      final raw = res.data;
      final json = raw is Map && raw['data'] != null ? raw['data'] as Map<String, dynamic> : raw as Map<String, dynamic>;
      return EmployeeProfile.fromJson(json);
    } catch (e) {
      throw ApiErrorMapper.fromObject(e);
    }
  }
}
