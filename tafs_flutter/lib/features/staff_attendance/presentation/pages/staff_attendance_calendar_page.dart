import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../bloc/staff_attendance_bloc.dart';
import '../bloc/staff_attendance_event.dart';
import '../bloc/staff_attendance_state.dart';
import '../utils/payroll_period_utils.dart';
import '../widgets/payroll_period_calendar.dart';
import 'my_objections_page.dart';
import 'staff_day_detail_page.dart';

class StaffAttendanceCalendarPage extends StatefulWidget {
  final StaffAttendanceRepository repository;

  const StaffAttendanceCalendarPage({super.key, required this.repository});

  @override
  State<StaffAttendanceCalendarPage> createState() =>
      _StaffAttendanceCalendarPageState();
}

class _StaffAttendanceCalendarPageState extends State<StaffAttendanceCalendarPage> {
  late String _period;
  late final StaffAttendanceBloc _bloc;

  @override
  void initState() {
    super.initState();
    _period = currentPayrollPeriodLabel();
    _bloc = StaffAttendanceBloc(repository: widget.repository)
      ..add(StaffAttendanceLoadPeriod(_period));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _load() => _bloc.add(StaffAttendanceLoadPeriod(_period));

  void _shift(int delta) {
    final next = shiftPayrollPeriod(_period, delta);
    final max = currentPayrollPeriodLabel();
    if (next.compareTo(max) > 0) return;
    setState(() => _period = next);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<StaffAttendanceBloc, StaffAttendanceState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _shift(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        state is StaffAttendanceLoaded
                            ? formatPayrollPeriodRange(
                                state.period.periodStart,
                                state.period.periodEnd,
                              )
                            : _period,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.navy,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _shift(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'objections') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MyObjectionsPage(
                                repository: widget.repository,
                              ),
                            ),
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'objections',
                          child: Text('My Objections'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state is StaffAttendanceLoading)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state is StaffAttendanceError)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(state.message, textAlign: TextAlign.center),
                  )
                else if (state is StaffAttendanceLoaded)
                  PayrollPeriodCalendar(
                    days: state.period.days,
                    onDayTap: (day) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StaffDayDetailPage(
                            day: day,
                            payrollSnapshot: state.period.payrollSnapshot,
                            repository: widget.repository,
                            onObjectionSubmitted: _load,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
