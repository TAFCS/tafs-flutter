import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/attendance_alert.dart';
import '../bloc/notice_board_bloc.dart';
import '../bloc/notice_board_event.dart';

class AttendanceAlertCard extends StatefulWidget {
  final AttendanceAlert alert;

  const AttendanceAlertCard({super.key, required this.alert});

  @override
  State<AttendanceAlertCard> createState() => _AttendanceAlertCardState();
}

class _AttendanceAlertCardState extends State<AttendanceAlertCard> {
  @override
  void initState() {
    super.initState();
    if (!widget.alert.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NoticeBoardBloc>().add(NoticeBoardAlertRead(widget.alert.id));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final isClockIn = alert.direction == 'IN';
    final iconColor = isClockIn ? AppTheme.paid : AppTheme.navy;
    final iconBg = isClockIn ? AppTheme.paidBg : AppTheme.blue100;
    final icon = isClockIn ? Icons.login_rounded : Icons.logout_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: AppTheme.space3),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.blue100),
        boxShadow: AppTheme.shadowXs,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Text(
              alert.body,
              style: const TextStyle(fontSize: 13, color: AppTheme.navy, height: 1.4),
            ),
          ),
          const SizedBox(width: AppTheme.space2),
          Text(
            _formatTime(alert.scanTimeUtc),
            style: const TextStyle(fontSize: 11, color: AppTheme.blue300),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}
