import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/support_ticket.dart';

class TicketStatusBadge extends StatelessWidget {
  final TicketStatus status;

  const TicketStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TicketStatus.open => ('Open', Colors.orange),
      TicketStatus.assigned => ('In Progress', AppTheme.navy),
      TicketStatus.closed => ('Closed', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
