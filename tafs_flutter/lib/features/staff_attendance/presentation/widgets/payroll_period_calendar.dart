import 'package:flutter/material.dart';

import '../../domain/entities/staff_attendance_period.dart';
import '../utils/attendance_day_utils.dart';
import 'day_status_cell.dart';

const _weekdayLabels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

class PayrollPeriodCalendar extends StatelessWidget {
  final List<StaffDayEntry> days;
  final StaffPayrollSnapshot? payrollSnapshot;
  final void Function(StaffDayEntry day)? onDayTap;

  const PayrollPeriodCalendar({
    super.key,
    required this.days,
    this.payrollSnapshot,
    this.onDayTap,
  });

  int get _unresolvedCount => days.where((day) {
        final breakdown = breakdownForDay(payrollSnapshot, day);
        return classifyDay(day, breakdown: breakdown) == 'UNRESOLVED';
      }).length;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    final first = days.first.date.toUtc();
    final leadingBlanks = first.weekday % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_unresolvedCount > 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_unresolvedCount unresolved day(s) — tap a day to review punches.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF92400E),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              for (final label in _weekdayLabels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: label == 'Su' || label == 'Sa'
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFF71717A),
                    ),
                  ),
                ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: leadingBlanks + days.length,
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox.shrink();
            final day = days[index - leadingBlanks];
            return DayStatusCell(
              day: day,
              breakdown: breakdownForDay(payrollSnapshot, day),
              onTap: onDayTap != null ? () => onDayTap!(day) : null,
            );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'All times shown in PKT (UTC+5)',
          style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final (cls, label) in attendanceLegend)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: cellStyleFor(cls).dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
