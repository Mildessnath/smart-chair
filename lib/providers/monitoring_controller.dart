import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/chair_telemetry.dart';
import '../models/posture_state.dart';
import '../utils/history_stats.dart';
import '../utils/labels_id.dart';
import 'dashboard_controller.dart';

/// Chair activation, sitting duration and pressure alerts.
///
/// Fed by the telemetry the [DashboardController] receives. Everything here is
/// driven by sample timestamps, so it behaves the same with real or
/// simulated time.
///
/// - Sitting duration starts at 0 when the chair is activated and only counts
///   while the chair is active AND the seat is occupied.
/// - An alert is raised once per episode when the pressure pattern is
///   abnormal (occupied seat, non-upright posture) continuously for
///   [alertAfter] while the chair is active.
class MonitoringController extends ChangeNotifier {
  MonitoringController({
    required this.dashboard,
    Duration alertAfter = defaultAlertAfter,
    bool seedDemoNotifications = false,
    // ignore: prefer_initializing_formals
  }) : _alertAfter = alertAfter {
    dashboard.addListener(_onDashboard);
    if (seedDemoNotifications) _seedDemo();
  }

  static const Duration defaultAlertAfter = Duration(minutes: 5);

  final DashboardController dashboard;

  Duration _alertAfter;
  bool _active = false;
  DateTime? _activatedAt;
  Duration _sitting = Duration.zero;
  Duration _sessionGood = Duration.zero;
  Duration _sessionBad = Duration.zero;

  /// The first sample after activation only sets the baseline: the interval
  /// that straddles the activation moment is not sitting time.
  bool _baselineSet = false;

  ChairTelemetry? _prev;
  DateTime? _abnormalSince;
  bool _alerted = false;
  int _seq = 0;
  final List<AppNotification> _notifications = [];

  // ------------------------------------------------------------- activation

  bool get isActive => _active;
  DateTime? get activatedAt => _activatedAt;

  /// Time spent sitting since activation.
  Duration get sittingDuration => _sitting;

  /// Part of [sittingDuration] spent upright / in a non-upright posture.
  Duration get sessionGoodDuration => _sessionGood;
  Duration get sessionBadDuration => _sessionBad;

  void activate() {
    if (_active) return;
    _active = true;
    _activatedAt = dashboard.now;
    _sitting = Duration.zero;
    _sessionGood = Duration.zero;
    _sessionBad = Duration.zero;
    _baselineSet = false;
    _resetEpisode();
    notifyListeners();
  }

  void deactivate() {
    if (!_active) return;
    _active = false;
    _resetEpisode();
    notifyListeners();
  }

  // ----------------------------------------------------------------- alerts

  /// How long the pressure must stay abnormal before notifying.
  Duration get alertAfter => _alertAfter;
  set alertAfter(Duration value) {
    _alertAfter = value;
    notifyListeners();
  }

  /// How long the pressure has been continuously abnormal, if it is.
  Duration? get abnormalFor {
    final since = _abnormalSince;
    final last = _prev;
    if (since == null || last == null) return null;
    return last.timestamp.difference(since);
  }

  List<AppNotification> get notifications => List.unmodifiable(
    List.of(_notifications)..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
  );

  int get unreadCount => _notifications.where((n) => !n.read).length;

  void markAllRead() {
    if (unreadCount == 0) return;
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].markRead();
    }
    notifyListeners();
  }

  void markRead(String id) {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i < 0 || _notifications[i].read) return;
    _notifications[i] = _notifications[i].markRead();
    notifyListeners();
  }

  /// Adds the pressure alert. Also used by the simulation panel to preview
  /// the notification without waiting [alertAfter].
  void raisePressureAlert(
    PostureState posture,
    Duration duration, {
    DateTime? at,
  }) {
    final minutes = duration.inMinutes;
    final span = minutes >= 1
        ? '$minutes menit'
        : '${duration.inSeconds} detik';
    _notifications.add(
      AppNotification(
        id: 'pressure-${_seq++}',
        timestamp: at ?? _prev?.timestamp ?? dashboard.now,
        title: 'Tekanan duduk tidak normal',
        body:
            '${postureTitleId(posture)} terdeteksi selama $span. '
            'Coba ubah posisi duduk.',
      ),
    );
    notifyListeners();
  }

  // --------------------------------------------------------------- internals

  void _resetEpisode() {
    _abnormalSince = null;
    _alerted = false;
  }

  DateTime? _lastTimestamp;

  void _onDashboard() {
    final t = dashboard.latest;
    if (t == null) return;
    final last = _lastTimestamp;
    if (last != null && !t.timestamp.isAfter(last)) return;
    _lastTimestamp = t.timestamp;
    _process(t);
  }

  void _process(ChairTelemetry t) {
    final prev = _prev;
    if (_active) {
      if (!_baselineSet) {
        _baselineSet = true;
      } else if (prev != null && isSeatOccupied(prev)) {
        final dt = t.timestamp.difference(prev.timestamp);
        if (dt > Duration.zero && dt <= maxSampleGap) {
          _sitting += dt;
          if (prev.posture.isGood) _sessionGood += dt;
          if (prev.posture.isBad) _sessionBad += dt;
        }
      }

      final abnormal = pressureStatusOf(t) == PressureStatus.abnormal;
      if (abnormal) {
        _abnormalSince ??= t.timestamp;
        final span = t.timestamp.difference(_abnormalSince!);
        if (!_alerted && span >= _alertAfter) {
          _alerted = true;
          raisePressureAlert(t.posture, span, at: t.timestamp);
        }
      } else {
        _resetEpisode();
      }
    }
    _prev = t;
    notifyListeners();
  }

  void _seedDemo() {
    final now = dashboard.now;
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    _notifications.addAll([
      AppNotification(
        id: 'seed-1',
        timestamp: yesterday.add(const Duration(hours: 10, minutes: 5)),
        title: 'Tekanan duduk tidak normal',
        body:
            '${postureTitleId(PostureState.leaningForward)} terdeteksi selama '
            '6 menit. Coba ubah posisi duduk.',
        read: true,
      ),
      AppNotification(
        id: 'seed-2',
        timestamp: yesterday.add(const Duration(hours: 15, minutes: 40)),
        title: 'Tekanan duduk tidak normal',
        body:
            '${postureTitleId(PostureState.crossedLegs)} terdeteksi selama '
            '8 menit. Coba ubah posisi duduk.',
        read: true,
      ),
    ]);
  }

  /// "5 menit" style description of [alertAfter] for the UI.
  String get alertAfterLabel => alertAfter.inMinutes >= 1
      ? '${alertAfter.inMinutes} menit'
      : '${alertAfter.inSeconds} detik';

  @override
  void dispose() {
    dashboard.removeListener(_onDashboard);
    super.dispose();
  }
}
