import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chair_config.dart';
import '../models/chair_event.dart';
import '../models/chair_telemetry.dart';
import '../models/daily_posture_summary.dart';
import '../models/device_status.dart';
import '../repositories/chair_repository.dart';
import '../repositories/simulation_controls.dart';

enum LoadStatus { loading, ready, error }

/// Creates the repository for the given mode. In the Firebase stage:
/// `demo ? MockChairRepository(...) : FirebaseChairRepository(...)`.
typedef RepositoryFactory = ChairRepository Function({
  required bool demoMode,
  required ChairConfig config,
});

/// Single source of UI state. Widgets read from here, never from a repository.
class DashboardController extends ChangeNotifier {
  DashboardController({
    required RepositoryFactory repositoryFactory,
    bool demoMode = true,
    this.historyWindow = const Duration(minutes: 5),
    this.staleAfter = const Duration(seconds: 5),
    this.tickInterval = const Duration(seconds: 1),
    DateTime Function()? clock,
  }) : _factory = repositoryFactory,
       _demoMode = demoMode,
       _clock = clock ?? DateTime.now {
    _repo = _factory(demoMode: demoMode, config: _config);
  }

  final RepositoryFactory _factory;
  final DateTime Function() _clock;
  final Duration historyWindow;
  final Duration staleAfter;
  final Duration tickInterval;

  late ChairRepository _repo;
  final List<StreamSubscription<Object?>> _subs = [];
  Timer? _clockTimer;
  bool _disposed = false;
  int _loadGeneration = 0;

  LoadStatus _status = LoadStatus.loading;
  Object? _error;
  bool _demoMode;
  ChairConfig _config = ChairConfig.defaults;
  DeviceStatus? _device;
  final List<ChairTelemetry> _history = [];
  List<ChairEvent> _events = const []; // newest first
  List<DailyPostureSummary> _daily = const [];

  static const int maxEvents = 200;

  // ---------------------------------------------------------------- getters

  LoadStatus get status => _status;
  Object? get error => _error;
  bool get demoMode => _demoMode;
  ChairConfig get config => _config;
  DeviceStatus? get device => _device;
  List<ChairTelemetry> get history => List.unmodifiable(_history);
  List<ChairEvent> get events => _events;
  List<DailyPostureSummary> get dailySummaries => _daily;
  ChairTelemetry? get latest => _history.isEmpty ? null : _history.last;
  String get configDestination => _repo.configDestination;
  DateTime get now => _clock();

  SimulationControls? get simulation =>
      _repo is SimulationControls ? _repo as SimulationControls : null;

  Duration? get dataAge =>
      latest == null ? null : now.difference(latest!.timestamp);

  /// Latest sample exists but is older than [staleAfter].
  bool get isStale => dataAge != null && dataAge! > staleAfter;

  DailyPostureSummary? get today {
    if (_daily.isEmpty) return null;
    final t = now;
    final last = _daily.last;
    return last.date.year == t.year &&
            last.date.month == t.month &&
            last.date.day == t.day
        ? last
        : null;
  }

  // ---------------------------------------------------------------- loading

  Future<void> load() async {
    final gen = ++_loadGeneration;
    _cancelSubs();
    _status = LoadStatus.loading;
    _error = null;
    _notify();
    try {
      final results = await Future.wait<Object>([
        _repo.fetchConfig(),
        _repo.fetchDeviceStatus(),
        _repo.fetchTelemetryHistory(window: historyWindow),
        _repo.fetchEvents(limit: maxEvents),
        _repo.fetchDailySummaries(days: 7),
      ]);
      if (gen != _loadGeneration || _disposed) return;
      _config = results[0] as ChairConfig;
      _device = results[1] as DeviceStatus;
      _history
        ..clear()
        ..addAll(results[2] as List<ChairTelemetry>);
      _events = List.of(results[3] as List<ChairEvent>);
      _daily = results[4] as List<DailyPostureSummary>;
      _subscribe();
      _status = LoadStatus.ready;
    } catch (e) {
      if (gen != _loadGeneration || _disposed) return;
      _error = e;
      _status = LoadStatus.error;
    }
    _clockTimer ??= Timer.periodic(tickInterval, (_) => _notify());
    _notify();
  }

  void _subscribe() {
    _subs
      ..add(_repo.watchLatestTelemetry().listen(_onTelemetry))
      ..add(
        _repo.watchDeviceStatus().listen((d) {
          _device = d;
          _notify();
        }),
      )
      ..add(_repo.watchNewEvents().listen(_onEvent))
      ..add(
        _repo.watchDailySummaries().listen((d) {
          _daily = d;
          _notify();
        }),
      );
  }

  void _onTelemetry(ChairTelemetry t) {
    if (_history.isNotEmpty && !t.timestamp.isAfter(_history.last.timestamp)) {
      return;
    }
    _history.add(t);
    final cutoff = t.timestamp.subtract(historyWindow);
    _history.removeWhere((e) => e.timestamp.isBefore(cutoff));
    _notify();
  }

  void _onEvent(ChairEvent e) {
    if (_events.any((x) => x.id == e.id)) return;
    _events = [e, ..._events.take(maxEvents - 1)];
    _notify();
  }

  void _cancelSubs() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  // ---------------------------------------------------------------- actions

  Future<void> saveConfig(ChairConfig config) async {
    final stamped = config.copyWith(updatedAt: now);
    await _repo.saveConfig(stamped);
    _config = stamped;
    _notify();
  }

  double? _bodyWeightKg;

  /// Occupant weight entered by the user. Re-applied to every simulated
  /// repository so it survives switching Demo Mode.
  double? get bodyWeightKg => _bodyWeightKg;

  void setBodyWeight(double kg) {
    _bodyWeightKg = kg;
    simulation?.setBodyWeight(kg);
    _notify();
  }

  /// Last pause/resume requested from the UI. Shown immediately, until the
  /// device's own telemetry reports the same value.
  bool? _pausedRequest;

  /// Whether automatic correction is paused. The repository/device is the
  /// source of truth (via telemetry); a fresh user request wins until the
  /// device acknowledges it.
  bool get correctionPaused {
    final reported = latest?.correction.correctionPaused;
    final requested = _pausedRequest;
    if (requested != null && reported != requested) return requested;
    return reported ?? false;
  }

  Future<void> setCorrectionPaused(bool value) async {
    await _repo.setCorrectionPaused(value);
    _pausedRequest = value;
    _notify();
  }

  /// Switches between the simulated repository and the non-demo repository.
  Future<void> setDemoMode(bool value) async {
    if (value == _demoMode) return;
    _demoMode = value;
    _pausedRequest = null; // the new repository reports its own state
    _cancelSubs();
    final old = _repo;
    _repo = _factory(demoMode: value, config: _config);
    if (_bodyWeightKg != null) simulation?.setBodyWeight(_bodyWeightKg!);
    _history.clear();
    _events = const [];
    _daily = const [];
    _device = null;
    unawaited(old.dispose());
    await load();
  }

  /// Runs a simulation hook and refreshes listeners.
  void simulate(void Function(SimulationControls sim) action) {
    final sim = simulation;
    if (sim == null) return;
    action(sim);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _clockTimer?.cancel();
    _cancelSubs();
    _repo.dispose();
    super.dispose();
  }
}
