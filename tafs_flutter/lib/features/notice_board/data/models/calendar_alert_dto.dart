import '../../domain/entities/calendar_alert.dart';

class CalendarAlertDto extends CalendarAlert {
  const CalendarAlertDto({
    required super.id,
    required super.familyId,
    required super.studentCc,
    required super.studentName,
    required super.date,
    required super.alertType,
    required super.title,
    required super.body,
    required super.isRead,
    required super.createdAt,
    required super.isPinned,
  });

  factory CalendarAlertDto.fromJson(Map<String, dynamic> json) {
    return CalendarAlertDto(
      id: json['id'] as int,
      familyId: json['family_id'] as int,
      studentCc: json['student_cc'] as int,
      studentName: (json['students'] as Map<String, dynamic>?)?['full_name'] as String? ?? 'Student',
      date: DateTime.parse(json['date'] as String),
      alertType: json['alert_type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['read_at'] != null,
      createdAt: DateTime.parse(json['created_at'] as String),
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }
}
