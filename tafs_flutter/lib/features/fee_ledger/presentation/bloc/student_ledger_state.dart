import 'package:equatable/equatable.dart';
import '../../domain/entities/ledger.dart';
import '../../domain/entities/voucher.dart';

abstract class StudentLedgerState extends Equatable {
  const StudentLedgerState();

  @override
  List<Object?> get props => [];
}

class StudentLedgerInitial extends StudentLedgerState {
  const StudentLedgerInitial();
}

class StudentLedgerLoading extends StudentLedgerState {
  const StudentLedgerLoading();
}

class StudentLedgerLoaded extends StudentLedgerState {
  final Ledger ledger;
  final List<Voucher> vouchers;

  const StudentLedgerLoaded({required this.ledger, required this.vouchers});

  @override
  List<Object?> get props => [ledger, vouchers];
}

class StudentLedgerError extends StudentLedgerState {
  final String message;

  const StudentLedgerError(this.message);

  @override
  List<Object?> get props => [message];
}
