import 'dart:async';
import 'dart:math';

import '../models/chair_config.dart';
import '../models/chair_event.dart';
import '../models/chair_telemetry.dart';
import '../models/daily_posture_summary.dart';
import '../models/device_status.dart';
import '../models/load_cell.dart';
import '../models/posture_state.dart';
import '../services/chair_simulator.dart';
import '../utils/formatters.dart';
import 'chair_repository.dart';
import 'simulation_controls.dart';

/// In-memory repository driven by [ChairSimulator].
///
/// Seeds a few minutes of history on construction, then produces one sample
/// per [tickInterval]. All data is simulated and tagged as such.
class MockChairRepository implements ChairRepository, SimulationControls {
  MockChairRepository({
    ChairConfig initialConfig = ChairConfig.defaults,
    this.tickInterval = const Duration(seconds: 1),
    this.loadDelay = const Duration(milliseconds: 600),
    Duration seedHistory = const Duration(minutes: 3),
    int seed = 7,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _config = initialConfig,
       _seed = seed,
       _sim = ChairSimulator(seed: seed, config: initialConfig) {
    _seedData(seedHistory);
    _timer = Timer.periodic(tickInterval, (_) => _tick());
  }

  static const int _maxHistory = 900;
  static const int _maxEvents = 300;

  final Duration tickInterval;
  final Duration loadDelay;
  final DateTime Function() _clock;
  final int _seed;
  final ChairSimulator _sim;
  ChairConfig _config;
  Timer? _timer;

  final List<ChairTelemetry> _history = [];
  final List<ChairEvent> _events = []; // oldest first
  final List<DailyPostureSummary> _daily = []; // oldest first
  DateTime? _lastHeartbeat;
  SimLink _link = SimLink.demo;
  bool _failNextLoad = false;
  int _warningIndex = 0;

  final _telemetryCtrl = StreamController<ChairTelemetry>.broadcast();
  final _statusCtrl = StreamController<DeviceStatus>.broadcast();
  final _eventCtrl = StreamController<ChairEvent>.broadcast();
  final _dailyCtrl = StreamController<List<DailyPostureSummary>>.broadcast();

  double get _dtSec => tickInterval.inMilliseconds / 1000;

  // ---------------------------------------------------------------- seeding

  void _seedData(Duration window) {
    final now = _clock();
    final today = dayOf(now);
    final rng = Random(_seed * 31);

    for (var i = 6; i >= 1; i--) {
      _daily.add(
        DailyPostureSummary(
          date: today.subtract(Duration(days: i)),
          goodMinutes: 150 + rng.nextDouble() * 150,
          badMinutes: 40 + rng.nextDouble() * 80,
        ),
      );
    }
    // Today so far: scaled by how much of an 08:00–17:00 day has elapsed.
    final elapsed = ((now.hour + now.minute / 60) - 8) / 9;
    final frac = elapsed.clamp(0.0, 1.0);
    _daily.add(
      DailyPostureSummary(
        date: today,
        goodMinutes: 220 * frac,
        badMinutes: 70 * frac,
      ),
    );

    final steps = window.inMilliseconds ~/ tickInterval.inMilliseconds;
    for (var i = steps; i >= 1; i--) {
      final ts = now.subtract(tickInterval * i);
      _apply(_sim.step(ts, dtSec: _dtSec), emit: false);
    }
    _addEvent(
      _sim.event(
        now,
        EventType.system,
        EventSeverity.info,
        'Mock repository started — all data is simulated',
      ),
      emit: false,
    );
  }

  // ------------------------------------------------------------------ ticks

  void _tick() {
    if (_link == SimLink.offline) {
      _statusCtrl.add(_status());
      return;
    }
    _apply(_sim.step(_clock(), dtSec: _dtSec), emit: true);
  }

  void _apply(SimulationStep step, {required bool emit}) {
    final t = step.telemetry;
    _history.add(t);
    if (_history.length > _maxHistory) _history.removeAt(0);
    _lastHeartbeat = t.timestamp;

    final dtMin = _dtSec / 60;
    final idx = _daily.lastIndexWhere((d) => isSameDay(d.date, t.timestamp));
    if (idx < 0) {
      _daily.add(
        DailyPostureSummary(
          date: dayOf(t.timestamp),
          goodMinutes: 0,
          badMinutes: 0,
        ),
      );
      if (_daily.length > 30) _daily.removeAt(0);
    }
    final i = idx < 0 ? _daily.length - 1 : idx;
    if (t.posture.isGood) _daily[i] = _daily[i].add(good: dtMin);
    if (t.posture.isBad) _daily[i] = _daily[i].add(bad: dtMin);

    for (final e in step.events) {
      _addEvent(e, emit: emit);
    }
    if (emit) {
      _telemetryCtrl.add(t);
      _statusCtrl.add(_status());
      _dailyCtrl.add(List.unmodifiable(_daily));
    }
  }

  void _addEvent(ChairEvent e, {bool emit = true}) {
    _events.add(e);
    if (_events.length > _maxEvents) _events.removeAt(0);
    if (emit && !_eventCtrl.isClosed) _eventCtrl.add(e);
  }

  DeviceStatus _status() {
    if (_link == SimLink.offline) {
      return DeviceStatus.offline(lastHeartbeat: _lastHeartbeat);
    }
    final hb = _lastHeartbeat;
    return DeviceStatus(
      connection: _link == SimLink.online
          ? DeviceConnection.online
          : DeviceConnection.demo,
      lastHeartbeat: hb,
      loadCellHealth: {
        for (final p in LoadCellPosition.values)
          p: _sim.faultyCells.contains(p)
              ? SensorHealth.fault
              : SensorHealth.ok,
      },
      tiltSensorHealth: SensorHealth.ok,
      firmwareVersion: 'sim-0.1.0',
      wifiRssiDbm: hb == null ? null : -58 + (hb.second % 7) - 3,
    );
  }

  Future<void> _delay() async {
    if (loadDelay > Duration.zero) await Future<void>.delayed(loadDelay);
  }

  // ------------------------------------------------------------ repository

  @override
  String get configDestination => 'local app state (simulation only)';

  @override
  Future<ChairConfig> fetchConfig() async {
    await _delay();
    if (_failNextLoad) {
      _failNextLoad = false;
      throw StateError('Simulated load failure (mock repository)');
    }
    return _config;
  }

  @override
  Future<DeviceStatus> fetchDeviceStatus() async {
    await _delay();
    return _status();
  }

  @override
  Future<List<ChairTelemetry>> fetchTelemetryHistory({
    required Duration window,
  }) async {
    await _delay();
    final from = _clock().subtract(window);
    return _history.where((t) => t.timestamp.isAfter(from)).toList();
  }

  @override
  Future<List<DailyPostureSummary>> fetchDailySummaries({int days = 7}) async {
    await _delay();
    final start = max(0, _daily.length - days);
    return List.unmodifiable(_daily.sublist(start));
  }

  @override
  Future<List<ChairEvent>> fetchEvents({int limit = 100}) async {
    await _delay();
    return _events.reversed.take(limit).toList();
  }

  @override
  Stream<ChairTelemetry> watchLatestTelemetry() => _telemetryCtrl.stream;

  @override
  Stream<DeviceStatus> watchDeviceStatus() => _statusCtrl.stream;

  @override
  Stream<ChairEvent> watchNewEvents() => _eventCtrl.stream;

  @override
  Stream<List<DailyPostureSummary>> watchDailySummaries() => _dailyCtrl.stream;

  @override
  Future<void> saveConfig(ChairConfig config) async {
    if (loadDelay > Duration.zero) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    _config = config;
    _sim.config = config;
    _addEvent(
      _sim.event(
        _clock(),
        EventType.config,
        EventSeverity.info,
        'Max tilt set to ${formatDeg(config.maxTiltDeg)} — saved to local '
        'app state only (not sent to device)',
      ),
    );
  }

  @override
  Future<void> setCorrectionPaused(bool paused) async {
    if (_sim.correctionPaused == paused) return;
    _sim.correctionPaused = paused;
    _addEvent(
      _sim.event(
        _clock(),
        EventType.correction,
        EventSeverity.info,
        paused
            ? 'Correction paused — detection and notifications continue '
                  '(simulated)'
            : 'Correction resumed (simulated)',
        code: 'correction_pause_changed',
        args: {'paused': paused},
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await Future.wait([
      _telemetryCtrl.close(),
      _statusCtrl.close(),
      _eventCtrl.close(),
      _dailyCtrl.close(),
    ]);
  }

  // ---------------------------------------------------- simulation controls

  @override
  SimLink get link => _link;

  @override
  void setLink(SimLink link) {
    if (link == _link) return;
    final was = _link;
    _link = link;
    _addEvent(
      _sim.event(
        _clock(),
        EventType.connection,
        link == SimLink.offline ? EventSeverity.warning : EventSeverity.info,
        link == SimLink.offline
            ? 'Device connection lost (simulated)'
            : 'Link changed: ${was.label} → ${link.label}',
        code: link == SimLink.offline ? 'link_lost' : 'link_changed',
      ),
    );
    _statusCtrl.add(_status());
  }

  @override
  PostureState? get postureOverride => _sim.postureOverride;

  @override
  void setPostureOverride(PostureState? posture) {
    _sim.postureOverride = posture;
    _addEvent(
      _sim.event(
        _clock(),
        EventType.system,
        EventSeverity.info,
        posture == null
            ? 'Simulation: following scripted scenario'
            : 'Simulation: forcing ${posture.label}',
      ),
    );
  }

  @override
  Set<LoadCellPosition> get faultyCells => Set.unmodifiable(_sim.faultyCells);

  @override
  void setSensorFault(LoadCellPosition position, bool faulty) {
    final changed = faulty
        ? _sim.faultyCells.add(position)
        : _sim.faultyCells.remove(position);
    if (!changed) return;
    _addEvent(
      _sim.event(
        _clock(),
        EventType.sensor,
        faulty ? EventSeverity.error : EventSeverity.info,
        faulty
            ? 'Load cell ${position.label}: no valid reading (simulated fault)'
            : 'Load cell ${position.label} recovered',
        code: 'sensor_fault_changed',
        args: {'position': position.name, 'faulty': faulty},
      ),
    );
    _statusCtrl.add(_status());
  }

  static const _warnings = [
    (EventSeverity.warning, 'Actuator current above nominal (simulated)'),
    (EventSeverity.error, 'Tilt sensor read timeout (simulated)'),
    (EventSeverity.warning, 'Wi-Fi signal weak: -82 dBm (simulated)'),
  ];

  @override
  void injectWarning() {
    final (severity, message) = _warnings[_warningIndex++ % _warnings.length];
    _addEvent(_sim.event(_clock(), EventType.system, severity, message));
  }

  @override
  double get bodyWeightKg => _sim.bodyWeightKg;

  @override
  void setBodyWeight(double kg) => _sim.bodyWeightKg = kg;

  @override
  bool get failNextLoad => _failNextLoad;

  @override
  void setFailNextLoad(bool value) => _failNextLoad = value;
}
