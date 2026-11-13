import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_chair_dashboard/models/chair_config.dart';
import 'package:smart_chair_dashboard/models/chair_event.dart';
import 'package:smart_chair_dashboard/models/correction_state.dart';
import 'package:smart_chair_dashboard/models/posture_state.dart';
import 'package:smart_chair_dashboard/providers/dashboard_controller.dart';
import 'package:smart_chair_dashboard/repositories/chair_repository.dart';
import 'package:smart_chair_dashboard/repositories/mock_chair_repository.dart';
import 'package:smart_chair_dashboard/services/chair_simulator.dart';

final _t0 = DateTime(2026, 11, 13, 9);

/// Steps [sim] for [seconds] one-second ticks starting at tick [from].
List<SimulationStep> run(ChairSimulator sim, int seconds, {int from = 0}) => [
  for (var i = 0; i < seconds; i++)
    sim.step(_t0.add(Duration(seconds: from + i))),
];

Iterable<ControlPhase> phases(List<SimulationStep> s) =>
    s.map((e) => e.telemetry.correction.phase);

ChairSimulator backwardSim({double limit = 2, bool paused = false}) =>
    ChairSimulator(config: ChairConfig(maxTiltDeg: limit))
      ..postureOverride = PostureState.leaningBackward
      ..correctionPaused = paused;

