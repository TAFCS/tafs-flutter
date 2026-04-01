import 'package:equatable/equatable.dart';

abstract class FeeLedgerEvent extends Equatable {
  const FeeLedgerEvent();

  @override
  List<Object?> get props => [];
}

class FeeLedgerLoadRequested extends FeeLedgerEvent {
  final int studentCc;
  const FeeLedgerLoadRequested(this.studentCc);

  @override
  List<Object?> get props => [studentCc];
}
