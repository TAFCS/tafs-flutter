import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../staff_attendance/presentation/utils/payroll_period_utils.dart';
import '../../domain/repositories/staff_payroll_repository.dart';
import '../bloc/staff_payroll_bloc.dart';
import 'staff_payroll_detail_page.dart';

class StaffPayrollListPage extends StatefulWidget {
  final StaffPayrollRepository repository;

  const StaffPayrollListPage({super.key, required this.repository});

  @override
  State<StaffPayrollListPage> createState() => _StaffPayrollListPageState();
}

class _StaffPayrollListPageState extends State<StaffPayrollListPage> {
  late final StaffPayrollBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = StaffPayrollBloc(repository: widget.repository)
      ..add(StaffPayrollLoadRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  String _fmtPkr(double v) => 'PKR ${NumberFormat('#,##0.00').format(v)}';

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<StaffPayrollBloc, StaffPayrollState>(
        builder: (context, state) {
          if (state is StaffPayrollLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StaffPayrollError) {
            return Center(child: Text(state.message));
          }
          if (state is! StaffPayrollLoaded) {
            return const SizedBox.shrink();
          }

          final finalized = state.items.where((i) => i.runStatus == 'FINALIZED');
          final totalNet = finalized.fold<double>(0, (s, i) => s + i.netPay);
          final totalDisbursed = finalized
              .where((i) => i.disbursedAt != null)
              .fold<double>(0, (s, i) => s + i.netPay);
          final balance = totalNet - totalDisbursed;

          if (state.items.isEmpty) {
            return const Center(child: Text('No payroll records yet.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _bloc.add(StaffPayrollLoadRequested()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Balance owed', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                      Text(
                        _fmtPkr(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Finalized net: ${_fmtPkr(totalNet)} • Disbursed: ${_fmtPkr(totalDisbursed)}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...state.items.map((item) {
                  final start = DateTime.parse('${item.periodStart}T00:00:00Z');
                  final end = DateTime.parse('${item.periodEnd}T00:00:00Z');
                  return Card(
                    child: ListTile(
                      title: Text(formatPayrollPeriodRange(start, end)),
                      subtitle: Text(_fmtPkr(item.netPay)),
                      trailing: Chip(label: Text(item.displayStatus)),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StaffPayrollDetailPage(
                              payrollRunId: item.payrollRunId,
                              repository: widget.repository,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
