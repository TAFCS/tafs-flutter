import 'package:dio/dio.dart';
import '../../domain/entities/staff_payroll_summary.dart';
import '../../domain/repositories/staff_payroll_repository.dart';

class StaffPayrollRepositoryImpl implements StaffPayrollRepository {
  final Dio dio;

  StaffPayrollRepositoryImpl({required this.dio});

  @override
  Future<List<StaffPayrollSummary>> getMyPayrollList() async {
    final res = await dio.get('/hr/payroll/me');
    final list = _unwrapList(res.data);
    return list.map(_mapSummary).toList();
  }

  @override
  Future<StaffPayrollDetail> getMyPayrollDetail(int payrollRunId) async {
    final res = await dio.get('/hr/payroll/me/$payrollRunId');
    final json = _unwrapMap(res.data);
    return StaffPayrollDetail(
      payrollRunId: json['payroll_run_id'] as int? ?? payrollRunId,
      periodStart: _dateOnly(json['run']?['period_start'] ?? json['period_start']),
      periodEnd: _dateOnly(json['run']?['period_end'] ?? json['period_end']),
      runStatus: (json['run']?['status'] ?? json['status']) as String? ?? 'DRAFT',
      disbursedAt: json['disbursed_at'] != null
          ? DateTime.parse(json['disbursed_at'] as String)
          : null,
      disbursementNotes: json['disbursement_notes'] as String?,
      monthlyPay: (json['monthly_pay'] as num).toDouble(),
      totalDeductions: (json['total_deductions'] as num).toDouble(),
      netPay: (json['net_pay'] as num).toDouble(),
      presentDays: json['present_days'] as int? ?? 0,
      lateDays: json['late_days'] as int? ?? 0,
      absentDays: json['absent_days'] as int? ?? 0,
      halfDays: json['half_days'] as int? ?? 0,
      excusedDays: json['excused_days'] as int? ?? 0,
      unresolvedDays: json['unresolved_days'] as int? ?? 0,
      absenceDeduction: (json['absence_deduction'] as num?)?.toDouble() ?? 0,
      halfDayDeduction: (json['half_day_deduction'] as num?)?.toDouble() ?? 0,
      breakDeduction: (json['break_deduction'] as num?)?.toDouble() ?? 0,
      dailyRate: (json['daily_rate'] as num?)?.toDouble() ?? 0,
      perMinuteRate: (json['per_minute_rate'] as num?)?.toDouble() ?? 0,
      dailyBreakdown: (json['daily_breakdown'] as List? ?? [])
          .cast<Map<String, dynamic>>(),
    );
  }

  StaffPayrollSummary _mapSummary(Map<String, dynamic> json) {
    return StaffPayrollSummary(
      payrollRunId: json['payroll_run_id'] as int,
      periodStart: _dateOnly(json['period_start']),
      periodEnd: _dateOnly(json['period_end']),
      runStatus: json['run_status'] as String? ?? 'DRAFT',
      disbursedAt: json['disbursed_at'] != null
          ? DateTime.parse(json['disbursed_at'] as String)
          : null,
      disbursementNotes: json['disbursement_notes'] as String?,
      monthlyPay: (json['monthly_pay'] as num).toDouble(),
      totalDeductions: (json['total_deductions'] as num).toDouble(),
      netPay: (json['net_pay'] as num).toDouble(),
    );
  }

  List<Map<String, dynamic>> _unwrapList(dynamic raw) {
    final data = raw is Map ? raw['data'] ?? raw : raw;
    return (data as List).cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map && raw['data'] != null) return raw['data'] as Map<String, dynamic>;
    return raw as Map<String, dynamic>;
  }

  String _dateOnly(dynamic value) {
    final raw = value as String;
    return raw.contains('T') ? raw.split('T').first : raw;
  }
}
