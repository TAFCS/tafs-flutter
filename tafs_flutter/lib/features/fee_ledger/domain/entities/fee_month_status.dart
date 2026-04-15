import 'package:equatable/equatable.dart';

class FeeMonthStatus extends Equatable {
  final String academicYear;
  final int targetMonth;
  final String monthLabel;
  final double totalAmount;
  final double totalPaid;
  final double outstandingBalance;
  final double runningOutstandingBalance;
  final String status;
  final DateTime? feeDate;

  const FeeMonthStatus({
    required this.academicYear,
    required this.targetMonth,
    required this.monthLabel,
    required this.totalAmount,
    required this.totalPaid,
    required this.outstandingBalance,
    required this.runningOutstandingBalance,
    required this.status,
    this.feeDate,
  });

  @override
  List<Object?> get props => [
    academicYear,
    targetMonth,
    monthLabel,
    totalAmount,
    totalPaid,
    outstandingBalance,
    runningOutstandingBalance,
    status,
    feeDate,
  ];
}
