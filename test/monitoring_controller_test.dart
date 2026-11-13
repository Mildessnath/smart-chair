import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_chair_dashboard/models/chair_config.dart';
import 'package:smart_chair_dashboard/models/posture_state.dart';
import 'package:smart_chair_dashboard/providers/dashboard_controller.dart';
import 'package:smart_chair_dashboard/providers/monitoring_controller.dart';
import 'package:smart_chair_dashboard/repositories/chair_repository.dart';
import 'package:smart_chair_dashboard/repositories/mock_chair_repository.dart';

final _t0 = DateTime(2026, 11, 13, 10);

/// Runs [body] with a controller pair on fake time (1 s simulator ticks).
void scenario(
  void Function(
    FakeAsync async,
    DashboardController dash,
    MonitoringController mon,
  )
  body, {
  bool seedDemo = false,
}) {
  fakeAsync((async) {
    DateTime clock() => _t0.add(async.elapsed);
    ChairRepository factory({
      required bool demoMode,
      required ChairConfig config,
    }) => MockChairRepository(
      initialConfig: config,
      loadDelay: Duration.zero,
      seedHistory: const Duration(seconds: 5),
      clock: clock,
    );
    final dash = DashboardController(repositoryFactory: factory, clock: clock)
      ..load();
    final mon = MonitoringController(
      dashboard: dash,
      seedDemoNotifications: seedDemo,
    );
    async.flushMicrotasks();
    async.elapse(const Duration(seconds: 2));
    body(async, dash, mon);
    mon.dispose();
    dash.dispose();
    async.flushTimers();
  });
}

void posture(DashboardController d, PostureState p) =>
    d.simulate((s) => s.setPostureOverride(p));

void run(FakeAsync async, int seconds) =>
    async.elapse(Duration(seconds: seconds));

