import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance_day.dart';

abstract class AttendanceHistoryState extends Equatable {
  const AttendanceHistoryState();

  @override
  List<Object?> get props => [];
}

class AttendanceHistoryInitial extends AttendanceHistoryState {
  const AttendanceHistoryInitial();
}

class AttendanceHistoryLoading extends AttendanceHistoryState {
  const AttendanceHistoryLoading();
}

class AttendanceHistoryLoaded extends AttendanceHistoryState {
  final List<AttendanceDay> days;
  final String month; // YYYY-MM

  const AttendanceHistoryLoaded({
    required this.days,
    required this.month,
  });

  @override
  List<Object?> get props => [days, month];
}

class AttendanceHistoryError extends AttendanceHistoryState {
  final String message;

  const AttendanceHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
