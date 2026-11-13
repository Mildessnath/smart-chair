import 'dart:math';

import '../models/chair_config.dart';
import '../models/chair_event.dart';
import '../models/chair_telemetry.dart';
import '../models/correction_state.dart';
import '../models/load_cell.dart';
import '../models/posture_state.dart';
import '../utils/formatters.dart';
import '../utils/posture_classifier.dart';

/// Result of advancing the simulation by one tick.
class SimulationStep {
  const SimulationStep(this.telemetry, this.events);
  final ChairTelemetry telemetry;
  final List<ChairEvent> events;
}

/// Deterministic, physically-plausible chair simulation.
///
/// - Load cells follow a scripted posture scenario with first-order smoothing
///   and small Gaussian noise, so curves are continuous rather than jumpy.
/// - Seat tilt = posture-induced disturbance + simulated actuator offset.
/// - Correction runs as MONITOR → DWELL → CORRECT → HOLD → MONITOR:
///   * Forward/backward lean with |tilt| above the limit starts DWELL
///     (`config.dwellSeconds`, 20–30 s). If posture or tilt recovers while
///     waiting, DWELL is cancelled.
///   * After DWELL the simulated actuator moves at a fixed rate toward the 0°
///     target, stops inside a small deadband, then holds for [holdSeconds].
///   * Sideways lean (left/right) never starts a correction.
///   * While [correctionPaused] the actuator never moves and no phase beyond
///     MONITOR is entered, but detection and events keep running.
///
/// Every value produced here is tagged [DataSource.simulated].
class ChairSimulator {
  ChairSimulator({
    int seed = 7,
    this.config = ChairConfig.defaults,
    this.classifier = const PostureClassifier(),
  }) : _rng = Random(seed);

  /// Scripted scenario: (posture, seconds). `unknown` = seat empty.
  static const List<(PostureState, int)> scenario = [
    (PostureState.upright, 45),
    (PostureState.leaningForward, 20),
    (PostureState.upright, 30),
    (PostureState.leaningLeft, 12),
    (PostureState.upright, 25),
    (PostureState.leaningBackward, 50),
    (PostureState.upright, 20),
    (PostureState.crossedLegs, 18),
    (PostureState.upright, 15),
    (PostureState.unknown, 10),
    (PostureState.upright, 15),
    (PostureState.leaningRight, 12),
  ];

  /// Target loads in kg for a ~70 kg occupant (seat carries ~60 kg).
  static const Map<PostureState, List<double>> loadProfiles = {
    // FL, FR, RL, RR
    PostureState.upright: [13, 13, 17, 17],
    PostureState.leaningForward: [20, 20, 10, 10],
    PostureState.leaningBackward: [8, 8, 22, 22],
    PostureState.leaningLeft: [19, 9, 22, 10],
    PostureState.leaningRight: [9, 19, 10, 22],
    // Diagonal pattern (FR + RL heavy): legs crossed.
    PostureState.crossedLegs: [8, 19, 22, 11],
    PostureState.unknown: [0.4, 0.4, 0.4, 0.4],
  };

  /// Seat pitch disturbance (degrees) each posture induces.
  static const Map<PostureState, double> tiltDisturbance = {
    PostureState.upright: 0.8,
    PostureState.leaningForward: -3.6,
    PostureState.leaningBackward: 6.2,
    PostureState.leaningLeft: 1.2,
    PostureState.leaningRight: 1.2,
    PostureState.crossedLegs: 1.0,
    PostureState.unknown: 0.0,
  };

  static const double targetAngleDeg = 0;
  static const double actuatorRateDegPerSec = 0.6;
  static const double settleDeadbandDeg = 0.3;
  static const double actuatorRangeDeg = 8;
  static const int prolongedBadPostureSec = 15;
  static const double holdSeconds = 10;

  final Random _rng;
  final PostureClassifier classifier;

  /// Active configuration; the tilt limit is read every step.
  ChairConfig config;

  /// When set, overrides the scripted scenario.
  PostureState? postureOverride;
  final Set<LoadCellPosition> faultyCells = {};

  /// Occupant weight. The load profiles are defined for [referenceWeightKg]
  /// and scale linearly with this value.
  double bodyWeightKg = referenceWeightKg;

  static const double referenceWeightKg = 70;

  /// When true the actuator is frozen and CORRECT is never entered.
  bool correctionPaused = false;

