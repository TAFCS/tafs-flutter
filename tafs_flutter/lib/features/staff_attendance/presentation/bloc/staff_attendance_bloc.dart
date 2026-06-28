import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import 'staff_attendance_event.dart';
import 'staff_attendance_state.dart';

class StaffAttendanceBloc extends Bloc<StaffAttendanceEvent, StaffAttendanceState> {
  final StaffAttendanceRepository repository;

  StaffAttendanceBloc({required this.repository}) : super(const StaffAttendanceInitial()) {
    on<StaffAttendanceLoadPeriod>(_onLoad);
  }

  Future<void> _onLoad(
    StaffAttendanceLoadPeriod event,
    Emitter<StaffAttendanceState> emit,
  ) async {
    emit(const StaffAttendanceLoading());
    try {
      final period = await repository.getMyAttendance(event.period);
      emit(StaffAttendanceLoaded(period));
    } catch (e) {
      emit(StaffAttendanceError(
        ApiErrorMapper.staffSelfServiceMessage(e, featureLabel: 'attendance'),
      ));
    }
  }
}
