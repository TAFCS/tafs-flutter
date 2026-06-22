import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../auth/domain/entities/staff_user.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../../notice_board/staff/presentation/bloc/staff_notice_board_cubit.dart';
import '../../../../notice_board/staff/presentation/pages/staff_notice_board_page.dart';
import '../../../../notice_board/staff/staff_notice_board_access.dart';
import '../../../../../core/session/session_reset.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../support_ticket_staff_access.dart';
import '../bloc/staff_pending_approvals_cubit.dart';
import '../bloc/staff_ticket_queue_bloc.dart';
import 'staff_support_tickets_shell.dart';

enum _StaffTab { tickets, noticeBoard }

class StaffMainShell extends StatefulWidget {
  final StaffUser staff;

  const StaffMainShell({super.key, required this.staff});

  @override
  State<StaffMainShell> createState() => _StaffMainShellState();
}

class _StaffMainShellState extends State<StaffMainShell> {
  _StaffTab _activeTab = _StaffTab.tickets;

  bool get _showTickets => canViewSupportTickets(widget.staff);
  bool get _showNoticeBoard => canViewStaffNoticeBoard(widget.staff);

  @override
  void initState() {
    super.initState();
    if (!_showTickets && _showNoticeBoard) {
      _activeTab = _StaffTab.noticeBoard;
    }
  }

  void _refreshActiveTab() {
    if (_activeTab == _StaffTab.tickets && _showTickets) {
      context.read<StaffTicketQueueBloc>().add(StaffQueueRefreshRequested());
      if (widget.staff.role == 'SUPER_ADMIN') {
        context.read<StaffPendingApprovalsCubit>().load();
      }
    } else if (_activeTab == _StaffTab.noticeBoard && _showNoticeBoard) {
      context.read<StaffNoticeBoardCubit>().refresh();
    }
  }

  Widget _buildBody() {
    if (_showTickets && _showNoticeBoard) {
      return IndexedStack(
        index: _activeTab == _StaffTab.tickets ? 0 : 1,
        children: [
          StaffSupportTicketsShell(staff: widget.staff, embedded: true),
          const StaffNoticeBoardPage(loadOnMount: false),
        ],
      );
    }
    if (_showTickets) {
      return StaffSupportTicketsShell(staff: widget.staff, embedded: true);
    }
    if (_showNoticeBoard) {
      return const StaffNoticeBoardPage(loadOnMount: true);
    }
    return const SizedBox.shrink();
  }

  String get _title {
    if (!_showTickets && _showNoticeBoard) return 'Notice Board';
    if (_showTickets && !_showNoticeBoard) return 'Support Tickets';
    return _activeTab == _StaffTab.tickets
        ? 'Support Tickets'
        : 'Notice Board';
  }

  @override
  Widget build(BuildContext context) {
    if (!_showTickets && !_showNoticeBoard) {
      return Scaffold(
        appBar: AppBar(title: const Text('TAFS Staff')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Your account does not have access to Support Tickets. '
              'Ask an administrator to grant the appropriate permissions.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final showBottomNav = _showTickets && _showNoticeBoard;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshActiveTab,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              resetStaffSessionState(context);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: showBottomNav
          ? NavigationBar(
              selectedIndex: _activeTab == _StaffTab.tickets ? 0 : 1,
              onDestinationSelected: (index) {
                setState(() {
                  _activeTab =
                      index == 0 ? _StaffTab.tickets : _StaffTab.noticeBoard;
                });
                if (index == 1) {
                  context.read<StaffNoticeBoardCubit>().load();
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.confirmation_number_outlined),
                  selectedIcon: Icon(Icons.confirmation_number),
                  label: 'Tickets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.article_outlined),
                  selectedIcon: Icon(Icons.article),
                  label: 'Notice Board',
                ),
              ],
            )
          : null,
    );
  }
}
