import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/unconfirmed_admission_model.dart';

abstract class QuickAdmissionRemoteDataSource {
  Future<UnconfirmedAdmissionModel> createQuickAdmission(Map<String, dynamic> data);
  Future<String> uploadPhoto(int cc, String filePath);
  Future<Uint8List> getDepositSlipPdf(int cc);
}

class QuickAdmissionRemoteDataSourceImpl implements QuickAdmissionRemoteDataSource {
  final Dio dio;

  QuickAdmissionRemoteDataSourceImpl(this.dio);

  @override
  Future<UnconfirmedAdmissionModel> createQuickAdmission(Map<String, dynamic> data) async {
    final baseUrl = AppConfig.apiBaseUrl;
    try {
      final response = await dio.post(
        '$baseUrl/unconfirmed-admissions',
        data: data,
      );
      if (response.statusCode == 201 && response.data != null) {
        final payload = response.data['data'] as Map<String, dynamic>;
        return UnconfirmedAdmissionModel.fromJson(payload);
      }
      throw const ServerFailure('Failed to create quick admission');
    } on DioException catch (e) {
      throw ServerFailure(ApiErrorMapper.fromDioException(
        e,
        fallback: 'Unable to submit admission. Please try again.',
      ));
    } catch (e) {
      throw ServerFailure(ApiErrorMapper.fromObject(
        e,
        fallback: 'Unable to submit admission. Please try again.',
      ));
    }
  }

  @override
  Future<String> uploadPhoto(int cc, String filePath) async {
    final baseUrl = AppConfig.apiBaseUrl;
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        '$baseUrl/unconfirmed-admissions/$cc/photo',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final payload = response.data['data'] as Map<String, dynamic>;
        return payload['url'] as String;
      }
      throw const ServerFailure('Failed to upload photo');
    } on DioException catch (e) {
      throw ServerFailure(ApiErrorMapper.fromDioException(
        e,
        fallback: 'Unable to upload photo. Please try again.',
      ));
    } catch (e) {
      throw ServerFailure(ApiErrorMapper.fromObject(
        e,
        fallback: 'Unable to upload photo. Please try again.',
      ));
    }
  }

  @override
  Future<Uint8List> getDepositSlipPdf(int cc) async {
    final baseUrl = AppConfig.apiBaseUrl;
    try {
      final response = await dio.get<List<int>>(
        '$baseUrl/unconfirmed-admissions/$cc/deposit-slip',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data!);
      }
      throw const ServerFailure('Failed to download deposit slip');
    } on DioException catch (e) {
      throw ServerFailure(ApiErrorMapper.fromDioException(
        e,
        fallback: 'Unable to fetch deposit slip PDF. Please try again.',
      ));
    } catch (e) {
      throw ServerFailure(ApiErrorMapper.fromObject(
        e,
        fallback: 'Unable to fetch deposit slip PDF. Please try again.',
      ));
    }
  }
}
