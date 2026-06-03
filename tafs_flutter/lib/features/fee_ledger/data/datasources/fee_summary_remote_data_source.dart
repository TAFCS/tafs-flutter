import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/error/failures.dart';
import '../models/fee_summary_dto.dart';

abstract class FeeSummaryRemoteDataSource {
  Future<FeeSummaryDto> getStudentFeeSummary(int studentCc);
}

class FeeSummaryRemoteDataSourceImpl implements FeeSummaryRemoteDataSource {
  final Dio dio;
  FeeSummaryRemoteDataSourceImpl(this.dio);

  @override
  Future<FeeSummaryDto> getStudentFeeSummary(int studentCc) async {
    final baseUrl =
        AppConfig.apiBaseUrl;
    try {
      final response = await dio.get('$baseUrl/fees/parent/student/$studentCc/summary');
      if (response.statusCode == 200 && response.data != null) {
        return FeeSummaryDto.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw const ServerFailure('Failed to load fee summary');
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
