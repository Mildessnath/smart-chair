import '../models/chair_config.dart';
import '../models/chair_event.dart';
import '../models/chair_telemetry.dart';
import '../models/daily_posture_summary.dart';
import '../models/device_status.dart';

/// Data source contract for the dashboard.
///
/// Widgets never talk to a repository directly; they read state from
/// `DashboardController`. Implementations:
/// - [MockChairRepository]: deterministic simulation (current stage).
/// - `DisconnectedChairRepository`: no device configured yet.
/// - `FirebaseChairRepository`: planned, see docs/firebase_schema.md.
abstract class ChairRepository {
  /// Initial snapshot loads. May throw; the controller shows an error state.
  Future<ChairConfig> fetchConfig();
  Future<DeviceStatus> fetchDeviceStatus();
  Future<List<ChairTelemetry>> fetchTelemetryHistory({
    required Duration window,
  });
  Future<List<DailyPostureSummary>> fetchDailySummaries({int days = 7});

  /// Most recent events, newest first.
  Future<List<ChairEvent>> fetchEvents({int limit = 100});

  /// Live updates.
  Stream<ChairTelemetry> watchLatestTelemetry();
  Stream<DeviceStatus> watchDeviceStatus();
  Stream<ChairEvent> watchNewEvents();
  Stream<List<DailyPostureSummary>> watchDailySummaries();

  /// Persists configuration. Implementations must not claim the device has
  /// applied it unless the device acknowledges.
  Future<void> saveConfig(ChairConfig config);

  /// Pauses/resumes automatic correction. While paused the actuator must not
  /// move, but posture detection and notifications continue.
  Future<void> setCorrectionPaused(bool paused);

  /// Human-readable description of where saved config goes.
  String get configDestination;

  Future<void> dispose();
}
