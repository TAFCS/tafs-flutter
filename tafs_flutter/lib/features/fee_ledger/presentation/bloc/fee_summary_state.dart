import 'package:equatable/equatable.dart';
import '../../domain/entities/fee_summary.dart';

abstract class FeeSummaryState extends Equatable {
  const FeeSummaryState();
  @override
  List<Object?> get props => [];
}

class FeeSummaryInitial extends FeeSummaryState {}
class FeeSummaryLoading extends FeeSummaryState {}
class FeeSummaryLoaded extends FeeSummaryState {
  final FeeSummary summary;
  const FeeSummaryLoaded(this.summary);
  @override
  List<Object?> get props => [summary];
}
class FeeSummaryError extends FeeSummaryState {
  final String message;
  const FeeSummaryError(this.message);
  @override
  List<Object?> get props => [message];
}
