class StaffPayrollSummary {
  final int payrollRunId;
  final String periodStart;
  final String periodEnd;
  final String runStatus;
  final DateTime? disbursedAt;
  final String? disbursementNotes;
  final double monthlyPay;
  final double totalDeductions;
  final double netPay;

  const StaffPayrollSummary({
    required this.payrollRunId,
    required this.periodStart,
    required this.periodEnd,
    required this.runStatus,
    this.disbursedAt,
    this.disbursementNotes,
    required this.monthlyPay,
    required this.totalDeductions,
    required this.netPay,
  });

  String get displayStatus {
    if (disbursedAt != null) return 'DISBURSED';
    return runStatus;
  }
}

class StaffPayrollDetail extends StaffPayrollSummary {
  final int presentDays;
  final int lateDays;
  final int absentDays;
  final int halfDays;
  final int excusedDays;
  final int unresolvedDays;
  final double absenceDeduction;
  final double halfDayDeduction;
  final double breakDeduction;
  final double dailyRate;
  final double perMinuteRate;
  final List<Map<String, dynamic>> dailyBreakdown;

  const StaffPayrollDetail({
    required super.payrollRunId,
    required super.periodStart,
    required super.periodEnd,
    required super.runStatus,
    super.disbursedAt,
    super.disbursementNotes,
    required super.monthlyPay,
    required super.totalDeductions,
    required super.netPay,
    required this.presentDays,
    required this.lateDays,
    required this.absentDays,
    required this.halfDays,
    required this.excusedDays,
    required this.unresolvedDays,
    required this.absenceDeduction,
    required this.halfDayDeduction,
    required this.breakDeduction,
    required this.dailyRate,
    required this.perMinuteRate,
    required this.dailyBreakdown,
  });
}
