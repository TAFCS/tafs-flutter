import 'package:equatable/equatable.dart';

abstract class FeeSummaryEvent extends Equatable {
  const FeeSummaryEvent();
  @override
  List<Object?> get props => [];
}

class FeeSummaryLoadRequested extends FeeSummaryEvent {
  final int studentCc;
  const FeeSummaryLoadRequested(this.studentCc);
  @override
  List<Object?> get props => [studentCc];
}
