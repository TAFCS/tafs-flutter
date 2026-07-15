import 'package:intl/intl.dart';

/// Compact chat bubble timestamp, e.g. "Fri, 13 Jun · 2:30 PM".
String formatChatBubbleTimestamp(DateTime value) {
  final local = value.toLocal();
  final date = DateFormat('EEE, d MMM').format(local);
  final time = DateFormat('h:mm a').format(local);
  return '$date · $time';
}
