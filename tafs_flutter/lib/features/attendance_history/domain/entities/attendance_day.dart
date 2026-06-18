import 'package:equatable/equatable.dart';

class AttendanceDay extends Equatable {
  final String date; // YYYY-MM-DD
  final String? status; // e.g. "PRESENT", "ABSENT", "LATE", null
  final List<AttendanceSession> sessions;

  const AttendanceDay({
    required this.date,
    this.status,
    required this.sessions,
  });

  @override
  List<Object?> get props => [date, status, sessions];
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
