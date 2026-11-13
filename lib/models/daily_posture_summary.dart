/// Minutes spent in good vs bad posture for one calendar day.
class DailyPostureSummary {
  const DailyPostureSummary({
    required this.date,
    required this.goodMinutes,
    required this.badMinutes,
  });

  /// Local date at midnight.
  final DateTime date;
  final double goodMinutes;
  final double badMinutes;

  double get totalMinutes => goodMinutes + badMinutes;
  double? get goodRatio =>
      totalMinutes <= 0 ? null : goodMinutes / totalMinutes;

  DailyPostureSummary add({double good = 0, double bad = 0}) =>
      DailyPostureSummary(
        date: date,
        goodMinutes: goodMinutes + good,
        badMinutes: badMinutes + bad,
      );

  /// Storage key, e.g. `2026-10-16`.
  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
    'goodMinutes': goodMinutes,
    'badMinutes': badMinutes,
  };

  factory DailyPostureSummary.fromMap(
    String dateKey,
    Map<String, dynamic> map,
  ) {
    final parts = dateKey.split('-').map(int.parse).toList();
    return DailyPostureSummary(
      date: DateTime(parts[0], parts[1], parts[2]),
      goodMinutes: (map['goodMinutes'] as num?)?.toDouble() ?? 0,
      badMinutes: (map['badMinutes'] as num?)?.toDouble() ?? 0,
    );
  }
}
