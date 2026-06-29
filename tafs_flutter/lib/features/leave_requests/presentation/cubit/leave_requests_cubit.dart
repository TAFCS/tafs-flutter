import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/repositories/leave_requests_repository.dart';

// ── States ───────────────────────────────────────────────────────────────────

abstract class LeaveRequestsState extends Equatable {
  const LeaveRequestsState();

  @override
  List<Object?> get props => [];
}

class LeaveRequestsInitial extends LeaveRequestsState {}

class LeaveRequestsLoading extends LeaveRequestsState {}

class LeaveRequestsLoaded extends LeaveRequestsState {
  final List<LeaveRequest> items;

  const LeaveRequestsLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class LeaveRequestsError extends LeaveRequestsState {
  final String message;

  const LeaveRequestsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Cubit ────────────────────────────────────────────────────────────────────

class LeaveRequestsCubit extends Cubit<LeaveRequestsState> {
  final LeaveRequestsRepository repository;

  LeaveRequestsCubit({required this.repository}) : super(LeaveRequestsInitial());

  Future<void> load() async {
    emit(LeaveRequestsLoading());
    try {
      final items = await repository.getMyRequests();
      emit(LeaveRequestsLoaded(items));
    } catch (e) {
      emit(LeaveRequestsError(ApiErrorMapper.fromObject(e)));
    }
  }

  Future<String?> cancel(int id) async {
    final previous = state;
    try {
      await repository.cancelRequest(id);
      await load();
      return null;
    } catch (e) {
      if (previous is LeaveRequestsLoaded) {
        emit(previous);
      }
      return ApiErrorMapper.fromObject(e);
    }
  }
}
