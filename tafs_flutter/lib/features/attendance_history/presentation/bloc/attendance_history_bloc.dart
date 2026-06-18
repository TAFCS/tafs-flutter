import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../domain/repositories/attendance_history_repository.dart';
import 'attendance_history_event.dart';
import 'attendance_history_state.dart';

class AttendanceHistoryBloc extends Bloc<AttendanceHistoryEvent, AttendanceHistoryState> {
  final AttendanceHistoryRepository repository;

  AttendanceHistoryBloc({required this.repository}) : super(const AttendanceHistoryInitial()) {
    on<AttendanceHistoryLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    AttendanceHistoryLoadRequested event,
    Emitter<AttendanceHistoryState> emit,
  ) async {
    emit(const AttendanceHistoryLoading());
    try {
      final days = await repository.getAttendanceHistory(event.studentCc, event.month);
      emit(AttendanceHistoryLoaded(days: days, month: event.month));
    } catch (e) {
      emit(AttendanceHistoryError(message: ApiErrorMapper.fromObject(e)));
    }
  }
}
