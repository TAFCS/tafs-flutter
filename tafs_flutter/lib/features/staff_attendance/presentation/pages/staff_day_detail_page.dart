import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/pkt_format.dart';
import '../../domain/entities/staff_attendance_period.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../widgets/day_timeline_widget.dart';
import '../widgets/scan_timeline_widget.dart';
import 'objection_submit_page.dart';

class StaffDayDetailPage extends StatefulWidget {
  final StaffDayEntry day;
  final StaffPayrollSnapshot? payrollSnapshot;
  final StaffAttendanceRepository repository;
  final VoidCallback? onObjectionSubmitted;

  const StaffDayDetailPage({
    super.key,
    required this.day,
    this.payrollSnapshot,
    required this.repository,
    this.onObjectionSubmitted,
  });

  @override
  State<StaffDayDetailPage> createState() => _StaffDayDetailPageState();
}

class _StaffDayDetailPageState extends State<StaffDayDetailPage> {
  late List<StaffObjectionSummary> _objections;

  @override
  void initState() {
    super.initState();
    _objections = widget.day.objections;
  }

  String get _dateKey => pktDateKey(widget.day.date);

  Map<String, dynamic>? _dayBreakdown() {
    if (widget.payrollSnapshot == null) return null;
    for (final row in widget.payrollSnapshot!.dailyBreakdown) {
      if (row['date'] == _dateKey) return row;
    }
    return null;
  }

  Future<void> _reloadObjections() async {
    try {
      final rows = await widget.repository.getMyObjections();
      final updated = rows
          .where((o) {
            final d = o['attendance_date'] as String?;
            return d != null && d.startsWith(_dateKey);
          })
          .map(
            (o) => StaffObjectionSummary(
              id: o['id'] as int,
              scanId: o['scan_id'] as int?,
              claimedTime: DateTime.parse(o['claimed_time'] as String),
              status: o['status'] as String,
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() => _objections = updated);
      widget.onObjectionSubmitted?.call();
    } catch (_) {
      widget.onObjectionSubmitted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = _dayBreakdown();
    final dateLabel = formatPktDate(widget.day.date);

    final segments = breakdown?['segments'] is List
        ? (breakdown!['segments'] as List).cast<Map<String, dynamic>>()
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Day Detail'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            dateLabel,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (widget.day.status != null)
            Chip(label: Text(widget.day.status!.replaceAll('_', ' '))),
          const SizedBox(height: 20),

          // ── Day Timeline ──────────────────────────────────────────────────
          const Text(
            'Timeline',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          DayTimelineWidget(
            segments: segments,
            scans: widget.day.scans,
          ),

          const SizedBox(height: 24),

          // ── Clock Events ──────────────────────────────────────────────────
          const Text(
            'Clock Events',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          ScanTimelineWidget(
            scans: widget.day.scans,
            onObjectionTap: (scan) async {
              final submitted = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ObjectionSubmitPage(
                    attendanceDate: widget.day.date,
                    scans: widget.day.scans,
                    preselectedScan: scan,
                    repository: widget.repository,
                  ),
                ),
              );
              if (submitted == true) await _reloadObjections();
            },
          ),

          // ── Deductions ────────────────────────────────────────────────────
          if (breakdown != null) ...[
            const Divider(height: 32),
            const Text(
              'Deductions',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text('Classification: ${breakdown['classification'] ?? '—'}'),
            Text('Break minutes: ${breakdown['break_minutes'] ?? 0}'),
          ],

          // ── Objections ────────────────────────────────────────────────────
          if (_objections.isNotEmpty) ...[
            const Divider(height: 32),
            const Text(
              'Objections',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
            ..._objections.map(
              (o) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(o.status),
                subtitle: Text('Claimed ${formatPktTime(o.claimedTime)}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
