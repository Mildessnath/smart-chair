import '../models/chair_config.dart';
import '../models/chair_event.dart';
import '../models/chair_telemetry.dart';
import '../models/daily_posture_summary.dart';
import '../models/device_status.dart';
import 'chair_repository.dart';

/// Used when Demo Mode is off and no real backend is configured yet.
///
/// Reports the device as offline with no data, so the dashboard shows its
/// empty states. Replace with `FirebaseChairRepository` once available.
class DisconnectedChairRepository implements ChairRepository {
  DisconnectedChairRepository({
    ChairConfig initialConfig = ChairConfig.defaults,
  }) : _config = initialConfig;

  ChairConfig _config;

  @override
  String get configDestination => 'local app state (no device connected)';

  @override
  Future<ChairConfig> fetchConfig() async => _config;

  @override
  Future<DeviceStatus> fetchDeviceStatus() async => DeviceStatus.offline();

  @override
  Future<List<ChairTelemetry>> fetchTelemetryHistory({
    required Duration window,
  }) async => const [];

  @override
  Future<List<DailyPostureSummary>> fetchDailySummaries({int days = 7}) async =>
      const [];

  @override
  Future<List<ChairEvent>> fetchEvents({int limit = 100}) async => [
    ChairEvent(
      id: 'no-backend',
      timestamp: DateTime.now(),
      type: EventType.connection,
      severity: EventSeverity.warning,
      message:
          'Demo Mode is off and no device backend is configured yet '
          '(Firebase integration is a later stage).',
      simulated: false,
    ),
  ];

  @override
  Stream<ChairTelemetry> watchLatestTelemetry() => const Stream.empty();

  @override
  Stream<DeviceStatus> watchDeviceStatus() => const Stream.empty();

  @override
  Stream<ChairEvent> watchNewEvents() => const Stream.empty();

  @override
  Stream<List<DailyPostureSummary>> watchDailySummaries() =>
      const Stream.empty();

  @override
  Future<void> saveConfig(ChairConfig config) async => _config = config;

  /// No actuator is connected, so there is nothing to pause.
  @override
  Future<void> setCorrectionPaused(bool paused) async {}

  @override
  Future<void> dispose() async {}
}
