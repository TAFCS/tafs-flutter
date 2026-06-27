import '../entities/staff_payroll_summary.dart';

abstract class StaffPayrollRepository {
  Future<List<StaffPayrollSummary>> getMyPayrollList();
  Future<StaffPayrollDetail> getMyPayrollDetail(int payrollRunId);
}
