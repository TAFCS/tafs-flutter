import 'package:equatable/equatable.dart';

class FeeSummary extends Equatable {
  final String? academicYear;
  final double totalCharged;
  final double totalPaid;
  final double outstandingBalance;
  final bool hasOverdue;
  final int overdueCount;

  const FeeSummary({
    this.academicYear,
    required this.totalCharged,
    required this.totalPaid,
    required this.outstandingBalance,
    required this.hasOverdue,
    required this.overdueCount,
  });

  @override
  List<Object?> get props => [
        academicYear,
        totalCharged,
        totalPaid,
        outstandingBalance,
        hasOverdue,
        overdueCount,
      ];
}
