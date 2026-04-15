import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/fee_month_status.dart';
import '../../domain/entities/voucher_resolution.dart';
import '../../domain/usecases/get_student_fee_months_usecase.dart';
import '../../domain/usecases/resolve_voucher_for_month_usecase.dart';
import '../../domain/usecases/get_student_vouchers_usecase.dart';
import 'fee_ledger_event.dart';
import 'fee_ledger_state.dart';

class FeeLedgerBloc extends Bloc<FeeLedgerEvent, FeeLedgerState> {
  final GetStudentFeeMonthsUseCase getStudentFeeMonths;
  final GetStudentVouchersUseCase getStudentVouchers;
  final ResolveVoucherForMonthUseCase resolveVoucherForMonthUseCase;

  FeeLedgerBloc({
    required this.getStudentFeeMonths,
    required this.getStudentVouchers,
    required this.resolveVoucherForMonthUseCase,
  }) : super(FeeLedgerInitial()) {
    on<FeeLedgerLoadRequested>(_onLoad);
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
