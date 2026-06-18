import '../../domain/entities/attendance_day.dart';

class AttendanceDayDto extends AttendanceDay {
  const AttendanceDayDto({
    required super.date,
    super.status,
    required super.sessions,
    super.holidayType,
    super.holidayDescription,
  });

  factory AttendanceDayDto.fromJson(Map<String, dynamic> json) {
    final sessionList = json['sessions'] as List? ?? [];
    final parsedSessions = sessionList.map((s) {
      final inStr = s['clock_in'] as String;
      final outStr = s['clock_out'] as String?;
      return AttendanceSession(
        clockIn: DateTime.parse(inStr).toLocal(),
        clockOut: outStr != null ? DateTime.parse(outStr).toLocal() : null,
      );
    }).toList();

    return AttendanceDayDto(
      date: json['date'] as String,
      status: json['status'] as String?,
      sessions: parsedSessions,
      holidayType: json['holiday_type'] as String?,
      holidayDescription: json['holiday_description'] as String?,
    );
  }
}
