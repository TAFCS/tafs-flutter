import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/entities/staff_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../notice_board/staff/presentation/bloc/staff_notice_board_cubit.dart';
import '../../../notice_board/staff/presentation/pages/staff_notice_board_page.dart';
import '../../../notice_board/staff/staff_notice_board_access.dart';
import '../../../employee_notice_board/presentation/cubit/employee_notice_cubit.dart';
import '../../../employee_notice_board/presentation/pages/employee_notice_board_page.dart';
import '../../../employee_notice_board/employee_notice_access.dart';
import '../../../employee_notice_board/data/repositories/employee_notice_repository_impl.dart';
import '../../../employee_notice_board/data/datasources/employee_notice_remote_data_source.dart';
import '../../../staff_attendance/data/repositories/staff_attendance_repository_impl.dart';
import '../../../staff_attendance/presentation/pages/staff_attendance_calendar_page.dart';
import '../../../staff_payroll/data/repositories/staff_payroll_repository_impl.dart';
import '../../../staff_payroll/presentation/pages/staff_payroll_list_page.dart';
import '../../../support_tickets/staff/presentation/bloc/staff_pending_approvals_cubit.dart';
import '../../../support_tickets/staff/presentation/bloc/staff_ticket_queue_bloc.dart';
import '../../../support_tickets/staff/presentation/pages/staff_support_tickets_shell.dart';
import '../../../support_tickets/staff/support_ticket_staff_access.dart';
import '../../../../core/session/session_reset.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../employee_portal_access.dart';

enum _EmployeeTab { attendance, payroll, tickets, noticeBoard, employeeNoticeBoard }

class EmployeeMainShell extends StatefulWidget {
  final StaffUser staff;

  const EmployeeMainShell({super.key, required this.staff});

  @override
  State<EmployeeMainShell> createState() => _EmployeeMainShellState();
}

class _EmployeeMainShellState extends State<EmployeeMainShell> {
  _EmployeeTab? _activeTab;

  StaffAttendanceRepositoryImpl? _attendanceRepo;
  StaffPayrollRepositoryImpl? _payrollRepo;
  EmployeeNoticeRepositoryImpl? _employeeNoticeRepo;
  late List<Widget> _tabBodies;

  final _attendanceKey = GlobalKey<StaffAttendanceCalendarPageState>();
  final _payrollKey = GlobalKey<StaffPayrollListPageState>();

  String get _accessSignature => staffPortalAccessSignature(widget.staff);

  bool get _showAttendance => canViewOwnAttendance(widget.staff);
  bool get _showPayroll => canViewOwnPayroll(widget.staff);
  bool get _showTickets => canViewSupportTickets(widget.staff);
  bool get _showNoticeBoard => canViewStaffNoticeBoard(widget.staff);
  bool get _showEmployeeNoticeBoard => canViewEmployeeNoticeBoard(widget.staff);

  @override
  void initState() {
    super.initState();
    _syncTabsFromStaff();
  }

  @override
  void didUpdateWidget(EmployeeMainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (staffPortalAccessSignature(oldWidget.staff) != _accessSignature) {
      _syncTabsFromStaff(notify: true);
    }
  }

