import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/calendar_alert.dart';
import '../../presentation/bloc/notice_board_bloc.dart';
import '../../presentation/bloc/notice_board_event.dart';
import '../../../auth/presentation/bloc/selected_student_cubit.dart';
import '../../../attendance_history/presentation/pages/attendance_calendar_page.dart';

class CalendarAlertCard extends StatefulWidget {
  final CalendarAlert alert;

  const CalendarAlertCard({super.key, required this.alert});

  @override
  State<CalendarAlertCard> createState() => _CalendarAlertCardState();
}

class _CalendarAlertCardState extends State<CalendarAlertCard> {
  @override
  void initState() {
    super.initState();
    if (!widget.alert.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NoticeBoardBloc>().add(NoticeBoardCalendarAlertRead(widget.alert.id));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    
    IconData icon;
    Color iconColor;
    Color iconBg;

    if (alert.alertType == 'SCHOOL_OPEN') {
      icon = Icons.event_available_rounded;
      iconColor = AppTheme.paid;
      iconBg = AppTheme.paidBg;
    } else if (alert.alertType == 'DAY_OFF') {
      icon = Icons.calendar_today_rounded;
      iconColor = AppTheme.warning;
      iconBg = AppTheme.warningBg;
    } else {
      // HOLIDAY
      icon = Icons.event_busy_rounded;
      iconColor = AppTheme.unpaid;
      iconBg = AppTheme.unpaidBg;
    }

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
            child: InkWell(
              onTap: () {
                final activeStudent = context.read<SelectedStudentCubit>().state;
                if (activeStudent != null && activeStudent.cc == alert.studentCc) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceCalendarPage(
                        student: activeStudent,
                        initialSelectedDate: alert.date.toLocal(),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                alert.body,
                style: const TextStyle(fontSize: 13, color: AppTheme.navy, height: 1.4),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space2),
          Text(
            _formatTime(alert.createdAt),
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