  ControlPhase _phase = ControlPhase.monitor;
  double _phaseElapsed = 0;
  bool _episodeActive = false;

  ControlPhase get phase => _phase;

  int _segment = 0;
  double _segmentElapsed = 0;
  List<double> _loads = List.of(loadProfiles[PostureState.upright]!);
  double _disturbance = 0.8;
  double _actuator = 0;
  PostureState? _lastPosture;
  double _badPostureSec = 0;
  bool _prolongedWarned = false;
  int _eventSeq = 0;

  PostureState get scriptedPosture => scenario[_segment].$1;

  ChairEvent event(
    DateTime ts,
    EventType type,
    EventSeverity severity,
    String message, {
    String? code,
    Map<String, Object?> args = const {},
  }) => ChairEvent(
    id: 'sim-${ts.millisecondsSinceEpoch}-${_eventSeq++}',
    timestamp: ts,
    type: type,
    severity: severity,
    message: message,
    code: code,
    args: args,
  );

  double _noise(double sigma) {
    // Box–Muller transform.
    final u1 = max(_rng.nextDouble(), 1e-12);
    final u2 = _rng.nextDouble();
    return sigma * sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  SimulationStep step(DateTime now, {double dtSec = 1}) {
    final events = <ChairEvent>[];

    // 1. Advance the scenario.
    _segmentElapsed += dtSec;
    if (_segmentElapsed >= scenario[_segment].$2) {
      _segmentElapsed = 0;
      _segment = (_segment + 1) % scenario.length;
    }
    final driving = postureOverride ?? scriptedPosture;

    // 2. Load cells: first-order lag toward the posture profile + noise.
    final scale = bodyWeightKg / referenceWeightKg;
    final target = [for (final v in loadProfiles[driving]!) v * scale];
    final alpha = 1 - exp(-dtSec / 2.5); // ~2.5 s time constant
    _loads = [
      for (var i = 0; i < 4; i++)
        max(0.0, _loads[i] + (target[i] - _loads[i]) * alpha + _noise(0.15)),
    ];
    final cells = {
      for (final p in LoadCellPosition.values)
        p: faultyCells.contains(p)
            ? LoadCellReading(position: p, kg: null, health: SensorHealth.fault)
            : LoadCellReading(position: p, kg: _loads[p.index]),
    };

    // 3. Posture (heuristic, from the simulated load cells).
    final posture = classifier.classify(cells).posture;
    if (posture != _lastPosture) {
      if (_lastPosture != null) {
        events.add(
          event(
            now,
            EventType.posture,
            EventSeverity.info,
            'Posture changed: ${_lastPosture!.label} → ${posture.label}',
            code: 'posture_changed',
            args: {'from': _lastPosture!.name, 'to': posture.name},
          ),
        );
      }
      _lastPosture = posture;
    }
    if (posture.isBad) {
      _badPostureSec += dtSec;
      if (_badPostureSec >= prolongedBadPostureSec && !_prolongedWarned) {
        _prolongedWarned = true;
        events.add(
          event(
            now,
            EventType.posture,
            EventSeverity.warning,
            '${posture.label} for over ${prolongedBadPostureSec}s',
            code: 'posture_prolonged',
            args: {'posture': posture.name, 'seconds': prolongedBadPostureSec},
          ),
        );
      }
    } else {
      _badPostureSec = 0;
      _prolongedWarned = false;
    }

    // 4. Tilt: disturbance follows posture with lag; actuator corrects.
    final tiltTarget = tiltDisturbance[driving]!;
    _disturbance += (tiltTarget - _disturbance) * (1 - exp(-dtSec / 3));
    final limit = config.maxTiltDeg;
    final dwellSec = config.dwellSeconds.toDouble();

    // Only front/back lean is ever corrected; sideways lean is not.
    final correctable =
        posture == PostureState.leaningForward ||
        posture == PostureState.leaningBackward;
    bool overLimit() =>
        (_disturbance + _actuator - targetAngleDeg).abs() > limit + 0.05;
    final condition = correctable && overLimit();

    // Detection and notification run regardless of pause state.
    if (condition && !_episodeActive) {
      _episodeActive = true;
      events.add(
        event(
          now,
          EventType.tilt,
          EventSeverity.warning,
          'Tilt ${formatSignedDeg(_disturbance + _actuator)} exceeds limit '
          '±${formatDeg(limit)}'
          '${correctionPaused ? ' — correction paused' : ''}',
          code: 'tilt_exceeded',
          args: {
            'angle': _disturbance + _actuator,
            'limit': limit,
            'paused': correctionPaused,
          },
        ),
      );
    }
    if (!condition) _episodeActive = false;

    switch (_phase) {
      case ControlPhase.monitor:
        if (!correctionPaused && condition) {
          _enterPhase(ControlPhase.dwell);
          events.add(
            event(
              now,
              EventType.correction,
              EventSeverity.info,
              'Bad posture persists — correction starts in '
              '${config.dwellSeconds}s unless it improves (simulated)',
              code: 'dwell_started',
              args: {'seconds': config.dwellSeconds},
            ),
          );
        } else if (!correctionPaused && !correctable) {
          // User sits properly again: release the actuator offset.
          _moveActuatorToward(0, dtSec);
        }
      case ControlPhase.dwell:
        if (correctionPaused || !condition) {
          _enterPhase(ControlPhase.monitor);
          events.add(
            event(
              now,
              EventType.correction,
              EventSeverity.info,
              correctionPaused
                  ? 'Correction paused — countdown cancelled (simulated)'
                  : 'Posture improved — correction cancelled (simulated)',
              code: 'dwell_cancelled',
              args: {'reason': correctionPaused ? 'paused' : 'improved'},
            ),
          );
        } else {
          _phaseElapsed += dtSec;
          if (_phaseElapsed >= dwellSec) {
            _enterPhase(ControlPhase.correct);
            events.add(
              event(
                now,
                EventType.correction,
                EventSeverity.info,
                'Correction started (simulated)',
                code: 'correction_started',
              ),
            );
          }
        }
      case ControlPhase.correct:
        if (correctionPaused) {
          _enterPhase(ControlPhase.monitor);
          events.add(
            event(
              now,
              EventType.correction,
              EventSeverity.info,
              'Correction paused — actuator stopped (simulated)',
              code: 'correction_stopped',
            ),
          );
        } else {
          _moveActuatorToward(targetAngleDeg, dtSec, includeDisturbance: true);
          final angle = _disturbance + _actuator;
          if ((angle - targetAngleDeg).abs() <= settleDeadbandDeg) {
            _enterPhase(ControlPhase.hold);
            events.add(
              event(
                now,
                EventType.correction,
                EventSeverity.info,
                'Correction settled at ${formatSignedDeg(angle)} (simulated)',
                code: 'correction_settled',
                args: {'angle': angle},
              ),
            );
          }
        }
      case ControlPhase.hold:
        if (correctionPaused) {
          _enterPhase(ControlPhase.monitor);
        } else {
          _phaseElapsed += dtSec;
          if (_phaseElapsed >= holdSeconds) _enterPhase(ControlPhase.monitor);
        }
    }

    final angle = _disturbance + _actuator;
    final tilt = angle + _noise(0.05);
    final status = switch (_phase) {
      ControlPhase.correct => CorrectionStatus.correcting,
      ControlPhase.dwell => CorrectionStatus.pending,
      _ =>
        correctionPaused && (angle - targetAngleDeg).abs() > limit + 0.05
            ? CorrectionStatus.paused
            : CorrectionStatus.withinLimit,
    };

    final telemetry = ChairTelemetry(
      timestamp: now,
      loadCells: cells,
      tiltAngleDeg: tilt,
      posture: posture,
      correction: CorrectionState(
        actualAngleDeg: tilt,
        targetAngleDeg: targetAngleDeg,
        status: status,
        source: DataSource.simulated,
        phase: _phase,
        correctionPaused: correctionPaused,
        dwellRemaining: _phase == ControlPhase.dwell
            ? (dwellSec - _phaseElapsed).ceil()
            : null,
      ),
      source: DataSource.simulated,
    );
    return SimulationStep(telemetry, events);
  }

  void _enterPhase(ControlPhase phase) {
    _phase = phase;
    _phaseElapsed = 0;
  }

  /// Moves the actuator offset so the seat angle approaches [goal].
  void _moveActuatorToward(
    double goal,
    double dtSec, {
    bool includeDisturbance = false,
  }) {
    final current = includeDisturbance ? _disturbance + _actuator : _actuator;
    final error = current - goal;
    final move = min(actuatorRateDegPerSec * dtSec, error.abs());
    _actuator = (_actuator - error.sign * move).clamp(
      -actuatorRangeDeg,
      actuatorRangeDeg,
    );
  }
}
