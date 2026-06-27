import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/staff_attendance_period.dart';

class DayStatusCell extends StatelessWidget {
  final StaffDayEntry day;
  final VoidCallback? onTap;

  const DayStatusCell({super.key, required this.day, this.onTap});

  Color _bgColor() {
    if (!day.isWorkingDay) return Colors.grey.shade300;
    final now = DateTime.now().toUtc();
    final isFuture = day.date.isAfter(DateTime.utc(now.year, now.month, now.day));
    if (isFuture) return Colors.grey.shade100;

    switch (day.status) {
      case 'PRESENT':
        return AppTheme.navy.withValues(alpha: 0.85);
      case 'LATE':
        return Colors.orange.shade400;
      case 'ABSENT':
        return Colors.red.shade300;
      case 'HALF_DAY':
        return Colors.orange.shade200;
      case 'EXCUSED':
        return Colors.blue.shade300;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _bgColor();
    final textColor = day.status == 'PRESENT' ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: day.status == 'ABSENT'
              ? Border.all(color: Colors.red.shade700, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.date.day}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: textColor,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
