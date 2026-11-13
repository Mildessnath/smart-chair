/// Device configuration that will later be synced to the chair.
class ChairConfig {
  const ChairConfig({
    required double maxTiltDeg,
    int dwellSeconds = defaultDwellSeconds,
    this.updatedAt,
  }) : maxTiltDeg = maxTiltDeg < minTilt
           ? minTilt
           : (maxTiltDeg > maxTilt ? maxTilt : maxTiltDeg),
       dwellSeconds = dwellSeconds < minDwellSeconds
           ? minDwellSeconds
           : (dwellSeconds > maxDwellSeconds ? maxDwellSeconds : dwellSeconds);

  static const double minTilt = 0;
  static const double maxTilt = 5;
  static const int minDwellSeconds = 20;
  static const int maxDwellSeconds = 30;
  static const int defaultDwellSeconds = 25;
  static const ChairConfig defaults = ChairConfig(maxTiltDeg: 3.0);

  /// Maximum allowed seat tilt before correction starts, 0°–5°.
  final double maxTiltDeg;

  /// How long bad posture must persist before correction starts, 20–30 s.
  final int dwellSeconds;
  final DateTime? updatedAt;

  ChairConfig copyWith({
    double? maxTiltDeg,
    int? dwellSeconds,
    DateTime? updatedAt,
  }) => ChairConfig(
    maxTiltDeg: maxTiltDeg ?? this.maxTiltDeg,
    dwellSeconds: dwellSeconds ?? this.dwellSeconds,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  bool sameValuesAs(ChairConfig other) =>
      (maxTiltDeg - other.maxTiltDeg).abs() < 1e-9 &&
      dwellSeconds == other.dwellSeconds;

  Map<String, dynamic> toMap() => {
    'maxTiltDeg': maxTiltDeg,
    'dwellSeconds': dwellSeconds,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
  };

  factory ChairConfig.fromMap(Map<String, dynamic> map) {
    final ts = map['updatedAt'] as int?;
    return ChairConfig(
      maxTiltDeg:
          (map['maxTiltDeg'] as num?)?.toDouble() ?? defaults.maxTiltDeg,
      dwellSeconds:
          (map['dwellSeconds'] as num?)?.toInt() ?? defaultDwellSeconds,
      updatedAt: ts == null ? null : DateTime.fromMillisecondsSinceEpoch(ts),
    );
  }
}
