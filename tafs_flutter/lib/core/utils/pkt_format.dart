import 'package:intl/intl.dart';

/// Pakistan Standard Time is UTC+5 year-round (no DST).
const pktOffset = Duration(hours: 5);

DateTime toPkt(DateTime value) => value.toUtc().add(pktOffset);

/// Calendar day key (`yyyy-MM-dd`) for attendance dates stored as UTC midnight.
String pktDateKey(DateTime value) {
  final d = value.toUtc();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

String formatPktTime(DateTime value) =>
    DateFormat('h:mm a').format(toPkt(value));

String formatPktDate(DateTime value, {String pattern = 'EEE, d MMM yyyy'}) {
  final d = value.toUtc();
  return DateFormat(pattern).format(DateTime(d.year, d.month, d.day));
}

String formatPktDateTime(DateTime value, {String pattern = 'd MMM yyyy • h:mm a'}) =>
    DateFormat(pattern).format(toPkt(value));
