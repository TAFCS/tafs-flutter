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
                          return Material(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openThread(t.id),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.householdName ?? 'Family #${t.familyId}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${categoryLabel(t.category.name)} · ${t.subtopic ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.blue300,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Family's last message
                                          if (t.lastFamilySnippet != null)
                                            _SnippetRow(
                                              label: 'Family',
                                              text: t.lastFamilySnippet!,
                                              bold: t.unreadByStaff > 0,
                                              count: t.unreadByStaff > 0 ? t.unreadByStaff : null,
                                              countColor: AppTheme.navy,
                                            ),
                                          // Staff's last message
                                          if (t.lastStaffSnippet != null) ...[
                                            if (t.lastFamilySnippet != null) const SizedBox(height: 3),
                                            _SnippetRow(
                                              label: 'You',
                                              text: t.lastStaffSnippet!,
                                              bold: pendingCount > 0,
                                              count: pendingCount > 0 ? pendingCount : null,
                                              countColor: Colors.amber.shade700,
                                            ),
                                          ],
                                          // Fallback if neither side snippet exists yet
                                          if (t.lastFamilySnippet == null && t.lastStaffSnippet == null && t.lastMessageSnippet != null) ...[
                                            Text(
                                              t.lastMessageSnippet!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('MMM d, h:mm a').format(t.lastMessageAt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

class _SnippetRow extends StatelessWidget {
  final String label;
  final String text;
  final bool bold;
  final int? count;
  final Color countColor;

  const _SnippetRow({
    required this.label,
    required this.text,
    required this.bold,
    this.count,
    required this.countColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: countColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
