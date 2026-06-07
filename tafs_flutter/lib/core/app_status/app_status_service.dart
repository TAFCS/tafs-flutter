import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import 'app_status_model.dart';

class AppStatusService {
  final Dio _dio;

  AppStatusService({Dio? dio}) : _dio = dio ?? Dio();

  Future<AppStatusModel> checkStatus() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final buildNumberStr = packageInfo.buildNumber;
      final buildNumber = int.tryParse(buildNumberStr) ?? 9;

      String platform = 'android';
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        platform = 'ios';
      }

      // Skip check on web platform
      if (kIsWeb) {
        return AppStatusModel.defaultOk();
      }

      final url = '${AppConfig.apiBaseUrl}/app-config/status';
      final response = await _dio.get(
        url,
        queryParameters: {
          'platform': platform,
          'build': buildNumber,
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          final dataMap = responseData['data'];
          if (dataMap is Map<String, dynamic>) {
            return AppStatusModel.fromJson(dataMap);
          }
        }
      }
      return AppStatusModel.defaultOk();
    } catch (e) {
      debugPrint('Failed to check app status (failing open): $e');
      return AppStatusModel.defaultOk();
    }
  }
}
