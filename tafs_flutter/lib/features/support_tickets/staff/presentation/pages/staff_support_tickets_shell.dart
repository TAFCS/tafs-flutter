import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../auth/domain/entities/staff_user.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../../../core/session/session_reset.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/staff_support_ticket.dart';
import '../../support_ticket_staff_access.dart';
import '../bloc/staff_pending_approvals_cubit.dart';
import '../bloc/staff_ticket_queue_bloc.dart';
import 'staff_ticket_thread_page.dart';

class StaffSupportTicketsShell extends StatefulWidget {
  final StaffUser staff;
  final bool embedded;

  const StaffSupportTicketsShell({
    super.key,
    required this.staff,
    this.embedded = false,
  });

  @override
  State<StaffSupportTicketsShell> createState() => _StaffSupportTicketsShellState();
}

class _StaffSupportTicketsShellState extends State<StaffSupportTicketsShell> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    if (!canViewSupportTickets(widget.staff)) return;
    context.read<StaffTicketQueueBloc>().add(StaffQueueInit(widget.staff.role));
    if (widget.staff.role == 'SUPER_ADMIN') {
      final approvalsCubit = context.read<StaffPendingApprovalsCubit>();
      approvalsCubit.startListening();
      approvalsCubit.load();
    }
    _searchController.addListener(() => setState(() => _search = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StaffSupportTicket> _filterTickets(List<StaffSupportTicket> items) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((t) {
      final household = t.householdName?.toLowerCase() ?? '';
      final subtopic = t.subtopic?.toLowerCase() ?? '';
      final snippet = t.lastMessageSnippet?.toLowerCase() ?? '';
      return household.contains(q) || subtopic.contains(q) || snippet.contains(q);
    }).toList();
  }

  void _openThread(String ticketId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffTicketThreadPage(
          ticketId: ticketId,
          staff: widget.staff,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      context.read<StaffTicketQueueBloc>().add(StaffQueueRefreshRequested());
      if (widget.staff.role == 'SUPER_ADMIN') {
        context.read<StaffPendingApprovalsCubit>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!canViewSupportTickets(widget.staff)) {
      if (widget.embedded) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Your account does not have access to Support Tickets.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Support Tickets')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Your account does not have access to Support Tickets. '
              'Ask an administrator to grant communication.support_tickets.view.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final showFinance = showFinanceTab(widget.staff.role);
    final showOversight = showOversightTab(widget.staff.role);

    final body = Column(
        children: [
          BlocBuilder<StaffTicketQueueBloc, StaffTicketQueueState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (showOversight)
                            _tabChip(context, state, StaffQueueTab.oversight),
                          _tabChip(context, state, StaffQueueTab.myQueue),
                          if (showFinance)
                            _tabChip(context, state, StaffQueueTab.financeQueue),
                          _tabChip(context, state, StaffQueueTab.closed),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search tickets…',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.error!,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<StaffPendingApprovalsCubit, StaffPendingApprovalsState>(
              builder: (context, approvalsState) {
                // Build ticketId -> pending count map for O(1) lookup per card
                final pendingByTicket = <String, int>{};
                if (widget.staff.role == 'SUPER_ADMIN') {
                  for (final a in approvalsState.items) {
                    if (a.ticketId != null) {
                      pendingByTicket[a.ticketId!] =
                          (pendingByTicket[a.ticketId!] ?? 0) + 1;
                    }
                  }
                }

                return BlocBuilder<StaffTicketQueueBloc, StaffTicketQueueState>(
                  builder: (context, state) {
                    if (state.loading && state.items.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.navy),
                      );
                    }
                    final filtered = _filterTickets(state.items);
                    if (filtered.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<StaffTicketQueueBloc>().add(StaffQueueRefreshRequested());
                        },
                        child: ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No tickets in this queue')),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<StaffTicketQueueBloc>().add(StaffQueueRefreshRequested());
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final t = filtered[i];
                          final pendingCount = pendingByTicket[t.id] ?? 0;
                          return _TicketCard(
                            ticket: t,
                            pendingCount: pendingCount,
                            currentStaffId: widget.staff.id,
                            onTap: () => _openThread(t.id),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Support Tickets'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<StaffTicketQueueBloc>().add(StaffQueueRefreshRequested());
              if (widget.staff.role == 'SUPER_ADMIN') {
                context.read<StaffPendingApprovalsCubit>().load();
              }
            },
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
      body: body,
    );
  }

  Widget _tabChip(
    BuildContext context,
    StaffTicketQueueState state,
    StaffQueueTab tab,
  ) {
    final selected = state.tab == tab;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(queueTabLabel(tab)),
        selected: selected,
        selectedColor: AppTheme.navy,
        labelStyle: TextStyle(
          color: selected ? AppTheme.white : AppTheme.navy,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        onSelected: (_) {
          context.read<StaffTicketQueueBloc>().add(StaffQueueTabChanged(tab));
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final StaffSupportTicket ticket;
  final int pendingCount;
  final String currentStaffId;
  final VoidCallback onTap;

  const _TicketCard({
    required this.ticket,
    required this.pendingCount,
    required this.currentStaffId,
    required this.onTap,
  });

  Color get _accentColor =>
      ticket.category.name == 'financial' ? Colors.amber.shade600 : AppTheme.navy;

  @override
  Widget build(BuildContext context) {
    final hasUnread = ticket.unreadByStaff > 0;
    final hasPending = pendingCount > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: name + time
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.householdName ?? 'Family #${ticket.familyId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM d, h:mm a').format(ticket.lastMessageAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 3),

              // Row 2: subtopic
              if (ticket.subtopic != null)
                Text(
                  ticket.subtopic!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),

              // Row 3: family snippet
              if (ticket.lastFamilySnippet != null)
                _SnippetRow(
                  icon: Icons.person_outline_rounded,
                  senderName: ticket.lastFamilySenderName ?? 'Family',
                  text: ticket.lastFamilySnippet!,
                  bold: hasUnread,
                  count: hasUnread ? ticket.unreadByStaff : null,
                  countColor: AppTheme.navy,
                ),

              // Row 4: staff snippet
              if (ticket.lastStaffSnippet != null) ...[
                if (ticket.lastFamilySnippet != null) const SizedBox(height: 4),
                _SnippetRow(
                  icon: Icons.support_agent_rounded,
                  senderName: ticket.lastStaffSenderId == currentStaffId
                      ? 'You'
                      : ticket.lastStaffSenderName ?? ticket.assigneeName ?? 'Staff',
                  text: ticket.lastStaffSnippet!,
                  bold: hasPending,
                  count: hasPending ? pendingCount : null,
                  countColor: Colors.amber.shade700,
                ),
              ],

              // Fallback
              if (ticket.lastFamilySnippet == null &&
                  ticket.lastStaffSnippet == null &&
                  ticket.lastMessageSnippet != null)
                Text(
                  ticket.lastMessageSnippet!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SnippetRow extends StatelessWidget {
  final IconData icon;
  final String senderName;
  final String text;
  final bool bold;
  final int? count;
  final Color countColor;

  const _SnippetRow({
    required this.icon,
    required this.senderName,
    required this.text,
    required this.bold,
    this.count,
    required this.countColor,
  });

  @override
  Widget build(BuildContext context) {
    final nameColor = bold ? countColor : Colors.grey.shade400;
    final textColor = bold ? const Color(0xFF1A1A2E) : Colors.grey.shade500;

    return Row(
      children: [
        Icon(icon, size: 13, color: nameColor),
        const SizedBox(width: 5),
        Text(
          '$senderName:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: nameColor,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: countColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
