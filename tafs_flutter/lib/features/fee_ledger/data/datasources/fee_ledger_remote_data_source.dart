import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/error/failures.dart';
import '../models/voucher_dto.dart';

abstract class FeeLedgerRemoteDataSource {
  Future<List<VoucherDto>> getStudentVouchers(int studentCc);
}

class FeeLedgerRemoteDataSourceImpl implements FeeLedgerRemoteDataSource {
  final Dio dio;
  FeeLedgerRemoteDataSourceImpl(this.dio);

  @override
  Future<List<VoucherDto>> getStudentVouchers(int studentCc) async {
    final baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api/v1';
    try {
      final response = await dio.get('$baseUrl/vouchers/parent/student/$studentCc');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> raw =
            (response.data['data'] as List<dynamic>?) ?? [];
        return raw
            .map((e) => VoucherDto.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw const ServerFailure('Failed to load vouchers');
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
