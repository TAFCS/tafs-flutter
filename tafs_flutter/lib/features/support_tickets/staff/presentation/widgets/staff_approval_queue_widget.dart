import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/staff_support_ticket.dart';
import '../bloc/staff_pending_approvals_cubit.dart';

class StaffApprovalQueueWidget extends StatelessWidget {
  final void Function(String ticketId)? onOpenTicket;

  const StaffApprovalQueueWidget({super.key, this.onOpenTicket});

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

        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pending approvals',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...state.items.take(5).map((item) => _ApprovalRow(
                    item: item,
                    onTap: item.ticketId != null
                        ? () => onOpenTicket?.call(item.ticketId!)
                        : null,
                  )),
              if (state.items.length > 5)
                Text(
                  '+${state.items.length - 5} more',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ApprovalRow extends StatelessWidget {
  final PendingApproval item;
  final VoidCallback? onTap;

  const _ApprovalRow({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.householdName ?? 'Ticket',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    item.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (item.senderName != null)
                    Text(
                      'From ${item.senderName}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}
