import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/staff_attendance_period.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../widgets/scan_timeline_widget.dart';
import 'objection_submit_page.dart';

class StaffDayDetailPage extends StatelessWidget {
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

  Map<String, dynamic>? _dayBreakdown() {
    if (payrollSnapshot == null) return null;
    final key = DateFormat('yyyy-MM-dd').format(day.date.toUtc());
    for (final row in payrollSnapshot!.dailyBreakdown) {
      if (row['date'] == key) return row;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = _dayBreakdown();
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(day.date.toLocal());

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
          if (day.status != null)
            Chip(label: Text(day.status!.replaceAll('_', ' '))),
          const SizedBox(height: 16),
          const Text('Punches', style: TextStyle(fontWeight: FontWeight.w600)),
          ScanTimelineWidget(
            scans: day.scans,
            onObjectionTap: (scan) async {
              final submitted = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ObjectionSubmitPage(
                    attendanceDate: day.date,
                    scans: day.scans,
                    preselectedScan: scan,
                    repository: repository,
                  ),
                ),
              );
              if (submitted == true) onObjectionSubmitted?.call();
            },
          ),
          if (breakdown != null) ...[
            const Divider(height: 32),
            const Text('Deductions', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Classification: ${breakdown['classification'] ?? '—'}'),
            Text('Break minutes: ${breakdown['break_minutes'] ?? 0}'),
          ],
          if (day.objections.isNotEmpty) ...[
            const Divider(height: 32),
            const Text('Objections', style: TextStyle(fontWeight: FontWeight.w600)),
            ...day.objections.map(
              (o) => ListTile(
                title: Text(o.status),
                subtitle: Text(
                  'Claimed ${DateFormat('h:mm a').format(o.claimedTime.toLocal())}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
