import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_fee_summary_usecase.dart';
import 'fee_summary_event.dart';
import 'fee_summary_state.dart';

class FeeSummaryBloc extends Bloc<FeeSummaryEvent, FeeSummaryState> {
  final GetFeeSummaryUseCase getFeeSummary;

  FeeSummaryBloc({required this.getFeeSummary}) : super(FeeSummaryInitial()) {
    on<FeeSummaryLoadRequested>(_onLoad);
    on<FeeSummaryResetRequested>(_onReset);
  }

  Future<void> _onLoad(
    FeeSummaryLoadRequested event,
    Emitter<FeeSummaryState> emit,
  ) async {
    if (state is! FeeSummaryLoaded) {
      emit(FeeSummaryLoading());
    }

    final result = await getFeeSummary(event.studentCc);
    result.fold(
      (failure) => emit(FeeSummaryError(failure.message)),
      (summary) => emit(FeeSummaryLoaded(summary)),
    );
  }

  void _onReset(
    FeeSummaryResetRequested event,
    Emitter<FeeSummaryState> emit,
  ) {
    emit(FeeSummaryInitial());
  }
}