void main() {
  test(
    'bad posture enters DWELL with a countdown from the configured time',
    () {
      final steps = run(backwardSim(), 15);
      final dwell = steps
          .where((s) => s.telemetry.correction.phase == ControlPhase.dwell)
          .toList();
      expect(dwell, isNotEmpty);

      final remaining = dwell
          .map((s) => s.telemetry.correction.dwellRemaining!)
          .toList();
      expect(remaining.first, ChairConfig.defaultDwellSeconds);
      for (var i = 1; i < remaining.length; i++) {
        expect(remaining[i], remaining[i - 1] - 1);
      }
      expect(dwell.first.telemetry.correction.status, CorrectionStatus.pending);
      // The actuator has not moved yet: seat angle only follows the posture.
      expect(
        steps.every(
          (s) => s.telemetry.correction.status != CorrectionStatus.correcting,
        ),
        isTrue,
      );
    },
  );

  test('dwell uses the duration from config (clamped to 20–30 s)', () {
    final sim = ChairSimulator(
      config: const ChairConfig(maxTiltDeg: 2, dwellSeconds: 99),
    )..postureOverride = PostureState.leaningBackward;
    final first = run(
      sim,
      15,
    ).firstWhere((s) => s.telemetry.correction.phase == ControlPhase.dwell);
    expect(first.telemetry.correction.dwellRemaining, 30);
  });

  test('full cycle MONITOR → DWELL → CORRECT → HOLD → MONITOR', () {
    final steps = run(backwardSim(), 90);
    final seq = <ControlPhase>[];
    for (final p in phases(steps)) {
      if (seq.isEmpty || seq.last != p) seq.add(p);
    }
    expect(seq, [
      ControlPhase.monitor,
      ControlPhase.dwell,
      ControlPhase.correct,
      ControlPhase.hold,
      ControlPhase.monitor,
    ]);
    expect(steps.last.telemetry.tiltAngleDeg!.abs(), lessThan(1));
  });

  test('DWELL is cancelled when posture improves', () {
    final sim = backwardSim();
    final before = run(sim, 12);
    expect(phases(before).last, ControlPhase.dwell);

    sim.postureOverride = PostureState.upright;
    final after = run(sim, 40, from: 12);
    expect(phases(after).last, ControlPhase.monitor);
    expect(
      phases(after).contains(ControlPhase.correct),
      isFalse,
      reason: 'must never correct after cancelling',
    );
    expect(after.last.telemetry.correction.dwellRemaining, isNull);
    expect(
      after
          .expand((s) => s.events)
          .any(
            (e) =>
                e.type == EventType.correction &&
                e.message.contains('cancelled'),
          ),
      isTrue,
    );
  });

  test('paused never enters CORRECT and never moves the actuator', () {
    final steps = run(backwardSim(paused: true), 120);
    for (final s in steps) {
      final c = s.telemetry.correction;
      expect(c.phase, ControlPhase.monitor);
      expect(c.correctionPaused, isTrue);
      expect(c.status, isNot(CorrectionStatus.correcting));
    }
    // Seat angle stays at the posture disturbance (~6.2°), never corrected.
    expect(steps.last.telemetry.tiltAngleDeg, greaterThan(5.5));
    expect(steps.last.telemetry.correction.status, CorrectionStatus.paused);
  });

  test('paused still detects posture and raises notifications', () {
    final steps = run(backwardSim(paused: true), 60);
    expect(steps.last.telemetry.posture, PostureState.leaningBackward);
    final events = steps.expand((s) => s.events).toList();
    expect(
      events.where(
        (e) =>
            e.type == EventType.tilt &&
            e.severity == EventSeverity.warning &&
            e.message.contains('correction paused'),
      ),
      isNotEmpty,
    );
    expect(
      events.where(
        (e) =>
            e.type == EventType.posture && e.severity == EventSeverity.warning,
      ),
      isNotEmpty,
      reason: 'prolonged bad posture warning',
    );
  });

  test('pausing during CORRECT freezes the actuator', () {
    final sim = backwardSim();
    var i = 0;
    var steps = <SimulationStep>[];
    while (steps.isEmpty || phases(steps).last != ControlPhase.correct) {
      steps = [...steps, ...run(sim, 1, from: i++)];
      expect(i, lessThan(80), reason: 'should reach CORRECT');
    }
    sim.correctionPaused = true;
    final frozen = run(sim, 10, from: i);
    expect(phases(frozen).toSet(), {ControlPhase.monitor});
    final angles = frozen.map((s) => s.telemetry.tiltAngleDeg!).toList();
    // Only the lagging posture disturbance and sensor noise may remain.
    expect(angles.last - angles.first, closeTo(0, 0.6));
  });

  test('resuming after a pause starts a fresh DWELL', () {
    final sim = backwardSim(paused: true);
    run(sim, 20);
    sim.correctionPaused = false;
    final steps = run(sim, 5, from: 20);
    expect(phases(steps), contains(ControlPhase.dwell));
  });

  for (final posture in [PostureState.leaningLeft, PostureState.leaningRight]) {
    test('${posture.label} never starts a correction', () {
      // Limit 0: the sideways disturbance is above the limit, yet no action.
      final sim = ChairSimulator(config: const ChairConfig(maxTiltDeg: 0))
        ..postureOverride = posture;
      final steps = run(sim, 120);
      expect(steps.last.telemetry.posture, posture);
      expect(phases(steps).toSet(), {ControlPhase.monitor});
      expect(
        steps.every(
          (s) => s.telemetry.correction.status != CorrectionStatus.correcting,
        ),
        isTrue,
      );
    });
  }

  test('forward lean is corrected the same way', () {
    final sim = ChairSimulator(config: const ChairConfig(maxTiltDeg: 2))
      ..postureOverride = PostureState.leaningForward;
    expect(phases(run(sim, 90)), contains(ControlPhase.correct));
  });

  test('actuator releases after the user sits upright again', () {
    final sim = backwardSim();
    run(sim, 60); // corrected, offset ≈ -6°
    sim.postureOverride = PostureState.upright;
    final steps = run(sim, 40, from: 60);
    expect(steps.last.telemetry.tiltAngleDeg!.abs(), lessThan(1.5));
  });

  test('new fields round-trip and old payloads still decode', () {
    const state = CorrectionState(
      actualAngleDeg: 4.2,
      targetAngleDeg: 0,
      status: CorrectionStatus.pending,
      source: DataSource.simulated,
      phase: ControlPhase.dwell,
      correctionPaused: true,
      dwellRemaining: 17,
    );
    final back = CorrectionState.fromMap(state.toMap());
    expect(back.phase, ControlPhase.dwell);
    expect(back.correctionPaused, isTrue);
    expect(back.dwellRemaining, 17);
    expect(back.status, CorrectionStatus.pending);

    final old = CorrectionState.fromMap({
      'actualDeg': 1.0,
      'targetDeg': 0.0,
      'status': 'withinLimit',
      'source': 'simulated',
    });
    expect(old.phase, ControlPhase.monitor);
    expect(old.correctionPaused, isFalse);
    expect(old.dwellRemaining, isNull);

    final oldConfig = ChairConfig.fromMap({'maxTiltDeg': 2.0});
    expect(oldConfig.dwellSeconds, ChairConfig.defaultDwellSeconds);
    expect(
      ChairConfig.fromMap(
        const ChairConfig(maxTiltDeg: 1, dwellSeconds: 22).toMap(),
      ).dwellSeconds,
      22,
    );
  });

  test('pause state set on the device before the UI connects is shown', () {
    fakeAsync((async) {
      DateTime clock() => _t0.add(async.elapsed);
      final repo = MockChairRepository(loadDelay: Duration.zero, clock: clock);
      repo.setCorrectionPaused(true); // e.g. paused from another client
      final ctrl = DashboardController(
        repositoryFactory: ({required demoMode, required config}) => repo,
        clock: clock,
      )..load();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 2));
      expect(ctrl.correctionPaused, isTrue);

      // The user's resume is reflected immediately, before the next tick.
      ctrl.setCorrectionPaused(false);
      async.flushMicrotasks();
      expect(ctrl.correctionPaused, isFalse);
      async.elapse(const Duration(seconds: 2));
      expect(ctrl.correctionPaused, isFalse);
      ctrl.dispose();
      async.flushTimers();
    });
  });

  test('controller pause flows through to telemetry and the event log', () {
    fakeAsync((async) {
      // Clock follows the fake timers; the wall clock would give consecutive
      // ticks identical timestamps, which the controller drops as duplicates.
      DateTime clock() => _t0.add(async.elapsed);
      ChairRepository factory({
        required bool demoMode,
        required ChairConfig config,
      }) => MockChairRepository(
        initialConfig: config,
        loadDelay: Duration.zero,
        clock: clock,
      );
      final ctrl = DashboardController(repositoryFactory: factory, clock: clock)
        ..load();
      async.flushMicrotasks();
      expect(ctrl.correctionPaused, isFalse);

      ctrl.setCorrectionPaused(true);
      async.flushMicrotasks();
      expect(ctrl.correctionPaused, isTrue);
      async.elapse(const Duration(seconds: 2));
      expect(ctrl.latest!.correction.correctionPaused, isTrue);
      expect(
        ctrl.events.any((e) => e.message.startsWith('Correction paused')),
        isTrue,
      );

      ctrl.setCorrectionPaused(false);
      async.elapse(const Duration(seconds: 2));
      expect(ctrl.latest!.correction.correctionPaused, isFalse);
      ctrl.dispose();
      async.flushTimers();
    });
  });
}
