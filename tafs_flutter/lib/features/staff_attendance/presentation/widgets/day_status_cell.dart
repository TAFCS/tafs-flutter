import 'package:flutter/material.dart';

import '../../../../core/utils/pkt_format.dart';
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
    final todayPkt = toPkt(DateTime.now());
    final dayPkt = toPkt(day.date);
    final todayKey = DateTime(todayPkt.year, todayPkt.month, todayPkt.day);
    final dayKey = DateTime(dayPkt.year, dayPkt.month, dayPkt.day);
    return dayKey.isAfter(todayKey);
  }

  @override
  Widget build(BuildContext context) {
    final classification = classifyDay(day, breakdown: breakdown);
    final style = cellStyleFor(classification);
    final dayNumber = day.date.toUtc().day;

    // Future days with approved leave keep their color so employees can see it.
    // All other future days get the neutral grey treatment.
    final isApprovedLeave = classification == 'EXCUSED';
    final useMutedStyle = _isFuture && !isApprovedLeave;

    final background = useMutedStyle ? const Color(0xFFFAFAFA) : style.background;
    final textColor = useMutedStyle ? const Color(0xFFA1A1AA) : style.text;
    final showDot = !useMutedStyle;
    final label = _shortLabel(classification);
    final showLabel = !useMutedStyle &&
        classification != 'PRESENT' &&
        classification != 'DAY_OFF' &&
        classification != 'UNRESOLVED' &&
        label.isNotEmpty;

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
                : isApprovedLeave
                    ? const Color(0xFFBAE6FD)
                    : const Color(0xFFE4E4E7),
            width: (classification == 'ABSENT' && !_isFuture) || isApprovedLeave ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (showDot)
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        fontSize: 14,
                        height: 1,
                      ),
                    ),
                    if (classification == 'UNRESOLVED')
                      Text(
                        '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: style.text,
                          fontSize: 8,
                          height: 1,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (showLabel)
              Positioned(
                left: 0,
                right: 0,
                bottom: 1,
                child: Text(
                  label,
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
        return 'Leave';
      default:
        return '';
    }
  }
}
