import 'package:equatable/equatable.dart';

abstract class StudentLedgerEvent extends Equatable {
  const StudentLedgerEvent();

  @override
  List<Object?> get props => [];
}

class StudentLedgerLoadRequested extends StudentLedgerEvent {
  final int studentCc;

  const StudentLedgerLoadRequested(this.studentCc);

  @override
  List<Object?> get props => [studentCc];
}

class StudentLedgerResetRequested extends StudentLedgerEvent {
  const StudentLedgerResetRequested();
}
