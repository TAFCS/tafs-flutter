import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_ledger_usecase.dart';
import '../../domain/usecases/get_student_vouchers_usecase.dart';
import 'student_ledger_event.dart';
import 'student_ledger_state.dart';

class StudentLedgerBloc extends Bloc<StudentLedgerEvent, StudentLedgerState> {
  final GetLedgerUseCase getLedger;
  final GetStudentVouchersUseCase getStudentVouchers;

  StudentLedgerBloc({
    required this.getLedger,
    required this.getStudentVouchers,
  }) : super(const StudentLedgerInitial()) {
    on<StudentLedgerLoadRequested>(_onLoad);
    on<StudentLedgerResetRequested>(_onReset);
  }

  Future<void> _onLoad(
    StudentLedgerLoadRequested event,
    Emitter<StudentLedgerState> emit,
  ) async {
    emit(const StudentLedgerLoading());

    final ledgerResult = await getLedger(event.studentCc);
    final vouchersResult = await getStudentVouchers(event.studentCc);

    ledgerResult.fold(
      (failure) => emit(StudentLedgerError(failure.message)),
      (ledger) {
        vouchersResult.fold(
          (_) => emit(StudentLedgerLoaded(ledger: ledger, vouchers: const [])),
          (vouchers) =>
              emit(StudentLedgerLoaded(ledger: ledger, vouchers: vouchers)),
        );
      },
    );
  }

  void _onReset(
    StudentLedgerResetRequested event,
    Emitter<StudentLedgerState> emit,
  ) {
    emit(const StudentLedgerInitial());
  }
}
