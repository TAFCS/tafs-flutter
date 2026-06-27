import 'package:equatable/equatable.dart';
import '../../domain/entities/staff_attendance_period.dart';

abstract class StaffAttendanceState extends Equatable {
  const StaffAttendanceState();
  @override
  List<Object?> get props => [];
}

class StaffAttendanceInitial extends StaffAttendanceState {
  const StaffAttendanceInitial();
}

class StaffAttendanceLoading extends StaffAttendanceState {
  const StaffAttendanceLoading();
}

class StaffAttendanceLoaded extends StaffAttendanceState {
  final StaffAttendancePeriod period;
  const StaffAttendanceLoaded(this.period);
  @override
  List<Object?> get props => [period];
}

class StaffAttendanceError extends StaffAttendanceState {
  final String message;
  const StaffAttendanceError(this.message);
  @override
  List<Object?> get props => [message];
}
