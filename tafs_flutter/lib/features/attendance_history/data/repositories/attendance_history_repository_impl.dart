import 'package:dio/dio.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/repositories/attendance_history_repository.dart';
import '../models/attendance_day_dto.dart';

class AttendanceHistoryRepositoryImpl implements AttendanceHistoryRepository {
  final Dio dio;

  AttendanceHistoryRepositoryImpl({required this.dio});

  @override
  Future<List<AttendanceDay>> getAttendanceHistory(int studentCc, String month) async {
    final response = await dio.get(
      '/app/student/$studentCc/attendance-history',
      queryParameters: {'month': month},
    );
    final data = response.data;
    final list = data['days'] as List? ?? [];
    return list.map((e) => AttendanceDayDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}
