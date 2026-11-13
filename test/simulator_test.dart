import 'package:flutter_test/flutter_test.dart';
import 'package:smart_chair_dashboard/models/chair_config.dart';
import 'package:smart_chair_dashboard/models/chair_event.dart';
import 'package:smart_chair_dashboard/models/chair_telemetry.dart';
import 'package:smart_chair_dashboard/models/correction_state.dart';
import 'package:smart_chair_dashboard/models/load_cell.dart';
import 'package:smart_chair_dashboard/models/posture_state.dart';
import 'package:smart_chair_dashboard/services/chair_simulator.dart';

List<SimulationStep> run(ChairSimulator sim, int seconds) {
  final t0 = DateTime(2026, 10, 16, 9);
  return [
    for (var i = 0; i < seconds; i++) sim.step(t0.add(Duration(seconds: i))),
  ];
}

void main() {
  test('simulation is deterministic for a given seed', () {
    final a = run(ChairSimulator(seed: 3), 60);
    final b = run(ChairSimulator(seed: 3), 60);
    for (var i = 0; i < a.length; i++) {
      expect(a[i].telemetry.tiltAngleDeg, b[i].telemetry.tiltAngleDeg);
    }
  });

  test('values stay in a plausible range and change smoothly', () {
    final steps = run(
      ChairSimulator(),
      ChairSimulator.scenario.fold(0, (s, e) => s + e.$2) * 2,
    );
    double? prevTilt;
    for (final s in steps) {
      final t = s.telemetry;
      expect(t.source, DataSource.simulated);
      for (final p in LoadCellPosition.values) {
        expect(t.cell(p).kg, inInclusiveRange(0, 35));
      }
      expect(t.tiltAngleDeg!.abs(), lessThan(10));
      if (prevTilt != null) {
        expect((t.tiltAngleDeg! - prevTilt).abs(), lessThan(2.5));
      }
      prevTilt = t.tiltAngleDeg;
    }
  });

  test('scripted scenario visits every posture', () {
    final total = ChairSimulator.scenario.fold(0, (s, e) => s + e.$2);
    final seen = run(
      ChairSimulator(),
      total * 2,
    ).map((s) => s.telemetry.posture).toSet();
    expect(seen, containsAll(PostureState.values));
  });

  test('exceeding the limit triggers correction back toward target', () {
    final sim = ChairSimulator(config: const ChairConfig(maxTiltDeg: 2))
      ..postureOverride = PostureState.leaningBackward;
    final steps = run(sim, 60);
    final statuses = steps.map((s) => s.telemetry.correction.status).toList();
    expect(statuses, contains(CorrectionStatus.correcting));
    expect(steps.last.telemetry.tiltAngleDeg!.abs(), lessThanOrEqualTo(2));
    expect(
      steps.expand((s) => s.events).where((e) => e.type == EventType.tilt),
      isNotEmpty,
    );
  });

  test('a faulty cell reports no value and unknown posture', () {
    final sim = ChairSimulator()..faultyCells.add(LoadCellPosition.frontLeft);
    final t = run(sim, 3).last.telemetry;
    expect(t.cell(LoadCellPosition.frontLeft).isValid, isFalse);
    expect(t.posture, PostureState.unknown);
    expect(t.centerOfPressure, isNull);
  });

  test('telemetry survives a map round-trip (Firebase shape)', () {
    final t = run(ChairSimulator(), 5).last.telemetry;
    final back = ChairTelemetry.fromMap(t.toMap());
    expect(back.timestamp, t.timestamp);
    expect(back.posture, t.posture);
    expect(back.tiltAngleDeg, t.tiltAngleDeg);
    expect(
      back.cell(LoadCellPosition.rearRight).kg,
      t.cell(LoadCellPosition.rearRight).kg,
    );
    expect(back.correction.status, t.correction.status);
  });

  test('config clamps max tilt to 0–5°', () {
    expect(const ChairConfig(maxTiltDeg: 9).maxTiltDeg, 5);
    expect(const ChairConfig(maxTiltDeg: -1).maxTiltDeg, 0);
    expect(
      ChairConfig.fromMap(const ChairConfig(maxTiltDeg: 2.5).toMap())
          .maxTiltDeg,
      2.5,
    );
  });
}
