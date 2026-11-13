import '../utils/pressure_math.dart';
import 'correction_state.dart';
import 'load_cell.dart';
import 'posture_state.dart';

/// One telemetry sample from the chair (or the simulator).
class ChairTelemetry {
  const ChairTelemetry({
    required this.timestamp,
    required this.loadCells,
    required this.tiltAngleDeg,
    required this.posture,
    required this.correction,
    required this.source,
  });

  final DateTime timestamp;
  final Map<LoadCellPosition, LoadCellReading> loadCells;

  /// Measured seat pitch in degrees; positive = reclined backward.
  final double? tiltAngleDeg;
  final PostureState posture;
  final CorrectionState correction;
  final DataSource source;

  LoadCellReading cell(LoadCellPosition p) =>
      loadCells[p] ??
      LoadCellReading(position: p, kg: null, health: SensorHealth.noSignal);

  bool get allCellsValid =>
      LoadCellPosition.values.every((p) => cell(p).isValid);

  double? get totalLoadKg => allCellsValid
      ? LoadCellPosition.values.fold<double>(0, (s, p) => s + cell(p).kg!)
      : null;

  /// Derived, not stored: computed from the four load cells.
  CenterOfPressure? get centerOfPressure => computeCenterOfPressure(this);

  Map<String, dynamic> toMap() => {
    'ts': timestamp.millisecondsSinceEpoch,
    'loadCells': {
      for (final p in LoadCellPosition.values) p.key: cell(p).toMap(),
    },
    'tiltDeg': tiltAngleDeg,
    'posture': posture.key,
    'correction': correction.toMap(),
    'source': source.name,
  };

  factory ChairTelemetry.fromMap(Map<String, dynamic> map) {
    final cells = (map['loadCells'] as Map?)?.cast<String, dynamic>() ?? {};
    return ChairTelemetry(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['ts'] as int),
      loadCells: {
        for (final p in LoadCellPosition.values)
          if (cells[p.key] is Map)
            p: LoadCellReading.fromMap(
              p,
              (cells[p.key] as Map).cast<String, dynamic>(),
            ),
      },
      tiltAngleDeg: (map['tiltDeg'] as num?)?.toDouble(),
      posture: PostureState.fromKey(map['posture'] as String?),
      correction: map['correction'] is Map
          ? CorrectionState.fromMap(
              (map['correction'] as Map).cast<String, dynamic>(),
            )
          : const CorrectionState.unavailable(),
      source: DataSource.fromKey(map['source'] as String?),
    );
  }
}
