import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/staff_support_ticket.dart';
import '../../domain/repositories/staff_support_ticket_repository.dart';

class StaffPendingApprovalsState {
  final List<PendingApproval> items;
  final bool loading;
  final String? error;

  const StaffPendingApprovalsState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  StaffPendingApprovalsState copyWith({
    List<PendingApproval>? items,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      StaffPendingApprovalsState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

class StaffPendingApprovalsCubit extends Cubit<StaffPendingApprovalsState> {
  final StaffSupportTicketRepository repository;
  StreamSubscription<void>? _approvalSub;

  StaffPendingApprovalsCubit({required this.repository})
      : super(const StaffPendingApprovalsState());

  void startListening() {
    _approvalSub ??= repository.onReplyPendingApproval.listen((_) => load());
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final items = await repository.fetchPendingApprovals();
      emit(state.copyWith(items: items, loading: false));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: 'Failed to load approvals.',
      ));
    }
  }

  void reset() {
    _approvalSub?.cancel();
    _approvalSub = null;
    emit(const StaffPendingApprovalsState());
  }

  @override
  Future<void> close() {
    _approvalSub?.cancel();
    return super.close();
  }
}
