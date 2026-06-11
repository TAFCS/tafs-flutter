import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../auth/domain/entities/staff_user.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../../chat/staff/presentation/bloc/staff_announcements_cubit.dart';
import '../../../../chat/staff/presentation/pages/staff_announcements_page.dart';
import '../../../../chat/staff/staff_chat_access.dart';
import '../../../../../core/session/session_reset.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../support_ticket_staff_access.dart';
import '../bloc/staff_pending_approvals_cubit.dart';
import '../bloc/staff_ticket_queue_bloc.dart';
import 'staff_support_tickets_shell.dart';

enum _StaffTab { tickets, announcements }

class StaffMainShell extends StatefulWidget {
  final StaffUser staff;

  const StaffMainShell({super.key, required this.staff});

  @override
  State<StaffMainShell> createState() => _StaffMainShellState();
}

class _StaffMainShellState extends State<StaffMainShell> {
  _StaffTab _activeTab = _StaffTab.tickets;

  bool get _showTickets => canViewSupportTickets(widget.staff);
  bool get _showAnnouncements => canViewAnnouncementsChat(widget.staff);

  @override
  void initState() {
    super.initState();
    if (!_showTickets && _showAnnouncements) {
      _activeTab = _StaffTab.announcements;
    }
  }

  void _refreshActiveTab() {
    if (_activeTab == _StaffTab.tickets && _showTickets) {
      context.read<StaffTicketQueueBloc>().add(StaffQueueRefreshRequested());
      if (widget.staff.role == 'SUPER_ADMIN') {
        context.read<StaffPendingApprovalsCubit>().load();
      }
    } else if (_activeTab == _StaffTab.announcements && _showAnnouncements) {
      context.read<StaffAnnouncementsCubit>().refresh();
    }
  }

  Widget _buildBody() {
    if (_showTickets && _showAnnouncements) {
      return IndexedStack(
        index: _activeTab == _StaffTab.tickets ? 0 : 1,
        children: [
          StaffSupportTicketsShell(staff: widget.staff, embedded: true),
          const StaffAnnouncementsPage(loadOnMount: false),
        ],
      );
    }
    if (_showTickets) {
      return StaffSupportTicketsShell(staff: widget.staff, embedded: true);
    }
    return const StaffAnnouncementsPage(loadOnMount: true);
  }

  String get _title {
    if (!_showTickets && _showAnnouncements) return 'Announcements';
    if (_showTickets && !_showAnnouncements) return 'Support Tickets';
    return _activeTab == _StaffTab.tickets
        ? 'Support Tickets'
        : 'Announcements';
  }

  @override
  Widget build(BuildContext context) {
    if (!_showTickets && !_showAnnouncements) {
      return Scaffold(
        appBar: AppBar(title: const Text('TAFS Staff')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Your account does not have access to Support Tickets or '
              'Announcements Chat. Ask an administrator to grant the '
              'appropriate communication permissions.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final showBottomNav = _showTickets && _showAnnouncements;

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
                      index == 0 ? _StaffTab.tickets : _StaffTab.announcements;
                });
                if (index == 1) {
                  context.read<StaffAnnouncementsCubit>().load();
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.confirmation_number_outlined),
                  selectedIcon: Icon(Icons.confirmation_number),
                  label: 'Tickets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.campaign_outlined),
                  selectedIcon: Icon(Icons.campaign),
                  label: 'Announcements',
                ),
              ],
            )
          : null,
    );
  }
}
