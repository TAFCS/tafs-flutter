import 'package:equatable/equatable.dart';
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
  final List<Voucher> vouchers;
  const FeeLedgerLoaded(this.vouchers);

  @override
  List<Object?> get props => [vouchers];
}

class FeeLedgerError extends FeeLedgerState {
  final String message;
  const FeeLedgerError(this.message);

  @override
  List<Object?> get props => [message];
}
