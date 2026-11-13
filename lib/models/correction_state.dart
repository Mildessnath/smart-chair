/// Where a value came from. The UI must label simulated values clearly.
enum DataSource {
  simulated,
  sensor;

  static DataSource fromKey(String? key) =>
      key == 'sensor' ? DataSource.sensor : DataSource.simulated;
}

enum CorrectionStatus {
  withinLimit,

  /// Posture is bad and the dwell countdown is running.
  pending,
  correcting,

  /// Correction is paused by the user while the tilt exceeds the limit.
  paused,
  unavailable,
  fault;

  String get label => switch (this) {
    CorrectionStatus.withinLimit => 'Within limit',
    CorrectionStatus.pending => 'Pending',
    CorrectionStatus.correcting => 'Correcting',
    CorrectionStatus.paused => 'Paused',
    CorrectionStatus.unavailable => 'Unavailable',
    CorrectionStatus.fault => 'Fault',
  };

  static CorrectionStatus fromKey(String? key) =>
      CorrectionStatus.values.firstWhere(
        (s) => s.name == key,
        orElse: () => CorrectionStatus.unavailable,
      );
}

/// Control loop phase: MONITOR → DWELL → CORRECT → HOLD → MONITOR.
enum ControlPhase {
  monitor,

  /// Bad posture detected; waiting `dwellSeconds` before acting. Cancelled
  /// if posture improves.
  dwell,
  correct,
  hold;

  static ControlPhase fromKey(String? key) => ControlPhase.values.firstWhere(
    (p) => p.name == key,
    orElse: () => ControlPhase.monitor,
  );
}

/// Seat tilt correction state. Angles in degrees; positive = reclined back.
class CorrectionState {
  const CorrectionState({
    required this.actualAngleDeg,
    required this.targetAngleDeg,
    required this.status,
    required this.source,
    this.phase = ControlPhase.monitor,
    this.correctionPaused = false,
    this.dwellRemaining,
  });

  const CorrectionState.unavailable()
    : actualAngleDeg = null,
      targetAngleDeg = null,
      status = CorrectionStatus.unavailable,
      source = DataSource.simulated,
      phase = ControlPhase.monitor,
      correctionPaused = false,
      dwellRemaining = null;

  final double? actualAngleDeg;
  final double? targetAngleDeg;
  final CorrectionStatus status;
  final DataSource source;
  final ControlPhase phase;

  /// User paused correction: the actuator never moves, but detection and
  /// notifications keep running.
  final bool correctionPaused;

  /// Whole seconds left in the dwell countdown; only set while
  /// [phase] is [ControlPhase.dwell].
  final int? dwellRemaining;

  double? get errorDeg => actualAngleDeg == null || targetAngleDeg == null
      ? null
      : actualAngleDeg! - targetAngleDeg!;

  Map<String, dynamic> toMap() => {
    'actualDeg': actualAngleDeg,
    'targetDeg': targetAngleDeg,
    'status': status.name,
    'source': source.name,
    'phase': phase.name,
    'paused': correctionPaused,
    'dwellRemaining': dwellRemaining,
  };

  factory CorrectionState.fromMap(Map<String, dynamic> map) => CorrectionState(
    actualAngleDeg: (map['actualDeg'] as num?)?.toDouble(),
    targetAngleDeg: (map['targetDeg'] as num?)?.toDouble(),
    status: CorrectionStatus.fromKey(map['status'] as String?),
    source: DataSource.fromKey(map['source'] as String?),
    phase: ControlPhase.fromKey(map['phase'] as String?),
    correctionPaused: map['paused'] as bool? ?? false,
    dwellRemaining: (map['dwellRemaining'] as num?)?.toInt(),
  );
}
