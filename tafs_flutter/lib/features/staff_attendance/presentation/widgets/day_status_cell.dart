import 'package:flutter/material.dart';

import '../../domain/entities/staff_attendance_period.dart';
import '../utils/attendance_day_utils.dart';

class DayStatusCell extends StatelessWidget {
  final StaffDayEntry day;
  final Map<String, dynamic>? breakdown;
  final VoidCallback? onTap;

  const DayStatusCell({
    super.key,
    required this.day,
    this.breakdown,
    this.onTap,
  });

  bool get _isFuture {
    final today = DateTime.now().toUtc();
    final d = day.date.toUtc();
    final todayKey = DateTime.utc(today.year, today.month, today.day);
    final dayKey = DateTime.utc(d.year, d.month, d.day);
    return dayKey.isAfter(todayKey);
  }

  @override
  Widget build(BuildContext context) {
    final classification = classifyDay(day, breakdown: breakdown);
    final style = cellStyleFor(classification);
    final dayNumber = day.date.toUtc().day;

    final background = _isFuture ? const Color(0xFFFAFAFA) : style.background;
    final textColor = _isFuture ? const Color(0xFFA1A1AA) : style.text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: classification == 'ABSENT' && !_isFuture
                ? const Color(0xFFFECDD3)
                : const Color(0xFFE4E4E7),
            width: classification == 'ABSENT' && !_isFuture ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (!_isFuture)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: style.dot,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    fontSize: 14,
                    height: 1,
                  ),
                ),
              ),
            ),
            if (!_isFuture &&
                classification != 'PRESENT' &&
                classification != 'DAY_OFF' &&
                _shortLabel(classification).isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 1,
                child: Text(
                  _shortLabel(classification),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: 6.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _shortLabel(String classification) {
    switch (classification) {
      case 'LATE':
        return 'Late';
      case 'HALF_DAY':
        return 'Half';
      case 'ABSENT':
        return 'Absent';
      case 'EXCUSED':
        return 'Excused';
      case 'UNRESOLVED':
        return '?';
      default:
        return '';
    }
  }
}
