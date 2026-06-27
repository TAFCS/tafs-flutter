import 'package:equatable/equatable.dart';

abstract class StaffAttendanceEvent extends Equatable {
  const StaffAttendanceEvent();
  @override
  List<Object?> get props => [];
}

class StaffAttendanceLoadPeriod extends StaffAttendanceEvent {
  final String period;
  const StaffAttendanceLoadPeriod(this.period);
  @override
  List<Object?> get props => [period];
}
