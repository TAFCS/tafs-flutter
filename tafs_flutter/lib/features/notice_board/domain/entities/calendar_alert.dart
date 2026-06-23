import 'package:equatable/equatable.dart';

class CalendarAlert extends Equatable {
  final int id;
  final int familyId;
  final int studentCc;
  final String studentName;
  final DateTime date;
  final String alertType; // HOLIDAY | DAY_OFF | SCHOOL_OPEN
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final bool isPinned;

  const CalendarAlert({
    required this.id,
    required this.familyId,
    required this.studentCc,
    required this.studentName,
    required this.date,
    required this.alertType,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.isPinned = false,
  });

  CalendarAlert copyWith({bool? isRead, bool? isPinned}) {
    return CalendarAlert(
      id: id,
      familyId: familyId,
      studentCc: studentCc,
      studentName: studentName,
      date: date,
      alertType: alertType,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  List<Object?> get props => [id, familyId, studentCc, date, alertType, isRead, isPinned];
}
