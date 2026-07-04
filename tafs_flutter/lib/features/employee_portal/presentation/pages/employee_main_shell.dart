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
import '../../../leave_requests/domain/repositories/leave_requests_repository.dart';
import '../../../support_tickets/staff/presentation/pages/staff_support_tickets_shell.dart';
import '../../../support_tickets/staff/support_ticket_staff_access.dart';
import '../../../../core/session/session_reset.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../data/employee_profile_repository.dart';
import '../../employee_portal_access.dart';
import 'employee_profile_page.dart';

enum _EmployeeTab { attendance, payroll, tickets, noticeBoard, employeeNoticeBoard, profile }

class EmployeeMainShell extends StatefulWidget {
  final StaffUser staff;

  const EmployeeMainShell({super.key, required this.staff});

  @override
  State<EmployeeMainShell> createState() => _EmployeeMainShellState();
}

class _EmployeeMainShellState extends State<EmployeeMainShell> {
  _EmployeeTab? _activeTab;
  List<_EmployeeTab> _currentTabs = [];

  StaffAttendanceRepositoryImpl? _attendanceRepo;
  StaffPayrollRepositoryImpl? _payrollRepo;
  LeaveRequestsRepository? _leaveRepo;
  EmployeeNoticeRepositoryImpl? _employeeNoticeRepo;
  late final EmployeeProfileRepository _profileRepo;
  List<Widget> _tabBodies = [];

  final _attendanceKey = GlobalKey<StaffAttendanceCalendarPageState>();
  final _payrollKey = GlobalKey<StaffPayrollListPageState>();

  String get _accessSignature => staffPortalAccessSignature(widget.staff);

  bool get _showAttendance => canViewOwnAttendance(widget.staff);
  bool get _showPayroll => canViewOwnPayroll(widget.staff);
  bool get _showLeave => canApplyLeave(widget.staff);
  bool get _showTickets => canViewSupportTickets(widget.staff);
  bool get _showNoticeBoard => canViewStaffNoticeBoard(widget.staff);
  bool get _showEmployeeNoticeBoard => canViewEmployeeNoticeBoard(widget.staff);
  bool get _showProfile => canViewEmployeeProfile(widget.staff);

