import 'package:dio/dio.dart';
import '../../domain/entities/staff_attendance_period.dart';
import '../../domain/repositories/staff_attendance_repository.dart';

class StaffAttendanceRemoteDataSource {
  final Dio dio;

  StaffAttendanceRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> fetchMyAttendance(String period) async {
    final res = await dio.get(
      '/attendance/staff/me',
      queryParameters: {'period': period},
    );
    return _unwrap(res.data);
  }

  Future<void> createObjection(Map<String, dynamic> body) async {
    await dio.post('/attendance/objections', data: body);
  }

  Future<List<Map<String, dynamic>>> fetchMyObjections() async {
    final res = await dio.get('/attendance/objections/me');
    final raw = res.data;
    final data = raw is Map ? raw['data'] ?? raw : raw;
    return (data as List).cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map && raw['data'] != null) return raw['data'] as Map<String, dynamic>;
    return raw as Map<String, dynamic>;
  }
}

class StaffAttendanceRepositoryImpl implements StaffAttendanceRepository {
  final StaffAttendanceRemoteDataSource remote;

  StaffAttendanceRepositoryImpl({required this.remote});

  @override
  Future<StaffAttendancePeriod> getMyAttendance(String period) async {
    final json = await remote.fetchMyAttendance(period);
    return _mapPeriod(json);
  }

  @override
  Future<void> submitObjection({
    required DateTime attendanceDate,
    int? scanId,
    required DateTime claimedTime,
    required String reason,
  }) {
    return remote.createObjection({
      'attendance_date': _dateOnly(attendanceDate),
      if (scanId != null) 'scan_id': scanId,
      'claimed_time': claimedTime.toUtc().toIso8601String(),
      'reason': reason,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getMyObjections() => remote.fetchMyObjections();

  StaffAttendancePeriod _mapPeriod(Map<String, dynamic> json) {
    final days = (json['days'] as List? ?? [])
        .map((e) => _mapDay(e as Map<String, dynamic>))
        .toList();

    StaffPayrollSnapshot? snapshot;
    final snap = json['payroll_snapshot'];
    if (snap is Map<String, dynamic>) {
      snapshot = StaffPayrollSnapshot(
        status: snap['status'] as String? ?? 'DRAFT',
        disbursedAt: snap['disbursed_at'] != null
            ? DateTime.parse(snap['disbursed_at'] as String)
            : null,
        disbursementNotes: snap['disbursement_notes'] as String?,
        dailyRate: (snap['daily_rate'] as num?)?.toDouble() ?? 0,
        perMinuteRate: (snap['per_minute_rate'] as num?)?.toDouble() ?? 0,
        dailyBreakdown: (snap['daily_breakdown'] as List? ?? [])
            .cast<Map<String, dynamic>>(),
      );
    }

    return StaffAttendancePeriod(
      period: json['period'] as String,
      periodStart: DateTime.parse('${json['period_start']}T00:00:00Z'),
      periodEnd: DateTime.parse('${json['period_end']}T00:00:00Z'),
      days: days,
      payrollSnapshot: snapshot,
    );
  }

  StaffDayEntry _mapDay(Map<String, dynamic> json) {
    return StaffDayEntry(
      date: DateTime.parse('${json['date']}T00:00:00Z'),
      status: json['status'] as String?,
      checkInAt: json['check_in_at'] != null
          ? DateTime.parse(json['check_in_at'] as String)
          : null,
      checkOutAt: json['check_out_at'] != null
          ? DateTime.parse(json['check_out_at'] as String)
          : null,
      scans: (json['scans'] as List? ?? []).map((s) {
        final m = s as Map<String, dynamic>;
        return StaffScan(
          id: m['id'] as int,
          scanTime: DateTime.parse(m['scan_time'] as String),
          direction: m['direction'] as String?,
        );
      }).toList(),
      isWorkingDay: json['is_working_day'] as bool? ?? true,
      dayType: json['day_type'] as String?,
      objections: (json['objections'] as List? ?? []).map((o) {
        final m = o as Map<String, dynamic>;
        return StaffObjectionSummary(
          id: m['id'] as int,
          scanId: m['scan_id'] as int?,
          claimedTime: DateTime.parse(m['claimed_time'] as String),
          status: m['status'] as String,
        );
      }).toList(),
    );
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