void main() {
  group('activation and sitting duration', () {
    test('nothing is counted before the chair is activated', () {
      scenario((async, dash, mon) {
        run(async, 30);
        expect(mon.isActive, isFalse);
        expect(mon.sittingDuration, Duration.zero);
      });
    });

    test('duration starts at 0 on activation and counts while occupied', () {
      scenario((async, dash, mon) {
        run(async, 30); // before activation: ignored
        mon.activate();
        expect(mon.sittingDuration, Duration.zero);
        expect(mon.activatedAt, isNotNull);
        run(async, 20);
        expect(mon.sittingDuration.inSeconds, inInclusiveRange(18, 21));
      });
    });

    test('an empty seat does not add to the duration', () {
      scenario((async, dash, mon) {
        mon.activate();
        posture(dash, PostureState.unknown);
        run(async, 15); // loads settle below the occupancy threshold
        final atEmpty = mon.sittingDuration;
        run(async, 30);
        expect(mon.sittingDuration, atEmpty);
        posture(dash, PostureState.upright);
        run(async, 20);
        expect(mon.sittingDuration, greaterThan(atEmpty));
      });
    });

    test('deactivating stops counting; reactivating restarts from 0', () {
      scenario((async, dash, mon) {
        mon.activate();
        run(async, 10);
        mon.deactivate();
        final stopped = mon.sittingDuration;
        run(async, 20);
        expect(mon.sittingDuration, stopped);
        mon.activate();
        expect(mon.sittingDuration, Duration.zero);
      });
    });
  });

  group('session posture split', () {
    test('sitting time is split into upright and non-upright', () {
      scenario((async, dash, mon) {
        mon.activate();
        posture(dash, PostureState.upright);
        run(async, 25);
        posture(dash, PostureState.crossedLegs);
        run(async, 25);
        expect(mon.sessionGoodDuration.inSeconds, greaterThan(15));
        expect(mon.sessionBadDuration.inSeconds, greaterThan(15));
        expect(
          mon.sessionGoodDuration + mon.sessionBadDuration,
          lessThanOrEqualTo(mon.sittingDuration),
        );
      });
    });

    test('the split restarts with a new activation', () {
      scenario((async, dash, mon) {
        mon.activate();
        run(async, 10);
        mon.deactivate();
        mon.activate();
        expect(mon.sessionGoodDuration, Duration.zero);
        expect(mon.sessionBadDuration, Duration.zero);
      });
    });
  });

  group('pressure alert after 5 minutes', () {
    test('default threshold is 5 minutes', () {
      scenario((async, dash, mon) {
        expect(mon.alertAfter, const Duration(minutes: 5));
        expect(mon.alertAfterLabel, '5 menit');
      });
    });

    test('abnormal for 5+ minutes raises exactly one notification', () {
      scenario((async, dash, mon) {
        mon.activate();
        posture(dash, PostureState.crossedLegs);
        run(async, 4 * 60);
        expect(mon.notifications, isEmpty, reason: 'only 4 minutes so far');
        expect(mon.abnormalFor!.inMinutes, greaterThanOrEqualTo(3));

        run(async, 90);
        expect(mon.notifications, hasLength(1));
        final n = mon.notifications.single;
        expect(n.title, 'Tekanan duduk tidak normal');
        expect(n.body, contains('Melipat kaki'));
        expect(n.body, contains('5 menit'));
        expect(mon.unreadCount, 1);

        run(async, 6 * 60);
        expect(mon.notifications, hasLength(1), reason: 'once per episode');
      });
    });

    test('a normal period resets the clock', () {
      scenario((async, dash, mon) {
        mon.activate();
        posture(dash, PostureState.crossedLegs);
        run(async, 3 * 60);
        posture(dash, PostureState.upright);
        run(async, 30);
        expect(mon.abnormalFor, isNull);
        posture(dash, PostureState.crossedLegs);
        run(async, 3 * 60);
        expect(
          mon.notifications,
          isEmpty,
          reason: '3 + 3 min is not 5 in a row',
        );
        run(async, 2 * 60 + 30);
        expect(mon.notifications, hasLength(1));
      });
    });

    test('an inactive chair never alerts', () {
      scenario((async, dash, mon) {
        posture(dash, PostureState.crossedLegs);
        run(async, 7 * 60);
        expect(mon.notifications, isEmpty);
      });
    });

    test('an empty seat is not abnormal', () {
      scenario((async, dash, mon) {
        mon.activate();
        posture(dash, PostureState.unknown);
        run(async, 7 * 60);
        expect(mon.notifications, isEmpty);
        expect(mon.abnormalFor, isNull);
      });
    });

    test('front/back and sideways leaning count as abnormal too', () {
      for (final p in [
        PostureState.leaningForward,
        PostureState.leaningBackward,
        PostureState.leaningLeft,
        PostureState.leaningRight,
      ]) {
        scenario((async, dash, mon) {
          mon.activate();
          posture(dash, p);
          run(async, 5 * 60 + 30);
          expect(mon.notifications, hasLength(1), reason: p.label);
        });
      }
    });

    test('the threshold can be shortened for testing', () {
      scenario((async, dash, mon) {
        mon.alertAfter = const Duration(seconds: 10);
        mon.activate();
        posture(dash, PostureState.crossedLegs);
        run(async, 25);
        expect(mon.notifications, hasLength(1));
        expect(mon.notifications.single.body, contains('detik'));
      });
    });
  });

  group('notification list', () {
    test('mark read / mark all read update the unread count', () {
      scenario((async, dash, mon) {
        mon.raisePressureAlert(
          PostureState.leaningForward,
          const Duration(minutes: 6),
        );
        mon.raisePressureAlert(
          PostureState.crossedLegs,
          const Duration(minutes: 7),
        );
        expect(mon.unreadCount, 2);
        mon.markRead(mon.notifications.first.id);
        expect(mon.unreadCount, 1);
        mon.markAllRead();
        expect(mon.unreadCount, 0);
      });
    });

    test('newest notification comes first', () {
      scenario((async, dash, mon) {
        mon.raisePressureAlert(
          PostureState.leaningForward,
          const Duration(minutes: 6),
        );
        run(async, 5);
        mon.raisePressureAlert(
          PostureState.crossedLegs,
          const Duration(minutes: 7),
        );
        expect(mon.notifications.first.body, contains('Melipat kaki'));
      });
    });

    test('demo seed adds two read notifications from yesterday', () {
      scenario(seedDemo: true, (async, dash, mon) {
        expect(mon.notifications, hasLength(2));
        expect(mon.unreadCount, 0);
        final today = DateTime(_t0.year, _t0.month, _t0.day);
        expect(
          mon.notifications.every((n) => n.timestamp.isBefore(today)),
          isTrue,
        );
        expect(mon.notifications.every((n) => n.simulated), isTrue);
      });
    });
  });
}
