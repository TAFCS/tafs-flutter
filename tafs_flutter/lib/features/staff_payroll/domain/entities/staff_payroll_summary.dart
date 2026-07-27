class StaffPayrollSettlement {
  final String? overtimeRateType;
  final double? overtimeRateAmount;
  final int overtimeMinutes;
  final double overtimeRewardAmount;
  final double netPaid;
  final String? payslipPdfUrl;
  final DateTime settledAt;

  const StaffPayrollSettlement({
    this.overtimeRateType,
    this.overtimeRateAmount,
    required this.overtimeMinutes,
    required this.overtimeRewardAmount,
    required this.netPaid,
    this.payslipPdfUrl,
    required this.settledAt,
  });
}

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
  final int overtimeDays;
  final StaffPayrollSettlement? settlement;

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
    this.overtimeDays = 0,
    this.settlement,
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
  final int totalLateMinutes;
  final double absenceDeduction;
  final double halfDayDeduction;
  final double lateDeduction;
  final double breakDeduction;
  final double sandwichDeduction;
  final double consecutiveLateDeduction;
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
    super.overtimeDays,
    super.settlement,
    required this.presentDays,
    required this.lateDays,
    required this.absentDays,
    required this.halfDays,
    required this.excusedDays,
    required this.unresolvedDays,
    required this.totalLateMinutes,
    required this.absenceDeduction,
    required this.halfDayDeduction,
    required this.lateDeduction,
    required this.breakDeduction,
    required this.sandwichDeduction,
    required this.consecutiveLateDeduction,
    required this.dailyRate,
    required this.perMinuteRate,
    required this.dailyBreakdown,
  });

  /// Plain-English breakdown of every deduction actually applied this
  /// period — each entry pairs a label an employee can understand with the
  /// amount taken off. Zero-amount deductions are omitted.
  List<MapEntry<String, double>> get deductionExplanations {
    final entries = <MapEntry<String, double>>[
      MapEntry('Absence (days marked absent or unpaid leave)', absenceDeduction),
      MapEntry('Half-day attendance', halfDayDeduction),
      MapEntry('Late arrivals beyond the grace period', lateDeduction),
      MapEntry('Break time beyond work hours', breakDeduction),
      MapEntry('Off-day pay (absent the working day before & after this break)', sandwichDeduction),
      MapEntry("Late attendance (3 consecutive late days = 1 day's pay)", consecutiveLateDeduction),
    ];
    return entries.where((e) => e.value > 0).toList();
  }
}
