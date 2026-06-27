class StaffScan {
  final int id;
  final DateTime scanTime;
  final String? direction;

  const StaffScan({
    required this.id,
    required this.scanTime,
    this.direction,
  });
}

class StaffObjectionSummary {
  final int id;
  final int? scanId;
  final DateTime claimedTime;
  final String status;

  const StaffObjectionSummary({
    required this.id,
    this.scanId,
    required this.claimedTime,
    required this.status,
  });
}

class StaffDayEntry {
  final DateTime date;
  final String? status;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final List<StaffScan> scans;
  final bool isWorkingDay;
  final String? dayType;
  final List<StaffObjectionSummary> objections;

  const StaffDayEntry({
    required this.date,
    this.status,
    this.checkInAt,
    this.checkOutAt,
    required this.scans,
    required this.isWorkingDay,
    this.dayType,
    required this.objections,
  });
}

class StaffPayrollSnapshot {
  final String status;
  final DateTime? disbursedAt;
  final String? disbursementNotes;
  final double dailyRate;
  final double perMinuteRate;
  final List<Map<String, dynamic>> dailyBreakdown;

  const StaffPayrollSnapshot({
    required this.status,
    this.disbursedAt,
    this.disbursementNotes,
    required this.dailyRate,
    required this.perMinuteRate,
    required this.dailyBreakdown,
  });
}

class StaffAttendancePeriod {
  final String period;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<StaffDayEntry> days;
  final StaffPayrollSnapshot? payrollSnapshot;

  const StaffAttendancePeriod({
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.days,
    this.payrollSnapshot,
  });
}
