String _two(int v) => v.toString().padLeft(2, '0');

String formatTime(DateTime t) =>
    '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

String formatHm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatWeekday(DateTime d) => _weekdays[d.weekday - 1];

String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String formatDateTime(DateTime t) =>
    '${_two(t.day)} ${_months[t.month - 1]} ${formatTime(t)}';

String formatAgo(Duration d) {
  if (d.isNegative || d.inSeconds < 1) return 'just now';
  if (d.inSeconds < 60) return '${d.inSeconds}s ago';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

/// Compact elapsed time: `45s`, `3m 05s`, `1h 02m`.
String formatDuration(Duration d) {
  if (d.inMinutes < 1) return '${d.inSeconds}s';
  if (d.inHours < 1) return '${d.inMinutes}m ${_two(d.inSeconds % 60)}s';
  return '${d.inHours}h ${_two(d.inMinutes % 60)}m';
}

/// Stopwatch style: `12:34` or `1:02:05`.
String formatClock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  return h > 0 ? '$h:${_two(m)}:${_two(s)}' : '${_two(m)}:${_two(s)}';
}

String formatDeg(double? v, {int digits = 1}) =>
    v == null ? '—' : '${v.toStringAsFixed(digits)}°';

String formatSignedDeg(double? v, {int digits = 1}) {
  if (v == null) return '—';
  final s = v.toStringAsFixed(digits);
  return v > 0 ? '+$s°' : '$s°';
}

String formatKg(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)} kg';

String formatMinutes(double minutes) {
  final m = minutes.round();
  if (m < 60) return '$m min';
  return '${m ~/ 60}h ${_two(m % 60)}m';
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);
