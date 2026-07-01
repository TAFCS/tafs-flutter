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
    
    final IconData icon;
    final Color statusColor;
    final String badgeText;

    if (alert.alertType == 'SCHOOL_OPEN') {
      icon = Icons.event_available_rounded;
      statusColor = AppTheme.paid;
      badgeText = 'School Open';
    } else if (alert.alertType == 'DAY_OFF') {
      icon = Icons.calendar_today_rounded;
      statusColor = AppTheme.warning;
      badgeText = 'Day Off';
    } else {
      icon = Icons.event_busy_rounded;
      statusColor = AppTheme.unpaid;
      badgeText = 'Holiday';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.blue100.withOpacity(0.7), width: 1.0),
        boxShadow: AppTheme.shadowXs,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 180,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.24),
                        statusColor.withOpacity(0.0),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space4,
                  vertical: AppTheme.space3 * 1.2,
                ),
                child: Row(
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
                            badgeText,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            alert.body,
                            style: TextStyle(
                              fontSize: 13.0,
                              color: AppTheme.navy.withOpacity(0.75),
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.space2),
                    Row(
                      children: [
                        if (alert.isPinned) ...[
                          Icon(
                            Icons.push_pin_rounded,
                            size: 13,
                            color: AppTheme.navy.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                        ],
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
                  ],
                ),
              ),
            ],
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