  void _syncTabsFromStaff({bool notify = false}) {
    void apply() {
      if (_showAttendance && _attendanceRepo == null) {
        _attendanceRepo = StaffAttendanceRepositoryImpl(
          remote: StaffAttendanceRemoteDataSource(InjectionContainer.dio),
        );
      }
      if (_showPayroll && _payrollRepo == null) {
        _payrollRepo = StaffPayrollRepositoryImpl(dio: InjectionContainer.dio);
      }
      if (_showEmployeeNoticeBoard && _employeeNoticeRepo == null) {
        _employeeNoticeRepo = EmployeeNoticeRepositoryImpl(
          remoteDataSource: EmployeeNoticeRemoteDataSource(InjectionContainer.dio),
        );
      }
      _tabBodies = _buildTabBodies();
      final tabs = _tabs;
      if (tabs.isEmpty) {
        _activeTab = null;
      } else if (_activeTab == null || !tabs.contains(_activeTab)) {
        _activeTab = tabs.first;
      }
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }

  List<_EmployeeTab> get _tabs {
    final tabs = <_EmployeeTab>[];
    if (_showAttendance) tabs.add(_EmployeeTab.attendance);
    if (_showPayroll) tabs.add(_EmployeeTab.payroll);
    if (_showTickets) tabs.add(_EmployeeTab.tickets);
    if (_showNoticeBoard) tabs.add(_EmployeeTab.noticeBoard);
    if (_showEmployeeNoticeBoard) tabs.add(_EmployeeTab.employeeNoticeBoard);
    return tabs;
  }

  List<Widget> _buildTabBodies() {
    final bodies = <Widget>[];
    if (_showAttendance && _attendanceRepo != null) {
      bodies.add(
        StaffAttendanceCalendarPage(
          key: _attendanceKey,
          repository: _attendanceRepo!,
        ),
      );
    }
    if (_showPayroll && _payrollRepo != null) {
      bodies.add(
        StaffPayrollListPage(
          key: _payrollKey,
          repository: _payrollRepo!,
        ),
      );
    }
    if (_showTickets) {
      bodies.add(
        StaffSupportTicketsShell(
          key: ValueKey('employee_tickets_tab_$_accessSignature'),
          staff: widget.staff,
          embedded: true,
        ),
      );
    }
    if (_showNoticeBoard) {
      bodies.add(
        const StaffNoticeBoardPage(
          key: ValueKey('employee_notice_tab'),
          loadOnMount: false,
        ),
      );
    }
    if (_showEmployeeNoticeBoard && _employeeNoticeRepo != null) {
      bodies.add(
        BlocProvider.value(
          key: const ValueKey('employee_notices_tab'),
          value: InjectionContainer.employeeNoticeCubit,
          child: EmployeeNoticeBoardPage(
            repository: _employeeNoticeRepo!,
          ),
        ),
      );
    }
    return bodies;
  }

  void _refreshActiveTab() {
    final activeTab = _activeTab;
    if (activeTab == null) return;
    switch (activeTab) {
      case _EmployeeTab.tickets:
        if (_showTickets) {
          context.read<StaffTicketQueueBloc>().add(StaffQueueRefreshRequested());
          if (widget.staff.role == 'SUPER_ADMIN') {
            context.read<StaffPendingApprovalsCubit>().load();
          }
        }
        break;
      case _EmployeeTab.noticeBoard:
        if (_showNoticeBoard) context.read<StaffNoticeBoardCubit>().refresh();
        break;
      case _EmployeeTab.employeeNoticeBoard:
        if (_showEmployeeNoticeBoard) InjectionContainer.employeeNoticeCubit.refresh();
        break;
      case _EmployeeTab.attendance:
        _attendanceKey.currentState?.refresh();
        break;
      case _EmployeeTab.payroll:
        _payrollKey.currentState?.refresh();
        break;
    }
  }

  String get _title {
    final tabs = _tabs;
    if (tabs.isEmpty) return 'Staff';
    switch (_activeTab ?? tabs.first) {
      case _EmployeeTab.attendance:
        return 'Attendance';
      case _EmployeeTab.payroll:
        return 'Payroll';
      case _EmployeeTab.tickets:
        return 'Support Tickets';
      case _EmployeeTab.noticeBoard:
        return 'Notice Board';
      case _EmployeeTab.employeeNoticeBoard:
        return 'Notices';
    }
  }

  NavigationDestination _destinationFor(_EmployeeTab tab) {
    switch (tab) {
      case _EmployeeTab.attendance:
        return const NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Attendance',
        );
      case _EmployeeTab.payroll:
        return const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Payroll',
        );
      case _EmployeeTab.tickets:
        return const NavigationDestination(
          icon: Icon(Icons.confirmation_number_outlined),
          selectedIcon: Icon(Icons.confirmation_number),
          label: 'Tickets',
        );
      case _EmployeeTab.noticeBoard:
        return const NavigationDestination(
          icon: Icon(Icons.article_outlined),
          selectedIcon: Icon(Icons.article),
          label: 'Notices',
        );
      case _EmployeeTab.employeeNoticeBoard:
        return NavigationDestination(
          icon: BlocBuilder<EmployeeNoticeCubit, EmployeeNoticeState>(
            bloc: InjectionContainer.employeeNoticeCubit,
            builder: (_, s) => Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.campaign_outlined),
                if (s.hasUnread)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          selectedIcon: const Icon(Icons.campaign),
          label: 'Notices',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Staff'),
          backgroundColor: AppTheme.white,
          foregroundColor: AppTheme.navy,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                resetStaffSessionState(context);
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
          ],
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No mobile features are available for your account.\n'
              'Ask HR to link your employee profile and grant self-service permissions.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final tabs = _tabs;
    final activeTab = tabs.contains(_activeTab) ? _activeTab! : tabs.first;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshActiveTab),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              resetStaffSessionState(context);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: tabs.indexOf(activeTab),
        children: _tabBodies,
      ),
      bottomNavigationBar: tabs.length > 1
          ? NavigationBar(
              selectedIndex: tabs.indexOf(activeTab),
              onDestinationSelected: (index) {
                setState(() => _activeTab = tabs[index]);
                if (_activeTab == _EmployeeTab.noticeBoard) {
                  context.read<StaffNoticeBoardCubit>().load();
                } else if (_activeTab == _EmployeeTab.employeeNoticeBoard) {
                  InjectionContainer.employeeNoticeCubit.load();
                }
              },
              destinations: tabs.map(_destinationFor).toList(),
            )
          : null,
    );
  }
}
