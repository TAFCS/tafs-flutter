import 'package:flutter/material.dart';
import '../../domain/entities/staff_attendance_period.dart';
import 'day_status_cell.dart';

class PayrollPeriodCalendar extends StatelessWidget {
  final List<StaffDayEntry> days;
  final void Function(StaffDayEntry day)? onDayTap;

  const PayrollPeriodCalendar({
    super.key,
    required this.days,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    final first = days.first.date;
    final leadingBlanks = first.weekday % 7;

    return GridView.builder(
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
          onTap: onDayTap != null ? () => onDayTap!(day) : null,
        );
      },
    );
  }
}
