import 'package:equatable/equatable.dart';

abstract class AttendanceHistoryEvent extends Equatable {
  const AttendanceHistoryEvent();

  @override
  List<Object?> get props => [];
}

class AttendanceHistoryLoadRequested extends AttendanceHistoryEvent {
  final int studentCc;
  final String month; // YYYY-MM

  const AttendanceHistoryLoadRequested({
    required this.studentCc,
    required this.month,
  });

  @override
  List<Object?> get props => [studentCc, month];
}
