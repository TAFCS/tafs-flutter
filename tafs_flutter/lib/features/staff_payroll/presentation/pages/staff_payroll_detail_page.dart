import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/pkt_format.dart';
import '../../../staff_attendance/presentation/widgets/day_timeline_widget.dart';
import '../../../staff_attendance/presentation/utils/payroll_period_utils.dart';
import '../../domain/repositories/staff_payroll_repository.dart';

// ── Classification colours ────────────────────────────────────────────────────

const _clsColors = <String, _ClsStyle>{
  'PRESENT':    _ClsStyle(bg: Color(0xFFECFDF5), text: Color(0xFF059669), dot: Color(0xFF10B981), label: 'Present'),
  'LATE':       _ClsStyle(bg: Color(0xFFFFFBEB), text: Color(0xFFB45309), dot: Color(0xFFF59E0B), label: 'Late'),
  'HALF_DAY':   _ClsStyle(bg: Color(0xFFFFF7ED), text: Color(0xFFC2410C), dot: Color(0xFFF97316), label: 'Half Day'),
  'ABSENT':     _ClsStyle(bg: Color(0xFFFFF1F2), text: Color(0xFFBE123C), dot: Color(0xFFF43F5E), label: 'Absent'),
  'EXCUSED':    _ClsStyle(bg: Color(0xFFF0F9FF), text: Color(0xFF0369A1), dot: Color(0xFF38BDF8), label: 'Excused'),
  'UNRESOLVED': _ClsStyle(bg: Color(0xFFFFF0EB), text: Color(0xFF7C2D12), dot: Color(0xFFE8500A), label: 'Unresolved'),
  'DAY_OFF':    _ClsStyle(bg: Color(0xFFF4F4F5), text: Color(0xFF71717A), dot: Color(0xFFD4D4D8), label: 'Day Off'),
};

class _ClsStyle {
  final Color bg;
  final Color text;
  final Color dot;
  final String label;
  const _ClsStyle({required this.bg, required this.text, required this.dot, required this.label});
}

_ClsStyle _styleFor(String? cls) =>
    _clsColors[cls ?? ''] ?? const _ClsStyle(bg: Color(0xFFF4F4F5), text: Color(0xFF71717A), dot: Color(0xFFD4D4D8), label: '—');

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDayLabel(String dateStr) {
  try {
    final d = DateTime.parse('${dateStr}T00:00:00Z');
    return DateFormat('EEE, d MMM').format(d);
  } catch (_) {
    return dateStr;
  }
}

String _fmtTime(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    return formatPktTime(DateTime.parse(iso));
  } catch (_) {
    return '—';
  }
}

String _fmtBreak(int minutes) {
  if (minutes <= 0) return '';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m break';
  if (m == 0) return '${h}h break';
  return '${h}h ${m}m break';
}

// ── Page ──────────────────────────────────────────────────────────────────────

class StaffPayrollDetailPage extends StatefulWidget {
  final int payrollRunId;
  final StaffPayrollRepository repository;

  const StaffPayrollDetailPage({
    super.key,
    required this.payrollRunId,
    required this.repository,
  });

  @override
  State<StaffPayrollDetailPage> createState() => _StaffPayrollDetailPageState();
}

class _StaffPayrollDetailPageState extends State<StaffPayrollDetailPage> {
  bool _loading = true;
  String? _error;
  dynamic _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final detail = await widget.repository.getMyPayrollDetail(widget.payrollRunId);
      if (!mounted) return;
      setState(() { _detail = detail; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _fmtPkr(double v) => 'PKR ${NumberFormat('#,##0.00').format(v)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payslip Detail'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _detail;
    final start = parsePayrollPeriodDate(d.periodStart);
    final end   = parsePayrollPeriodDate(d.periodEnd);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          formatPayrollPeriodRange(start, end),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text('Status: ${d.displayStatus}'),
        if (d.disbursedAt != null)
          Text('Disbursed: ${DateFormat.yMMMd().format(d.disbursedAt!.toLocal())}'),

        const Divider(height: 32),
        _row('Monthly Pay (Base)',   _fmtPkr(d.monthlyPay)),
        _row('− Absence Deduction',  _fmtPkr(d.absenceDeduction)),
        _row('− Half-Day Deduction', _fmtPkr(d.halfDayDeduction)),
        _row('− Break Deduction',    _fmtPkr(d.breakDeduction)),
        const Divider(),
        _row('Net Pay', _fmtPkr(d.netPay), bold: true),

        const SizedBox(height: 16),
        Text(
          'Present ${d.presentDays} • Late ${d.lateDays} • Absent ${d.absentDays} • '
          'Half ${d.halfDays} • Excused ${d.excusedDays}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
        ),

        const SizedBox(height: 20),

        // ── Day-by-day breakdown ──────────────────────────────────────────
        const Text(
          'Day-by-day Breakdown',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...d.dailyBreakdown.map<Widget>((row) => _DayCard(row: row)),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

// ── Day card widget ───────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final Map<String, dynamic> row;

  const _DayCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final cls        = row['classification'] as String?;
    final style      = _styleFor(cls);
    final dateLabel  = _fmtDayLabel(row['date'] as String? ?? '');
    final breakMin   = (row['break_minutes'] as num?)?.toInt() ?? 0;
    final checkIn    = row['check_in_at'] as String?;
    final checkOut   = row['check_out_at'] as String?;
    final isWorkDay  = row['is_working_day'] != false;
    final segments   = row['segments'] is List
        ? (row['segments'] as List).cast<Map<String, dynamic>>()
        : null;

    // Determine if it needs a timeline bar (skip DAY_OFF and ABSENT with no scans)
    final showTimeline = isWorkDay && cls != 'DAY_OFF';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                // Status dot
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: style.dot,
                    shape: BoxShape.circle,
                  ),
                ),
                // Date
                Expanded(
                  child: Text(
                    dateLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                // Classification badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    style.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: style.text,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Clock-in / clock-out times (only when there's data to show)
          if (isWorkDay && cls != 'DAY_OFF' && (checkIn != null || checkOut != null))
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(
                children: [
                  _timeChip(
                    Icons.login_rounded,
                    const Color(0xFF059669),
                    const Color(0xFFECFDF5),
                    checkIn != null ? _fmtTime(checkIn) : '—',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward, size: 12, color: Color(0xFFD1D5DB)),
                  ),
                  _timeChip(
                    Icons.logout_rounded,
                    checkOut != null ? const Color(0xFFBE185D) : const Color(0xFFD97706),
                    checkOut != null ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB),
                    checkOut != null ? _fmtTime(checkOut) : '—',
                  ),
                  if (breakMin > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.coffee_rounded, size: 10, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 3),
                          Text(
                            _fmtBreak(breakMin),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Timeline bar
          if (showTimeline)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: DayTimelineWidget(
                segments: segments,
                scans: const [],
              ),
            ),

          // DAY_OFF / no-data label
          if (!showTimeline)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                row['day_description'] as String? ?? (cls == 'DAY_OFF' ? 'Non-working day' : 'No scans'),
                style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timeChip(IconData icon, Color iconColor, Color bg, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: iconColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
