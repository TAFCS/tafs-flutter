import 'package:flutter/material.dart';

import '../../../../core/utils/pkt_format.dart';
import '../../domain/entities/staff_attendance_period.dart';

class PunchDisplay {
  final String time;
  final bool isIn;
  final bool missing;

  const PunchDisplay({
    required this.time,
    required this.isIn,
    this.missing = false,
  });
}

class AttendanceCellStyle {
  final Color background;
  final Color dot;
  final Color text;

  const AttendanceCellStyle({
    required this.background,
    required this.dot,
    required this.text,
  });
}

String classifyDay(StaffDayEntry day, {Map<String, dynamic>? breakdown}) {
  final fromBreakdown = breakdown?['classification'] as String?;
  if (fromBreakdown != null && fromBreakdown.isNotEmpty) {
    return fromBreakdown;
  }

  if (!day.isWorkingDay) return 'DAY_OFF';

  final status = day.status?.toUpperCase();
  if (status == 'EXCUSED') return 'EXCUSED';
  if (status == 'ABSENT') return 'ABSENT';
  if (status == 'HALF_DAY') return 'HALF_DAY';
  if (status == 'LATE') return 'LATE';
  if (day.scans.isNotEmpty && day.scans.length % 2 != 0) return 'UNRESOLVED';
  if (status == 'PRESENT') return 'PRESENT';
  if (day.scans.isEmpty) return 'ABSENT';
  return 'PRESENT';
}

Map<String, dynamic>? breakdownForDay(
  StaffPayrollSnapshot? snapshot,
  StaffDayEntry day,
) {
  if (snapshot == null) return null;
  final key = pktDateKey(day.date);
  for (final row in snapshot.dailyBreakdown) {
    if (row['date'] == key) return row;
  }
  return null;
}

String _formatSegmentTime(String value) {
  if (value == '00:00' || value == '24:00') return value;
  return formatPktTime(DateTime.parse(value));
}

List<PunchDisplay> extractPunches(
  StaffDayEntry day, {
  Map<String, dynamic>? breakdown,
}) {
  final segments = breakdown?['segments'];
  if (segments is List && segments.isNotEmpty) {
    final punches = <PunchDisplay>[];
    for (final raw in segments) {
      if (raw is! Map) continue;
      if (raw['type'] != 'WORK') continue;
      final start = raw['start']?.toString();
      final end = raw['end']?.toString();
      if (start != null) {
        punches.add(PunchDisplay(time: _formatSegmentTime(start), isIn: true));
      }
      if (raw['isMissingOut'] == true) {
        punches.add(const PunchDisplay(time: '?', isIn: false, missing: true));
      } else if (end != null) {
        punches.add(PunchDisplay(time: _formatSegmentTime(end), isIn: false));
      }
    }
    if (punches.isNotEmpty) return punches;
  }

  if (day.scans.isNotEmpty) {
    final punches = <PunchDisplay>[];
    for (var i = 0; i < day.scans.length; i += 2) {
      punches.add(
        PunchDisplay(
          time: formatPktTime(day.scans[i].scanTime),
          isIn: true,
        ),
      );
      if (i + 1 < day.scans.length) {
        punches.add(
          PunchDisplay(
            time: formatPktTime(day.scans[i + 1].scanTime),
            isIn: false,
          ),
        );
      } else {
        punches.add(
          const PunchDisplay(time: '?', isIn: false, missing: true),
        );
      }
    }
    return punches;
  }

  final punches = <PunchDisplay>[];
  if (day.checkInAt != null) {
    punches.add(PunchDisplay(time: formatPktTime(day.checkInAt!), isIn: true));
  }
  if (day.checkOutAt != null) {
    punches.add(PunchDisplay(time: formatPktTime(day.checkOutAt!), isIn: false));
  } else if (day.checkInAt != null) {
    punches.add(const PunchDisplay(time: '?', isIn: false, missing: true));
  }
  return punches;
}

AttendanceCellStyle cellStyleFor(String classification) {
  switch (classification) {
    case 'LATE':
      return AttendanceCellStyle(
        background: const Color(0xFFFFFBEB),
        dot: const Color(0xFFF59E0B),
        text: const Color(0xFFB45309),
      );
    case 'HALF_DAY':
      return AttendanceCellStyle(
        background: const Color(0xFFFFF7ED),
        dot: const Color(0xFFF97316),
        text: const Color(0xFFC2410C),
      );
    case 'ABSENT':
      return AttendanceCellStyle(
        background: const Color(0xFFFFF1F2),
        dot: const Color(0xFFF43F5E),
        text: const Color(0xFFE11D48),
      );
    case 'EXCUSED':
      return AttendanceCellStyle(
        background: const Color(0xFFF0F9FF),
        dot: const Color(0xFF38BDF8),
        text: const Color(0xFF0369A1),
      );
    case 'UNRESOLVED':
      return AttendanceCellStyle(
        background: const Color(0xFFFFF0EB),
        dot: const Color(0xFFE8500A),
        text: const Color(0xFF7C2D12),
      );
    case 'DAY_OFF':
      return AttendanceCellStyle(
        background: const Color(0xFFF4F4F5),
        dot: const Color(0xFFD4D4D8),
        text: const Color(0xFF71717A),
      );
    case 'PRESENT':
    default:
      return AttendanceCellStyle(
        background: Colors.white,
        dot: const Color(0xFF10B981),
        text: const Color(0xFF3F3F46),
      );
  }
}

const attendanceLegend = <(String, String)>[
  ('PRESENT', 'Present'),
  ('LATE', 'Late'),
  ('HALF_DAY', 'Half Day'),
  ('ABSENT', 'Absent'),
  ('EXCUSED', 'Excused'),
  ('UNRESOLVED', 'Unresolved'),
  ('DAY_OFF', 'Day Off'),
];
