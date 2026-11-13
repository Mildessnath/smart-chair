import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_chair_dashboard/models/load_cell.dart';
import 'package:smart_chair_dashboard/models/posture_state.dart';
import 'package:smart_chair_dashboard/theme/app_theme.dart';

import 'test_helpers.dart';

Color _heroColor(WidgetTester tester) {
  final box = tester.widget<AnimatedContainer>(
    find.byKey(const Key('heroCard')),
  );
  return (box.decoration! as BoxDecoration).color!;
}

String _title(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('heroTitle'))).data!;

void main() {
  testWidgets('bottom nav has 5 tabs', (tester) async {
    await pumpApp(tester);
    for (final l in ['Beranda', 'Tekanan', 'Notifikasi', 'Riwayat', 'Profil']) {
      expect(find.text(l), findsWidgets, reason: l);
    }
    await openTab(tester, 'Riwayat');
    expect(find.byKey(const Key('historySegments')), findsOneWidget);
    expect(find.byKey(const Key('pauseButton')), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('home is clean: no recent-activity section', (tester) async {
    await pumpApp(tester);
    expect(find.text('Aktivitas terbaru'), findsNothing);
    expect(find.text('Ringkasan live'), findsOneWidget);
    expect(find.byKey(const Key('heroCard')), findsOneWidget);
    await disposeApp(tester);
  });

  group('chair activation', () {
    testWidgets('inactive: hero invites to activate, duration not counted', (
      tester,
    ) async {
      await pumpApp(tester, activate: false);
      await tick(tester, 3);
      expect(_title(tester), 'Kursi belum aktif');
      expect(find.text('Belum aktif'), findsOneWidget);
      expect(find.byKey(const Key('pauseButton')), findsNothing);
      expect(find.byKey(const Key('activateChairButton')), findsOneWidget);
      expect(find.text('Kursi belum aktif'), findsWidgets);
      await disposeApp(tester);
    });

    testWidgets('Aktifkan kursi starts monitoring and the duration', (
      tester,
    ) async {
      await pumpApp(tester, activate: false);
      await tick(tester, 2);
      await tester.tap(find.byKey(const Key('activateChairButton')));
      await tick(tester, 12);
      expect(monitoring(tester).isActive, isTrue);
      expect(_title(tester), 'Tegak');
      expect(find.byKey(const Key('pauseButton')), findsOneWidget);
      expect(find.byKey(const Key('activateChairButton')), findsNothing);
      expect(
        monitoring(tester).sittingDuration.inSeconds,
        inInclusiveRange(9, 13),
      );
      await disposeApp(tester);
    });

    testWidgets('tapping the duration card toggles via a confirmation', (
      tester,
    ) async {
      await pumpApp(tester);
      await tick(tester, 3);
      await tester.drag(
        find.byKey(const Key('cardAngle')),
        const Offset(-300, 0),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('cardDuration')));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(find.text('Nonaktifkan kursi?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmToggle')));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(monitoring(tester).isActive, isFalse);
      expect(_title(tester), 'Kursi belum aktif');
      await disposeApp(tester);
    });
  });

  group('hero states', () {
    testWidgets('1/5 upright is lime with a monitoring chip', (tester) async {
      await pumpApp(tester);
      dashboard(tester)
          .simulate((s) => s.setPostureOverride(PostureState.upright));
      await tick(tester, 15);
      expect(_title(tester), 'Tegak');
      expect(_heroColor(tester), AppColors.lime);
      expect(find.text('Memantau'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('2/5 sideways lean is amber and is never corrected', (
      tester,
    ) async {
      await pumpApp(tester);
      dashboard(tester)
          .simulate((s) => s.setPostureOverride(PostureState.leaningLeft));
      await tick(tester, 40);
      expect(_title(tester), 'Miring ke kiri');
      expect(_heroColor(tester), AppColors.amber);
      expect(find.byKey(const Key('dwellCountdown')), findsNothing);
      expect(find.text('Mengoreksi'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('crossed legs is shown as "Melipat kaki" on amber', (
      tester,
    ) async {
      await pumpApp(tester);
      dashboard(tester)
          .simulate((s) => s.setPostureOverride(PostureState.crossedLegs));
      await tick(tester, 20);
      expect(_title(tester), 'Melipat kaki');
      expect(_heroColor(tester), AppColors.amber);
      expect(find.text('Mengoreksi'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('3/5 DWELL: big countdown on coral', (tester) async {
      await pumpApp(tester);
      dashboard(tester)
          .simulate((s) => s.setPostureOverride(PostureState.leaningBackward));
      await tick(tester, 8);
      final first = int.parse(
        tester.widget<Text>(find.byKey(const Key('dwellCountdown'))).data!,
      );
      expect(first, inInclusiveRange(15, 25));
      expect(_title(tester), 'Condong ke belakang');
      expect(_heroColor(tester), AppColors.coral);
      expect(find.text('Bersiap koreksi'), findsOneWidget);
      await tick(tester, 3);
      final later = int.parse(
        tester.widget<Text>(find.byKey(const Key('dwellCountdown'))).data!,
      );
      expect(later, first - 3);
      await disposeApp(tester);
    });

    testWidgets('4/5 after the countdown the chair is correcting', (
      tester,
    ) async {
      await pumpApp(tester);
      dashboard(tester)
          .simulate((s) => s.setPostureOverride(PostureState.leaningBackward));
      await tick(tester, 33);
      expect(find.text('Mengoreksi'), findsOneWidget);
      expect(find.byKey(const Key('dwellCountdown')), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('5/5 pause shows "Koreksi dijeda" and stops correcting', (
      tester,
    ) async {
      await pumpApp(tester);
      dashboard(tester)
          .simulate((s) => s.setPostureOverride(PostureState.leaningBackward));
      await tick(tester, 8);
      expect(find.text('Pause koreksi'), findsOneWidget);
      await tester.tap(find.byKey(const Key('pauseButton')));
      await tick(tester, 2);
      expect(find.text('Koreksi dijeda'), findsOneWidget);
      expect(find.text('Lanjutkan koreksi'), findsOneWidget);
      expect(find.byKey(const Key('dwellCountdown')), findsNothing);
      await tick(tester, 60);
      expect(find.text('Mengoreksi'), findsNothing);
      await tester.tap(find.byKey(const Key('pauseButton')));
      await tick(tester, 5);
      expect(find.text('Koreksi dijeda'), findsNothing);
      expect(find.byKey(const Key('dwellCountdown')), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('live summary', () {
    testWidgets('cards show pressure, angle and a running sitting duration', (
      tester,
    ) async {
      await pumpApp(tester);
      await tick(tester, 5);
      expect(find.text('Peta tekanan'), findsOneWidget);
      expect(find.text('Sudut kursi'), findsOneWidget);
      expect(find.textContaining(' kg'), findsWidgets);
      expect(find.text('Normal'), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('cardAngle')),
        const Offset(-300, 0),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Durasi duduk'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^\d\d:\d\d$')), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('pressure card caption turns abnormal for crossed legs', (
      tester,
    ) async {
      await pumpApp(tester);
      dashboard(tester)
          .simulate((s) => s.setPostureOverride(PostureState.crossedLegs));
      await tick(tester, 25);
      expect(find.textContaining('Tidak normal'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('pressure card opens the Tekanan tab', (tester) async {
      await pumpApp(tester);
      await tick(tester, 3);
      await tester.tap(find.byKey(const Key('cardPressure')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Data load cell'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('angle card opens the angle sheet', (tester) async {
      await pumpApp(tester);
      await tick(tester, 3);
      await tester.tap(find.byKey(const Key('cardAngle')));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('angleSheetValue')), findsOneWidget);
      expect(find.text('Status koreksi'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  testWidgets('menu button opens the device status sheet', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Status perangkat'));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(find.text('Heartbeat terakhir'), findsOneWidget);
    expect(find.text('4 dari 4 normal'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('demo mode off: offline chip and no-data hero', (tester) async {
    await pumpApp(tester);
    await dashboard(tester).setDemoMode(false);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Offline'), findsOneWidget);
    expect(_title(tester), 'Belum ada data');
    await disposeApp(tester);
  });

  for (final size in const [Size(360, 700), Size(390, 844), Size(1280, 800)]) {
    testWidgets(
      'every tab renders without overflow at ${size.width.toInt()}px',
      (tester) async {
        await pumpApp(tester, size: size, seedNotifications: true);
        final ctrl = dashboard(tester);
        for (final p in [
          PostureState.upright,
          PostureState.crossedLegs,
          PostureState.leaningBackward,
          PostureState.unknown,
        ]) {
          ctrl.simulate((s) => s.setPostureOverride(p));
          await tick(tester, 12);
          for (final tab in [
            'Beranda',
            'Tekanan',
            'Notifikasi',
            'Riwayat',
            'Profil',
          ]) {
            await openTab(tester, tab);
            expect(tester.takeException(), isNull, reason: '${p.label} / $tab');
          }
        }
        ctrl.simulate((s) {
          s.setPostureOverride(null);
          s.setSensorFault(LoadCellPosition.frontLeft, true);
        });
        await tick(tester, 3);
        for (final tab in ['Beranda', 'Tekanan']) {
          await openTab(tester, tab);
          expect(tester.takeException(), isNull, reason: 'fault / $tab');
        }
        await openTab(tester, 'Beranda');
        expect(find.text('Sensor bermasalah'), findsWidgets);
        await disposeApp(tester);
      },
    );
  }
}
