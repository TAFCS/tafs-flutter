import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
        dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api/v1';
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
