import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_chair_dashboard/models/chair_config.dart';
import 'package:smart_chair_dashboard/models/device_status.dart';
import 'package:smart_chair_dashboard/providers/dashboard_controller.dart';
import 'package:smart_chair_dashboard/repositories/chair_repository.dart';
import 'package:smart_chair_dashboard/repositories/disconnected_chair_repository.dart';
import 'package:smart_chair_dashboard/repositories/mock_chair_repository.dart';
import 'package:smart_chair_dashboard/repositories/simulation_controls.dart';

void main() {
  test('loads seeded history, receives live ticks, detects stale data', () {
    fakeAsync((async) {
      DateTime clock() => DateTime(2026, 10, 16, 10).add(async.elapsed);
      ChairRepository factory({
        required bool demoMode,
        required ChairConfig config,
      }) => demoMode
          ? MockChairRepository(
              initialConfig: config,
              loadDelay: Duration.zero,
              clock: clock,
            )
          : DisconnectedChairRepository(initialConfig: config);

      final ctrl = DashboardController(repositoryFactory: factory, clock: clock)
        ..load();
      async.flushMicrotasks();
      expect(ctrl.status, LoadStatus.ready);
      expect(ctrl.history, isNotEmpty);
      expect(ctrl.device!.connection, DeviceConnection.demo);
      final seeded = ctrl.history.length;

      async.elapse(const Duration(seconds: 5));
      expect(ctrl.history.length, greaterThan(seeded));
      expect(ctrl.isStale, isFalse);

      ctrl.simulate((s) => s.setLink(SimLink.offline));
      async.elapse(const Duration(seconds: 8));
      expect(ctrl.device!.connection, DeviceConnection.offline);
      expect(ctrl.isStale, isTrue);

      ctrl.simulate((s) => s.setLink(SimLink.demo));
      async.elapse(const Duration(seconds: 2));
      expect(ctrl.isStale, isFalse);

      ctrl.dispose();
      async.flushTimers();
    });
  });

  test('simulated load failure shows error, retry recovers', () {
    fakeAsync((async) {
      ChairRepository factory({
        required bool demoMode,
        required ChairConfig config,
      }) =>
          MockChairRepository(initialConfig: config, loadDelay: Duration.zero);
      final ctrl = DashboardController(repositoryFactory: factory)..load();
      async.flushMicrotasks();
      ctrl.simulate((s) => s.setFailNextLoad(true));
      ctrl.load();
      async.flushMicrotasks();
      expect(ctrl.status, LoadStatus.error);
      ctrl.load();
      async.flushMicrotasks();
      expect(ctrl.status, LoadStatus.ready);
      ctrl.dispose();
      async.flushTimers();
    });
  });

  test('saving config updates state and the simulator', () {
    fakeAsync((async) {
      ChairRepository factory({
        required bool demoMode,
        required ChairConfig config,
      }) =>
          MockChairRepository(initialConfig: config, loadDelay: Duration.zero);
      final ctrl = DashboardController(repositoryFactory: factory)..load();
      async.flushMicrotasks();
      ctrl.saveConfig(const ChairConfig(maxTiltDeg: 1.5));
      async.flushMicrotasks();
      expect(ctrl.config.maxTiltDeg, 1.5);
      expect(ctrl.config.updatedAt, isNotNull);
      expect(ctrl.events.first.message, contains('not sent to device'));
      ctrl.dispose();
      async.flushTimers();
    });
  });
}
