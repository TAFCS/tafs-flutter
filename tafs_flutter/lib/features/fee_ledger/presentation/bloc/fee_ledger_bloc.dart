import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_student_vouchers_usecase.dart';
import 'fee_ledger_event.dart';
import 'fee_ledger_state.dart';

class FeeLedgerBloc extends Bloc<FeeLedgerEvent, FeeLedgerState> {
  final GetStudentVouchersUseCase getStudentVouchers;

  FeeLedgerBloc({required this.getStudentVouchers}) : super(FeeLedgerInitial()) {
    on<FeeLedgerLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    FeeLedgerLoadRequested event,
    Emitter<FeeLedgerState> emit,
  ) async {
    emit(FeeLedgerLoading());
    final result = await getStudentVouchers(event.studentCc);
    result.fold(
      (failure) => emit(FeeLedgerError(failure.message)),
      (vouchers) => emit(FeeLedgerLoaded(vouchers)),
    );
  }
}
