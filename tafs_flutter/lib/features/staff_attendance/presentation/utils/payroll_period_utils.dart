String currentPayrollPeriodLabel([DateTime? date]) {
  final d = date ?? DateTime.now().toUtc();
  final y = d.year;
  final m = d.month;
  if (d.day >= 26) {
    if (m == 12) return '${y + 1}-01';
    return '$y-${(m + 1).toString().padLeft(2, '0')}';
  }
  return '$y-${m.toString().padLeft(2, '0')}';
}

String shiftPayrollPeriod(String period, int delta) {
  final parts = period.split('-');
  var year = int.parse(parts[0]);
  var month = int.parse(parts[1]);
  month += delta;
  while (month > 12) {
    month -= 12;
    year += 1;
  }
  while (month < 1) {
    month += 12;
    year -= 1;
  }
  return '$year-${month.toString().padLeft(2, '0')}';
}

String formatPayrollPeriodRange(DateTime start, DateTime end) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String fmt(DateTime d, {bool withYear = true}) =>
      '${d.day} ${months[d.month - 1]}${withYear ? ' ${d.year}' : ''}';
  final sameYear = start.year == end.year;
  return '${fmt(start, withYear: !sameYear)} – ${fmt(end)}';
}
