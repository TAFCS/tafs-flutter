import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../domain/entities/staff_payroll_summary.dart';
import '../../domain/repositories/staff_payroll_repository.dart';

abstract class StaffPayrollEvent {}

class StaffPayrollLoadRequested extends StaffPayrollEvent {}

abstract class StaffPayrollState {}

class StaffPayrollInitial extends StaffPayrollState {}

class StaffPayrollLoading extends StaffPayrollState {}

class StaffPayrollLoaded extends StaffPayrollState {
  final List<StaffPayrollSummary> items;
  StaffPayrollLoaded(this.items);
}

class StaffPayrollError extends StaffPayrollState {
  final String message;
  StaffPayrollError(this.message);
}

class StaffPayrollBloc extends Bloc<StaffPayrollEvent, StaffPayrollState> {
  final StaffPayrollRepository repository;

  StaffPayrollBloc({required this.repository}) : super(StaffPayrollInitial()) {
    on<StaffPayrollLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    StaffPayrollLoadRequested event,
    Emitter<StaffPayrollState> emit,
  ) async {
    emit(StaffPayrollLoading());
    try {
      final items = await repository.getMyPayrollList();
      emit(StaffPayrollLoaded(items));
    } catch (e) {
      emit(StaffPayrollError(ApiErrorMapper.fromObject(e)));
    }
  }
}
