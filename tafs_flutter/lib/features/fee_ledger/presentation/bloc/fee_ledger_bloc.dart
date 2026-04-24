import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/fee_month_status.dart';
import '../../domain/entities/voucher_resolution.dart';
import '../../domain/usecases/get_ledger_usecase.dart';
import '../../domain/usecases/get_student_fee_months_usecase.dart';
import '../../domain/usecases/resolve_voucher_for_month_usecase.dart';
import '../../domain/usecases/get_student_vouchers_usecase.dart';
import 'fee_ledger_event.dart';
import 'fee_ledger_state.dart';

class FeeLedgerBloc extends Bloc<FeeLedgerEvent, FeeLedgerState> {
  final GetStudentFeeMonthsUseCase getStudentFeeMonths;
  final GetStudentVouchersUseCase getStudentVouchers;
  final ResolveVoucherForMonthUseCase resolveVoucherForMonthUseCase;
  final GetLedgerUseCase getLedger;

  FeeLedgerBloc({
    required this.getStudentFeeMonths,
    required this.getStudentVouchers,
    required this.resolveVoucherForMonthUseCase,
    required this.getLedger,
  }) : super(FeeLedgerInitial()) {
    on<FeeLedgerLoadRequested>(_onLoad);
    on<LedgerLoadRequested>(_onLedgerLoad);
  }

  Future<void> _onLoad(
    FeeLedgerLoadRequested event,
    Emitter<FeeLedgerState> emit,
  ) async {
    emit(FeeLedgerLoading());
    final monthsResult = await getStudentFeeMonths(event.studentCc);

    String? monthsError;
    List<FeeMonthStatus> months = const [];
    monthsResult.fold(
      (failure) => monthsError = failure.message,
      (value) => months = value,
    );

    if (monthsError != null) {
      emit(FeeLedgerError(monthsError!));
      return;
    }

    final vouchersResult = await getStudentVouchers(event.studentCc);
    vouchersResult.fold(
      (_) => emit(FeeLedgerLoaded(months: months, vouchers: const [])),
      (vouchers) => emit(FeeLedgerLoaded(months: months, vouchers: vouchers)),
    );
  }

  Future<void> _onLedgerLoad(
    LedgerLoadRequested event,
    Emitter<FeeLedgerState> emit,
  ) async {
    emit(FeeLedgerLoading());
    
    // Fetch ledger and vouchers in parallel for responsiveness
    final results = await Future.wait([
      getLedger(event.studentCc),
      getStudentVouchers(event.studentCc),
    ]);

    final ledgerResult = results[0] as dynamic;
    final vouchersResult = results[1] as dynamic;

    ledgerResult.fold(
      (failure) => emit(FeeLedgerError(failure.message)),
      (ledger) {
        vouchersResult.fold(
          (_) => emit(LedgerLoaded(ledger: ledger, vouchers: const [])),
          (vouchers) => emit(LedgerLoaded(ledger: ledger, vouchers: vouchers)),
        );
      },
    );
  }

  Future<VoucherResolution> resolveVoucherForMonth({
    required int studentCc,
    required String academicYear,
    required int targetMonth,
  }) async {
    final result = await resolveVoucherForMonthUseCase(
      studentCc: studentCc,
      academicYear: academicYear,
      targetMonth: targetMonth,
    );

    return result.fold(
      (failure) => VoucherResolution(exists: false, message: failure.message),
      (value) => value,
    );
  }
}
