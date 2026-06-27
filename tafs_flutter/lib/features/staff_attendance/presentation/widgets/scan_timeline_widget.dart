import 'package:flutter/material.dart';

import '../../../../core/utils/pkt_format.dart';
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
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No biometric scans recorded for this day.',
          style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
        ),
      );
    }

    // Build display entries: one per real scan, plus a synthetic missing
    // clock-out entry when the scan count is odd.
    final entries = <_Entry>[];
    for (var i = 0; i < scans.length; i++) {
      final isIn = scans[i].direction == 'IN' ||
          (scans[i].direction != 'OUT' && i % 2 == 0);
      entries.add(_Entry(scan: scans[i], isIn: isIn));
    }
    if (scans.length % 2 != 0) {
      entries.add(const _Entry(scan: null, isIn: false, missing: true));
    }

    return Column(
      children: entries.map((entry) {
        final Color iconColor;
        final Color bgColor;
        final Color borderColor;

        if (entry.missing) {
          iconColor = const Color(0xFFD97706);
          bgColor = const Color(0xFFFFFBEB);
          borderColor = const Color(0xFFFDE68A);
        } else if (entry.isIn) {
          iconColor = const Color(0xFF059669);
          bgColor = const Color(0xFFECFDF5);
          borderColor = const Color(0xFFA7F3D0);
        } else {
          iconColor = const Color(0xFFBE185D);
          bgColor = const Color(0xFFFFF1F2);
          borderColor = const Color(0xFFFFCDD2);
        }

        final label = entry.isIn ? 'Clock In' : 'Clock Out';
        final timeText = entry.missing
            ? 'Contact school admin to resolve'
            : formatPktTime(entry.scan!.scanTime);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  entry.missing
                      ? Icons.help_outline_rounded
                      : entry.isIn
                          ? Icons.login_rounded
                          : Icons.logout_rounded,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: entry.missing ? 14 : 17,
                        fontWeight: FontWeight.w800,
                        color: entry.missing
                            ? const Color(0xFF92400E)
                            : const Color(0xFF1F2937),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (!entry.missing && onObjectionTap != null)
                IconButton(
                  icon: Icon(Icons.flag_outlined,
                      size: 18, color: Colors.grey.shade400),
                  tooltip: 'Raise objection',
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => onObjectionTap!(entry.scan!),
                )
              else if (entry.missing)
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFF59E0B), size: 22),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Entry {
  final StaffScan? scan;
  final bool isIn;
  final bool missing;

  const _Entry({
    required this.scan,
    required this.isIn,
    this.missing = false,
  });
}
