import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/staff_attendance_period.dart';

class ScanTimelineWidget extends StatelessWidget {
  final List<StaffScan> scans;
  final void Function(StaffScan scan)? onObjectionTap;

  const ScanTimelineWidget({
    super.key,
    required this.scans,
    this.onObjectionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (scans.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No biometric punches recorded for this day.'),
      );
    }

    final fmt = DateFormat('h:mm a');

    return Column(
      children: scans.map((scan) {
        final isMissingOut = scans.last == scan && scans.length % 2 != 0;
        return ListTile(
          leading: Icon(
            scan.direction == 'OUT' ? Icons.logout : Icons.login,
            color: isMissingOut ? Colors.amber.shade800 : Colors.grey.shade700,
          ),
          title: Text(fmt.format(scan.scanTime.toLocal())),
          subtitle: Text(scan.direction ?? 'PUNCH'),
          trailing: onObjectionTap != null
              ? IconButton(
                  icon: const Icon(Icons.report_gmailerrorred_outlined),
                  tooltip: 'Raise objection',
                  onPressed: () => onObjectionTap!(scan),
                )
              : (isMissingOut
                  ? const Icon(Icons.warning_amber_rounded, color: Colors.amber)
                  : null),
        );
      }).toList(),
    );
  }
}
