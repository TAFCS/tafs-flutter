import 'package:dio/dio.dart';
import '../models/attendance_alert_dto.dart';
import '../models/notice_post_dto.dart';
import '../models/calendar_alert_dto.dart';

class NoticeBoardRemoteDataSource {
  final Dio dio;

  NoticeBoardRemoteDataSource(this.dio);

  Future<List<NoticePostDto>> getPosts({int? cursor}) async {
    final response = await dio.get(
      '/notice-board',
      queryParameters: cursor != null ? {'cursor': cursor} : null,
    );
    final data = response.data;
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list.map((e) => NoticePostDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(int postId) async {
    await dio.post('/notice-board/$postId/read');
  }

  Future<List<AttendanceAlertDto>> getAttendanceAlerts({int? cursor}) async {
    final response = await dio.get(
      '/attendance-notifications',
      queryParameters: cursor != null ? {'cursor': cursor} : null,
    );
    final data = response.data;
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list.map((e) => AttendanceAlertDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markAlertRead(int alertId) async {
    await dio.post('/attendance-notifications/$alertId/read');
  }

  Future<List<CalendarAlertDto>> getCalendarAlerts({int? cursor}) async {
    final response = await dio.get(
      '/calendar-notifications',
      queryParameters: cursor != null ? {'cursor': cursor} : null,
    );
    final data = response.data;
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list.map((e) => CalendarAlertDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markCalendarAlertRead(int alertId) async {
    await dio.post('/calendar-notifications/$alertId/read');
  }
}
