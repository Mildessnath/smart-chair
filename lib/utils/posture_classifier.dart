import '../models/load_cell.dart';
import '../models/posture_state.dart';
import 'pressure_math.dart';

/// SIMULATION HEURISTIC — not a validated posture classifier.
///
/// Classifies posture from the center of pressure of four load cells using
/// fixed thresholds that were chosen to match the simulator's load profiles.
/// A real classifier must be calibrated per chair/user and validated against
/// a reference (e.g. video annotation) before any claims are made.
class PostureClassifier {
  const PostureClassifier({
    this.threshold = 0.15,
    this.foreBaseline = -0.13,
    this.diagonalThreshold = 0.25,
  });

  /// Minimum normalized CoP shift that counts as leaning.
  final double threshold;

  /// Typical fore/aft CoP when sitting upright (people load the rear more).
  final double foreBaseline;

  /// Minimum normalized diagonal load imbalance
  /// `((FL + RR) − (FR + RL)) / total` that counts as crossed legs. Leaning
  /// moves the center of pressure but keeps the diagonals balanced.
  final double diagonalThreshold;

  PostureClassification classify(Map<LoadCellPosition, LoadCellReading> cells) {
    final kg = <LoadCellPosition, double>{};
    for (final p in LoadCellPosition.values) {
      final r = cells[p];
      if (r == null || !r.isValid) {
        return const PostureClassification(
          PostureState.unknown,
          'Sensor fault or missing reading',
        );
      }
      kg[p] = r.kg!;
    }
    final cop = centerOfPressureFromLoads(kg);
    if (cop == null) {
      return const PostureClassification(PostureState.unknown, 'Seat empty');
    }
    final total = kg.values.fold<double>(0, (a, b) => a + b);
    final diagonal =
        ((kg[LoadCellPosition.frontLeft]! + kg[LoadCellPosition.rearRight]!) -
            (kg[LoadCellPosition.frontRight]! +
                kg[LoadCellPosition.rearLeft]!)) /
        total;
    if (diagonal.abs() >= diagonalThreshold) {
      return const PostureClassification(
        PostureState.crossedLegs,
        'Diagonal load imbalance',
      );
    }
    final lateral = cop.x;
    final fore = cop.y - foreBaseline;
    if (lateral.abs() < threshold && fore.abs() < threshold) {
      return const PostureClassification(PostureState.upright, 'CoP centered');
    }
    if (fore.abs() >= lateral.abs()) {
      return fore > 0
          ? const PostureClassification(
              PostureState.leaningForward,
              'CoP shifted to front',
            )
          : const PostureClassification(
              PostureState.leaningBackward,
              'CoP shifted to rear',
            );
    }
    return lateral > 0
        ? const PostureClassification(
            PostureState.leaningRight,
            'CoP shifted to right',
          )
        : const PostureClassification(
            PostureState.leaningLeft,
            'CoP shifted to left',
          );
  }
}

class PostureClassification {
  const PostureClassification(this.posture, this.reason);
  final PostureState posture;
  final String reason;
}
