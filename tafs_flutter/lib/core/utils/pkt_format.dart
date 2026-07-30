import 'package:intl/intl.dart';

/// Pakistan Standard Time is UTC+5 year-round (no DST).
const pktOffset = Duration(hours: 5);

/// Attendance timestamps returned by the API (`scan_time`, `check_in_at`,
/// `check_out_at`, payroll segment bounds, objection `claimed_time`) are
/// Asia/Karachi **wall-clock** values that happen to be serialised with a `Z`
/// suffix: the biometric devices report local time and the backend stores it
/// verbatim in `timestamp without time zone` columns, then calls
/// `toISOString()` on it. Reading the UTC components back therefore already
/// gives PKT — adding [pktOffset] on top would double-count the offset.
///
/// Returns a local-flavoured `DateTime` carrying those wall-clock components,
/// so `DateFormat` and `TimeOfDay.fromDateTime` render them as-is.
DateTime pktWallClock(DateTime value) {
  final u = value.toUtc();
  return DateTime(u.year, u.month, u.day, u.hour, u.minute, u.second);
}

/// Current PKT wall clock, in the same shape as [pktWallClock]. `DateTime.now()`
/// *is* a real instant, so this one does need the offset applied.
DateTime nowPkt() {
  final u = DateTime.now().toUtc().add(pktOffset);
  return DateTime(u.year, u.month, u.day, u.hour, u.minute, u.second);
}

/// Calendar day key (`yyyy-MM-dd`) for attendance dates stored as UTC midnight.
String pktDateKey(DateTime value) {
  final d = value.toUtc();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

String formatPktTime(DateTime value) =>
    DateFormat('h:mm a').format(pktWallClock(value));

String formatPktDate(DateTime value, {String pattern = 'EEE, d MMM yyyy'}) {
  final d = value.toUtc();
  return DateFormat(pattern).format(DateTime(d.year, d.month, d.day));
}

String formatPktDateTime(DateTime value, {String pattern = 'd MMM yyyy • h:mm a'}) =>
    DateFormat(pattern).format(pktWallClock(value));
