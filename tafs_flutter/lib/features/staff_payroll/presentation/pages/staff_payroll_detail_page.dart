import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../staff_attendance/presentation/utils/payroll_period_utils.dart';
import '../../domain/repositories/staff_payroll_repository.dart';

class StaffPayrollDetailPage extends StatefulWidget {
  final int payrollRunId;
  final StaffPayrollRepository repository;

  const StaffPayrollDetailPage({
    super.key,
    required this.payrollRunId,
    required this.repository,
  });

  @override
  State<StaffPayrollDetailPage> createState() => _StaffPayrollDetailPageState();
}

class _StaffPayrollDetailPageState extends State<StaffPayrollDetailPage> {
  bool _loading = true;
  String? _error;
  dynamic _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await widget.repository.getMyPayrollDetail(widget.payrollRunId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _fmtPkr(double v) => 'PKR ${NumberFormat('#,##0.00').format(v)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payslip Detail'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _detail;
    final start = DateTime.parse('${d.periodStart}T00:00:00Z');
    final end = DateTime.parse('${d.periodEnd}T00:00:00Z');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          formatPayrollPeriodRange(start, end),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text('Status: ${d.displayStatus}'),
        if (d.disbursedAt != null)
          Text('Disbursed: ${DateFormat.yMMMd().format(d.disbursedAt!.toLocal())}'),
        const Divider(height: 32),
        _row('Monthly Pay (Base)', _fmtPkr(d.monthlyPay)),
        _row('− Absence Deduction', _fmtPkr(d.absenceDeduction)),
        _row('− Half-Day Deduction', _fmtPkr(d.halfDayDeduction)),
        _row('− Break Deduction', _fmtPkr(d.breakDeduction)),
        const Divider(),
        _row('Net Pay', _fmtPkr(d.netPay), bold: true),
        const SizedBox(height: 16),
        Text(
          'Present ${d.presentDays} • Late ${d.lateDays} • Absent ${d.absentDays} • '
          'Half ${d.halfDays} • Excused ${d.excusedDays}',
        ),
        const SizedBox(height: 16),
        ExpansionTile(
          title: const Text('Day-by-day breakdown'),
          children: d.dailyBreakdown.map<Widget>((row) {
            return ListTile(
              dense: true,
              title: Text('${row['date']} — ${row['classification']}'),
              subtitle: Text('Break: ${row['break_minutes'] ?? 0} min'),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