  @override
  void initState() {
    super.initState();
    _profileRepo = EmployeeProfileRepository(dio: InjectionContainer.dio);
    _syncTabsFromStaff();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_showEmployeeNoticeBoard && isEmployeeSelfServiceRole(widget.staff)) {
        InjectionContainer.employeeNoticeCubit.load();
      }
    });
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
      if (_showLeave && _leaveRepo == null) {
        _leaveRepo = InjectionContainer.leaveRequestsRepository;
      }
      if (_showEmployeeNoticeBoard && _employeeNoticeRepo == null) {
        _employeeNoticeRepo = EmployeeNoticeRepositoryImpl(
          remoteDataSource: EmployeeNoticeRemoteDataSource(InjectionContainer.dio),
        );
      }
      // Compute tabs once and cache — _tabBodies must be built from the exact
      // same list so indices always match what the NavigationBar shows.
      _currentTabs = _buildTabs();
      _tabBodies = _buildTabBodies(_currentTabs);
      if (_currentTabs.isEmpty) {
        _activeTab = null;
      } else if (_activeTab == null || !_currentTabs.contains(_activeTab)) {
        _activeTab = _currentTabs.first;
      }
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }

  List<_EmployeeTab> _buildTabs() {
    final tabs = <_EmployeeTab>[];
    final isEmployee = isEmployeeSelfServiceRole(widget.staff);

    void addTabs() {
      if (_showEmployeeNoticeBoard) tabs.add(_EmployeeTab.employeeNoticeBoard);
      if (_showAttendance) tabs.add(_EmployeeTab.attendance);
      if (_showPayroll) tabs.add(_EmployeeTab.payroll);
      if (_showTickets) tabs.add(_EmployeeTab.tickets);
      if (_showNoticeBoard) tabs.add(_EmployeeTab.noticeBoard);
    }

    if (isEmployee) {
      addTabs();
    } else {
      // Home (employee notice board) always leftmost when present.
      if (_showEmployeeNoticeBoard) tabs.add(_EmployeeTab.employeeNoticeBoard);
      if (_showAttendance) tabs.add(_EmployeeTab.attendance);
      if (_showPayroll) tabs.add(_EmployeeTab.payroll);
      if (_showTickets) tabs.add(_EmployeeTab.tickets);
      if (_showNoticeBoard) tabs.add(_EmployeeTab.noticeBoard);
    }

    // Profile always rightmost.
    if (_showProfile) tabs.add(_EmployeeTab.profile);

    return tabs;
  }

  List<Widget> _buildTabBodies(List<_EmployeeTab> tabs) {
    final bodies = <Widget>[];
    for (final tab in tabs) {
      switch (tab) {
        case _EmployeeTab.employeeNoticeBoard:
          bodies.add(
            BlocProvider.value(
              key: const ValueKey('employee_notices_tab'),
              value: InjectionContainer.employeeNoticeCubit,
              child: EmployeeNoticeBoardPage(
                repository: _employeeNoticeRepo!,
              ),
            ),
          );
          break;
        case _EmployeeTab.attendance:
          bodies.add(
            StaffAttendanceCalendarPage(
              key: _attendanceKey,
              repository: _attendanceRepo!,
              leaveRepository: _leaveRepo,
            ),
          );
          break;
        case _EmployeeTab.payroll:
          bodies.add(
            StaffPayrollListPage(
              key: _payrollKey,
              repository: _payrollRepo!,
            ),
          );
          break;
        case _EmployeeTab.tickets:
          bodies.add(
            StaffSupportTicketsShell(
              key: ValueKey('employee_tickets_tab_$_accessSignature'),
              staff: widget.staff,
              embedded: true,
            ),
          );
          break;
        case _EmployeeTab.noticeBoard:
          bodies.add(
            const StaffNoticeBoardPage(
              key: ValueKey('employee_notice_tab'),
              loadOnMount: false,
            ),
          );
          break;
        case _EmployeeTab.profile:
          bodies.add(
            EmployeeProfilePage(
              key: const ValueKey('employee_profile_tab'),
              repository: _profileRepo,
              fallbackName: widget.staff.fullName,
              embedded: true,
            ),
          );
          break;
      }
    }
    return bodies;
  }

  String get _title {
    if (_currentTabs.isEmpty) return 'Staff';
    switch (_activeTab ?? _currentTabs.first) {
      case _EmployeeTab.attendance:
        return 'Attendance';
      case _EmployeeTab.payroll:
        return 'Payroll';
      case _EmployeeTab.tickets:
        return 'Support Tickets';
      case _EmployeeTab.noticeBoard:
        return 'Notice Board';
      case _EmployeeTab.employeeNoticeBoard:
        return 'Home';
      case _EmployeeTab.profile:
        return 'My Profile';
    }
  }

  NavigationDestination _destinationFor(_EmployeeTab tab) {
    switch (tab) {
      case _EmployeeTab.attendance:
        return const NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined, size: 20),
          selectedIcon: Icon(Icons.calendar_month, size: 20),
          label: 'Attendance',
        );
      case _EmployeeTab.payroll:
        return const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined, size: 20),
          selectedIcon: Icon(Icons.account_balance_wallet, size: 20),
          label: 'Payroll',
        );
      case _EmployeeTab.tickets:
        return const NavigationDestination(
          icon: Icon(Icons.confirmation_number_outlined, size: 20),
          selectedIcon: Icon(Icons.confirmation_number, size: 20),
          label: 'Tickets',
        );
      case _EmployeeTab.noticeBoard:
        return const NavigationDestination(
          icon: Icon(Icons.article_outlined, size: 20),
          selectedIcon: Icon(Icons.article, size: 20),
          label: 'Notices',
        );
      case _EmployeeTab.employeeNoticeBoard:
        return NavigationDestination(
          icon: BlocBuilder<EmployeeNoticeCubit, EmployeeNoticeState>(
            bloc: InjectionContainer.employeeNoticeCubit,
            builder: (_, s) => Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.home_outlined, size: 20),
                if (s.hasUnread)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          selectedIcon: const Icon(Icons.home, size: 20),
          label: 'Home',
        );
      case _EmployeeTab.profile:
        return const NavigationDestination(
          icon: Icon(Icons.person_outline, size: 20),
          selectedIcon: Icon(Icons.person, size: 20),
          label: 'Profile',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTabs.isEmpty) {
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

    final activeTab = _currentTabs.contains(_activeTab)
        ? _activeTab!
        : _currentTabs.first;
    final activeIndex = _currentTabs.indexOf(activeTab);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              resetStaffSessionState(context);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: activeIndex,
        children: _tabBodies,
      ),
      bottomNavigationBar: _currentTabs.length > 1
          ? NavigationBar(
              selectedIndex: activeIndex,
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              indicatorColor: Colors.transparent,
              backgroundColor: AppTheme.white,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              height: 64,
              onDestinationSelected: (index) {
                setState(() => _activeTab = _currentTabs[index]);
                if (_activeTab == _EmployeeTab.noticeBoard) {
                  context.read<StaffNoticeBoardCubit>().load();
                } else if (_activeTab == _EmployeeTab.employeeNoticeBoard) {
                  InjectionContainer.employeeNoticeCubit.load();
                }
              },
              destinations: _currentTabs.map(_destinationFor).toList(),
            )
          : null,
    );
  }
}
