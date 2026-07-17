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
      final title = ticketRequesterLabel(
        studentName: t.studentName,
        householdName: t.householdName,
        familyId: t.familyId,
      ).toLowerCase();
      final student = t.studentName?.toLowerCase() ?? '';
      final household = t.householdName?.toLowerCase() ?? '';
      final subtopic = t.subtopic?.toLowerCase() ?? '';
      final snippet = t.lastMessageSnippet?.toLowerCase() ?? '';
      return title.contains(q) ||
          student.contains(q) ||
          household.contains(q) ||
          subtopic.contains(q) ||
          snippet.contains(q);
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
            return Container(
              color: Colors.white,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Underline tab row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Row(
                    children: [
                      if (showOversight) ...[
                        _TabButton(
                          label: queueTabLabel(StaffQueueTab.oversight),
                          selected: state.tab == StaffQueueTab.oversight,
                          onTap: () => context
                              .read<StaffTicketQueueBloc>()
                              .add(StaffQueueTabChanged(StaffQueueTab.oversight)),
                        ),
                        const SizedBox(width: 28),
                      ],
                      _TabButton(
                        label: queueTabLabel(StaffQueueTab.myQueue),
                        selected: state.tab == StaffQueueTab.myQueue,
                        onTap: () => context
                            .read<StaffTicketQueueBloc>()
                            .add(StaffQueueTabChanged(StaffQueueTab.myQueue)),
                      ),
                      if (showFinance) ...[
                        const SizedBox(width: 28),
                        _TabButton(
                          label: queueTabLabel(StaffQueueTab.financeQueue),
                          selected: state.tab == StaffQueueTab.financeQueue,
                          onTap: () => context
                              .read<StaffTicketQueueBloc>()
                              .add(StaffQueueTabChanged(StaffQueueTab.financeQueue)),
                        ),
                      ],
                      const SizedBox(width: 28),
                      _TabButton(
                        label: queueTabLabel(StaffQueueTab.closed),
                        selected: state.tab == StaffQueueTab.closed,
                        onTap: () => context
                            .read<StaffTicketQueueBloc>()
                            .add(StaffQueueTabChanged(StaffQueueTab.closed)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tickets…',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade400),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppTheme.navy.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
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
                  ),
              ],
            ));
          },
        ),
        Expanded(
          child: BlocBuilder<StaffPendingApprovalsCubit, StaffPendingApprovalsState>(
            builder: (context, approvalsState) {
              final pendingByTicket = <String, int>{};
              if (widget.staff.role == 'SUPER_ADMIN') {
                for (final a in approvalsState.items) {
                  if (a.ticketId != null) {
                    pendingByTicket[a.ticketId!] = (pendingByTicket[a.ticketId!] ?? 0) + 1;
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
                        final pc = pendingByTicket[t.id] ?? 0;
                        return _TicketCard(
                          ticket: t,
                          pendingCount: pc,
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
      backgroundColor: AppTheme.surface2,
      appBar: AppBar(
        title: const Text('Support Tickets'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<StaffTicketQueueBloc>().add(StaffQueueRefreshRequested());
              if (widget.staff.role == 'SUPER_ADMIN') {
                context.read<StaffPendingApprovalsCubit>().load();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
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
}

// Underline-style tab — no chips, no pills
class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: Container(
          padding: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppTheme.navy : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.navy : Colors.grey.shade400,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
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

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDay).inDays;
    if (diff == 0) return DateFormat('h:mm a').format(dt);
    if (diff <= 6) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }

  String get _staffSender =>
      ticket.lastStaffSenderId == currentStaffId
          ? 'You'
          : ticket.lastStaffSenderName ?? ticket.assigneeName ?? 'Staff';

  @override
  Widget build(BuildContext context) {
    final hasUnread = ticket.unreadByStaff > 0;
    final hasPending = pendingCount > 0;
    final isFinancial = ticket.category.name == 'financial';
    final hasFamily = ticket.lastFamilySnippet != null;
    final hasStaff = ticket.lastStaffSnippet != null;
    final hasFallback = !hasFamily && !hasStaff && ticket.lastMessageSnippet != null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: requester + time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      ticketRequesterLabel(
                        studentName: ticket.studentName,
                        householdName: ticket.householdName,
                        familyId: ticket.familyId,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatTime(ticket.lastMessageAt),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Row 2: category · subtopic
              Row(
                children: [
                  Flexible(
                    child: Text(
                      [
                        categoryLabel(ticket.category.name),
                        if (ticket.subtopic != null && ticket.subtopic!.isNotEmpty)
                          ticket.subtopic!,
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isFinancial) ...[
                    const SizedBox(width: 8),
                    _CategoryTag(label: 'Finance'),
                  ],
                ],
              ),
              // Message previews
              if (hasFamily || hasStaff || hasFallback) ...[
                const SizedBox(height: 10),
                if (hasFamily)
                  _SnippetText(
                    sender: ticket.lastFamilySenderName ?? 'Family',
                    text: ticket.lastFamilySnippet!,
                    color: hasUnread ? const Color(0xFF374151) : Colors.grey.shade400,
                    bold: hasUnread,
                  ),
                if (hasStaff) ...[
                  if (hasFamily) const SizedBox(height: 3),
                  _SnippetText(
                    sender: _staffSender,
                    text: ticket.lastStaffSnippet!,
                    color: Colors.grey.shade400,
                    bold: false,
                  ),
                ],
                if (hasFallback)
                  _SnippetText(
                    sender: '',
                    text: ticket.lastMessageSnippet!,
                    color: Colors.grey.shade400,
                    bold: false,
                  ),
              ],
              // Status footer: labeled unread + pending
              if (hasUnread || hasPending) ...[
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (hasUnread) ...[
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                          color: AppTheme.navy,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        '${ticket.unreadByStaff} unread',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.navy,
                        ),
                      ),
                    ],
                    if (hasUnread && hasPending)
                      Text(
                        '  ·  ',
                        style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
                      ),
                    if (hasPending) ...[
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        '$pendingCount pending approval',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String label;

  const _CategoryTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.amber.shade700,
        ),
      ),
    );
  }
}

class _SnippetText extends StatelessWidget {
  final String sender;
  final String text;
  final Color color;
  final bool bold;

  const _SnippetText({
    required this.sender,
    required this.text,
    required this.color,
    required this.bold,
  });

  @override
  Widget build(BuildContext context) {
    if (sender.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, color: color),
      );
    }
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: '$sender: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
            color: color,
          ),
        ),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
