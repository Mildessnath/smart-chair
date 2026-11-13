import '../models/chair_telemetry.dart';
import '../models/posture_state.dart';

/// Samples further apart than this are treated as a gap (no data).
const Duration maxSampleGap = Duration(seconds: 3);

/// Duration each sample "covers": time to the next sample, capped at the gap.
Iterable<(ChairTelemetry, Duration)> _weighted(List<ChairTelemetry> h) sync* {
  for (var i = 0; i < h.length - 1; i++) {
    final dt = h[i + 1].timestamp.difference(h[i].timestamp);
    if (dt <= maxSampleGap && !dt.isNegative) yield (h[i], dt);
  }
}

/// How long the latest posture has been held continuously.
Duration currentPostureDuration(List<ChairTelemetry> h) {
  if (h.length < 2) return Duration.zero;
  final current = h.last.posture;
  var start = h.last.timestamp;
  for (var i = h.length - 2; i >= 0; i--) {
    if (h[i].posture != current) break;
    if (start.difference(h[i].timestamp) > maxSampleGap) break;
    start = h[i].timestamp;
  }
  return h.last.timestamp.difference(start);
}

Map<PostureState, Duration> postureBreakdown(List<ChairTelemetry> h) {
  final out = {for (final p in PostureState.values) p: Duration.zero};
  for (final (t, dt) in _weighted(h)) {
    out[t.posture] = out[t.posture]! + dt;
  }
  return out;
}

class TiltStats {
  const TiltStats({
    required this.min,
    required this.max,
    required this.timeOverLimit,
    required this.covered,
  });
  final double? min;
  final double? max;
  final Duration timeOverLimit;
  final Duration covered;
}

TiltStats tiltStats(List<ChairTelemetry> h, double limitDeg) {
  double? lo, hi;
  for (final t in h) {
    final a = t.tiltAngleDeg;
    if (a == null) continue;
    lo = lo == null || a < lo ? a : lo;
    hi = hi == null || a > hi ? a : hi;
  }
  var over = Duration.zero, covered = Duration.zero;
  for (final (t, dt) in _weighted(h)) {
    final a = t.tiltAngleDeg;
    if (a == null) continue;
    covered += dt;
    if (a.abs() > limitDeg) over += dt;
  }
  return TiltStats(min: lo, max: hi, timeOverLimit: over, covered: covered);
}
