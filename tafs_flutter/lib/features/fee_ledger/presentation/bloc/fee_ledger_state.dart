import 'package:equatable/equatable.dart';
import '../../domain/entities/fee_month_status.dart';
import '../../domain/entities/ledger.dart';
import '../../domain/entities/voucher.dart';

abstract class FeeLedgerState extends Equatable {
  const FeeLedgerState();

  @override
  List<Object?> get props => [];
}

class FeeLedgerInitial extends FeeLedgerState {
  const FeeLedgerInitial();
}

class FeeLedgerLoading extends FeeLedgerState {
  const FeeLedgerLoading();
}

class FeeLedgerLoaded extends FeeLedgerState {
  final List<FeeMonthStatus> months;
  final List<Voucher> vouchers;
  const FeeLedgerLoaded({required this.months, required this.vouchers});

  @override
  List<Object?> get props => [months, vouchers];
}

class LedgerLoaded extends FeeLedgerState {
  final Ledger ledger;
  final List<Voucher> vouchers; // Keep vouchers for backward compatibility if needed
  const LedgerLoaded({required this.ledger, required this.vouchers});

  @override
  List<Object?> get props => [ledger, vouchers];
}

class FeeLedgerError extends FeeLedgerState {
  final String message;
  const FeeLedgerError(this.message);

  @override
  List<Object?> get props => [message];
}
