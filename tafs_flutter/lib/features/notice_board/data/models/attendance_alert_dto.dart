import '../../domain/entities/attendance_alert.dart';

class AttendanceAlertDto extends AttendanceAlert {
  const AttendanceAlertDto({
    required super.id,
    required super.studentCc,
    required super.studentName,
    required super.direction,
    required super.scanTime,
    required super.title,
    required super.body,
    required super.isRead,
  });

  factory AttendanceAlertDto.fromJson(Map<String, dynamic> json) {
    return AttendanceAlertDto(
      id: json['id'] as int,
      studentCc: json['student_cc'] as int,
      studentName: (json['students'] as Map<String, dynamic>?)?['full_name'] as String? ?? 'Student',
      direction: json['direction'] as String,
      scanTime: DateTime.parse(json['scan_time'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['read_at'] != null,
    );
  }
}
