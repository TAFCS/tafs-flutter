import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/staff_support_ticket.dart';
import '../bloc/staff_pending_approvals_cubit.dart';

class _GroupedApproval {
  final String? ticketId;
  final String? householdName;
  final int count;
  final String? senderName;
  final String lastSnippet;

  const _GroupedApproval({
    required this.ticketId,
    required this.householdName,
    required this.count,
    required this.senderName,
    required this.lastSnippet,
  });
}

List<_GroupedApproval> _groupByTicket(List<PendingApproval> items) {
  final map = <String, List<PendingApproval>>{};
  for (final item in items) {
    final key = item.ticketId ?? '__no_ticket__';
    map.putIfAbsent(key, () => []).add(item);
  }
  return map.entries.map((e) {
    final list = e.value;
    final last = list.last;
    return _GroupedApproval(
      ticketId: last.ticketId,
      householdName: last.householdName,
      count: list.length,
      senderName: last.senderName,
      lastSnippet: last.content,
    );
  }).toList();
}

class StaffApprovalQueueWidget extends StatefulWidget {
  final void Function(String ticketId)? onOpenTicket;

  const StaffApprovalQueueWidget({super.key, this.onOpenTicket});

  @override
  State<StaffApprovalQueueWidget> createState() => _StaffApprovalQueueWidgetState();
}

class _StaffApprovalQueueWidgetState extends State<StaffApprovalQueueWidget> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StaffPendingApprovalsCubit, StaffPendingApprovalsState>(
      builder: (context, state) {
        if (state.loading && state.items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.navy),
              ),
            ),
          );
        }
        if (state.items.isEmpty) return const SizedBox.shrink();

        final groups = _groupByTicket(state.items);

        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Column(
            children: [
              // Header — always visible, tap to collapse/expand
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: _expanded
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Text(
                        'Pending approvals',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${state.items.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 20,
                        color: Colors.amber.shade800,
                      ),
                    ],
                  ),
                ),
              ),

              // Collapsible body
              if (_expanded) ...[
                const Divider(height: 1, thickness: 1),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shrinkWrap: true,
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const Divider(height: 16, thickness: 0.5),
                    itemBuilder: (_, i) => _GroupedApprovalRow(
                      group: groups[i],
                      onTap: groups[i].ticketId != null
                          ? () => widget.onOpenTicket?.call(groups[i].ticketId!)
                          : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GroupedApprovalRow extends StatelessWidget {
  final _GroupedApproval group;
  final VoidCallback? onTap;

  const _GroupedApprovalRow({required this.group, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      group.householdName ?? 'Ticket',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (group.count > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${group.count} messages',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  group.lastSnippet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                if (group.senderName != null)
                  Text(
                    'From ${group.senderName}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }
}
