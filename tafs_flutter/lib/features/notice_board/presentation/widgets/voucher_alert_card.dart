import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/voucher_alert.dart';
import '../../presentation/bloc/notice_board_bloc.dart';
import '../../presentation/bloc/notice_board_event.dart';
import '../../../auth/presentation/bloc/selected_student_cubit.dart';
import '../../../../core/navigation/app_navigator.dart';

class VoucherAlertCard extends StatefulWidget {
  final VoucherAlert alert;

  const VoucherAlertCard({super.key, required this.alert});

  @override
  State<VoucherAlertCard> createState() => _VoucherAlertCardState();
}

class _VoucherAlertCardState extends State<VoucherAlertCard> {
  @override
  void initState() {
    super.initState();
    if (!widget.alert.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NoticeBoardBloc>().add(NoticeBoardVoucherAlertRead(widget.alert.id));
        }
      });
    }
  }

  void _markRead() {
    context.read<NoticeBoardBloc>().add(NoticeBoardVoucherAlertRead(widget.alert.id));
  }

  void _openFees() {
    final activeStudent = context.read<SelectedStudentCubit>().state;
    if (activeStudent == null || activeStudent.cc != widget.alert.studentCc) return;
    switchToFeesTab();
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;

    final IconData icon;
    final Color statusColor;

    if (alert.isIssuedAlert) {
      icon = Icons.receipt_long_rounded;
      statusColor = AppTheme.navy;
    } else if (alert.isOverdueAlert) {
      icon = Icons.error_outline_rounded;
      statusColor = AppTheme.danger;
    } else if (alert.isExpiryAlert) {
      icon = Icons.timer_outlined;
      statusColor = AppTheme.danger;
    } else {
      icon = Icons.warning_amber_rounded;
      statusColor = AppTheme.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      decoration: BoxDecoration(
        color: alert.isRead ? AppTheme.white : AppTheme.blue100.withOpacity(0.22),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.blue100.withOpacity(0.7), width: 1.0),
        boxShadow: AppTheme.shadowXs,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: _openFees,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space4,
              vertical: AppTheme.space3 * 1.2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(icon, size: 20, color: statusColor),
                    ),
                    const SizedBox(width: AppTheme.space3 * 1.2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: TextStyle(
                              fontSize: 15.5,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            alert.body,
                            style: TextStyle(
                              fontSize: 15.0,
                              color: AppTheme.navy.withOpacity(0.88),
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.space2),
                    Text(
                      _formatTime(alert.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.navy.withOpacity(0.45),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (!alert.isRead) ...[
                  const SizedBox(height: AppTheme.space2),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton.icon(
                      onPressed: _markRead,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.done_rounded, size: 15, color: AppTheme.navy),
                      label: const Text(
                        'Mark as read',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navy),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
