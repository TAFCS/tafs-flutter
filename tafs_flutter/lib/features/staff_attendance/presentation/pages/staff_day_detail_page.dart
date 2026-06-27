import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/pkt_format.dart';
import '../../domain/entities/staff_attendance_period.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Day Detail'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(dateLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (widget.day.status != null)
            Chip(label: Text(widget.day.status!.replaceAll('_', ' '))),
          const SizedBox(height: 16),
          const Text('Punches', style: TextStyle(fontWeight: FontWeight.w600)),
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
          if (breakdown != null) ...[
            const Divider(height: 32),
            const Text('Deductions', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Classification: ${breakdown['classification'] ?? '—'}'),
            Text('Break minutes: ${breakdown['break_minutes'] ?? 0}'),
          ],
          if (_objections.isNotEmpty) ...[
            const Divider(height: 32),
            const Text('Objections', style: TextStyle(fontWeight: FontWeight.w600)),
            ..._objections.map(
              (o) => ListTile(
                title: Text(o.status),
                subtitle: Text(
                  'Claimed ${formatPktTime(o.claimedTime)} PKT',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
