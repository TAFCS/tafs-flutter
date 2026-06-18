import 'package:equatable/equatable.dart';

class AttendanceDay extends Equatable {
  final String date; // YYYY-MM-DD
  final String? status; // e.g. "PRESENT", "ABSENT", "LATE", null
  final List<AttendanceSession> sessions;
  final String? holidayType;        // 'HOLIDAY' | 'WEEKEND' | 'WORKDAY' | null
  final String? holidayDescription; // e.g. "Eid ul-Fitr"

  const AttendanceDay({
    required this.date,
    this.status,
    required this.sessions,
    this.holidayType,
    this.holidayDescription,
  });

  bool get isHoliday => holidayType == 'HOLIDAY';
  bool get isWeekend => holidayType == 'WEEKEND';

  @override
  List<Object?> get props => [date, status, sessions, holidayType, holidayDescription];
}

class AttendanceSession extends Equatable {
  final DateTime clockIn;
  final DateTime? clockOut;

  const AttendanceSession({
    required this.clockIn,
    this.clockOut,
  });

  @override
  List<Object?> get props => [clockIn, clockOut];
}
