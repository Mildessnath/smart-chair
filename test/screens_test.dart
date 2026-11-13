import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_chair_dashboard/models/load_cell.dart';
import 'package:smart_chair_dashboard/models/posture_state.dart';
import 'package:smart_chair_dashboard/screens/app_shell.dart';
import 'package:smart_chair_dashboard/widgets/ui/buttons.dart';

import 'test_helpers.dart';

Future<void> _scrollTo(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}

Future<void> _dragSliderToEnd(WidgetTester tester) async {
  await tester.drag(
    find.byKey(const Key('sheetSlider')),
    const Offset(3000, 0),
  );
  await tester.pump();
}

void main() {
  group('Tekanan page', () {
    AppShell pressureTab() => const AppShell(initialTab: ShellTab.pressure);

    testWidgets('shows the map, the legend and all four load cells', (
      tester,
    ) async {
      await pumpApp(tester, home: pressureTab());
      dashboard(tester).setBodyWeight(70);
      await tick(tester, 6);
      expect(find.text('Peta tekanan'), findsOneWidget);
      expect(find.text('Data load cell'), findsOneWidget);
      for (final p in LoadCellPosition.values) {
        expect(find.byKey(Key('cell_${p.key}')), findsOneWidget);
      }
      expect(find.text('Depan kiri'), findsWidgets);
      expect(find.text('Belakang kanan'), findsWidgets);
      expect(find.text('Titik tekanan'), findsWidgets);
      await tester.scrollUntilVisible(
        find.textContaining('bukan distribusi tekanan fisik'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('bukan distribusi tekanan fisik'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('upright is "Normal"; its weight share is shown', (
      tester,
    ) async {
      await pumpApp(tester, home: pressureTab());
      dashboard(tester).setBodyWeight(70);
      dashboard(tester)
          .simulate((s) => s.setPostureOverride(PostureState.upright));
      await tick(tester, 12);
      expect(
        find.descendant(
          of: find.byKey(const Key('pressureStatus')),
          matching: find.text('Normal'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('abnormalNotice')), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Dari berat badan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('dari 70 kg'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('crossed legs is "Tidak normal" and explains the 5 minutes', (
      tester,
    ) async {
      await pumpApp(tester, home: pressureTab());
      dashboard(tester)
          .simulate((s) => s.setPostureOverride(PostureState.crossedLegs));
      await tick(tester, 25);
      expect(find.text('Tidak normal'), findsOneWidget);
      expect(find.byKey(const Key('abnormalNotice')), findsOneWidget);
      expect(find.textContaining('lebih dari 5 menit'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a faulty sensor is flagged and has no value', (tester) async {
      await pumpApp(tester, home: pressureTab());
      dashboard(tester)
          .simulate((s) => s.setSensorFault(LoadCellPosition.rearLeft, true));
      await tick(tester, 4);
      expect(find.text('Sensor bermasalah'), findsOneWidget);
      expect(find.text('FAULT'), findsOneWidget); // map chip
      expect(find.text('Fault'), findsOneWidget); // list row
      await disposeApp(tester);
    });

    testWidgets('abnormal while the chair is inactive says to activate', (
      tester,
    ) async {
      await pumpApp(tester, home: pressureTab(), activate: false);
      dashboard(tester)
          .simulate((s) => s.setPostureOverride(PostureState.crossedLegs));
      await tick(tester, 25);
      expect(
        find.textContaining('Aktifkan kursi agar notifikasi'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('empty state without data (demo mode off)', (tester) async {
      await pumpApp(tester, home: pressureTab());
      await dashboard(tester).setDemoMode(false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Belum ada data load cell'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('Notifikasi page', () {
    AppShell tab() => const AppShell(initialTab: ShellTab.notifications);

    testWidgets('groups sample notifications under Kemarin', (tester) async {
      await pumpApp(tester, home: tab(), seedNotifications: true);
      expect(find.text('Kemarin'), findsOneWidget);
      expect(find.text('Hari ini'), findsNothing);
      expect(find.text('Tekanan duduk tidak normal'), findsNWidgets(2));
      expect(
        find.textContaining('Melipat kaki terdeteksi selama 8 menit'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('unreadDot')), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('empty state explains when notifications appear', (
      tester,
    ) async {
      await pumpApp(tester, home: tab());
      expect(find.text('Belum ada notifikasi'), findsOneWidget);
      expect(find.textContaining('lebih dari 5 menit'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('inactive chair: tells the user monitoring is not running', (
      tester,
    ) async {
      await pumpApp(tester, home: tab(), activate: false);
      expect(find.textContaining('Kursi belum aktif'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a new alert goes under "Hari ini", badges the tab, reads', (
      tester,
    ) async {
      await pumpApp(tester, home: tab(), seedNotifications: true);
      monitoring(tester).raisePressureAlert(
        PostureState.leaningForward,
        const Duration(minutes: 5),
      );
      await tester.pump();
      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('Kemarin'), findsOneWidget);
      expect(find.byKey(const Key('unreadDot')), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('1')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('markAllRead')));
      await tester.pump();
      expect(find.byKey(const Key('unreadDot')), findsNothing);
      expect(find.byType(Badge), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('tapping one notification marks only it as read', (
      tester,
    ) async {
      await pumpApp(tester, home: tab());
      final m = monitoring(tester);
      m.raisePressureAlert(
        PostureState.leaningLeft,
        const Duration(minutes: 5),
      );
      m.raisePressureAlert(
        PostureState.crossedLegs,
        const Duration(minutes: 6),
      );
      await tester.pump();
      expect(find.byKey(const Key('unreadDot')), findsNWidgets(2));
      await tester.tap(
        find.byKey(Key('notification_${m.notifications.first.id}')),
      );
      await tester.pump();
      expect(find.byKey(const Key('unreadDot')), findsOneWidget);
      expect(m.unreadCount, 1);
      await disposeApp(tester);
    });
  });

  group('Profil page', () {
    AppShell tab() => const AppShell(initialTab: ShellTab.profile);

    Future<void> pumpProfile(WidgetTester tester) async {
      await pumpApp(tester, home: tab());
      session(tester)
        ..login(email: 'alex.k@mail.com', password: 'rahasia')
        ..setBodyWeight(70);
      dashboard(tester).setBodyWeight(70);
      await tester.pump();
    }

    testWidgets('shows the user, weight and chair status', (tester) async {
      await pumpProfile(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('profileName'))).data,
        'Alex',
      );
      expect(tester.widget<Text>(find.byKey(const Key('avatar'))).data, 'A');
      expect(find.text('alex.k@mail.com'), findsOneWidget);
      expect(find.text('70 kg'), findsOneWidget);
      expect(find.textContaining('Sejak'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the chair switch activates and deactivates', (tester) async {
      await pumpProfile(tester);
      expect(monitoring(tester).isActive, isTrue);
      await tester.tap(find.byKey(const Key('chairActiveSwitch')));
      await tester.pump();
      expect(monitoring(tester).isActive, isFalse);
      expect(find.text('Durasi duduk belum dihitung'), findsOneWidget);
      await tester.tap(find.byKey(const Key('chairActiveSwitch')));
      await tester.pump();
      expect(monitoring(tester).isActive, isTrue);
      await disposeApp(tester);
    });

    testWidgets('editing the weight validates and updates the simulator', (
      tester,
    ) async {
      await pumpProfile(tester);
      await tester.tap(find.byKey(const Key('weightRow')));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      await tester.enterText(find.byKey(const Key('sheetWeightField')), '12');
      await tester.pump();
      expect(find.textContaining('Masukkan angka'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('sheetWeightField')), '82,5');
      await tester.pump();
      await tester.tap(find.byKey(const Key('sheetWeightSave')));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(find.text('82.5 kg'), findsOneWidget);
      expect(session(tester).bodyWeightKg, 82.5);
      expect(dashboard(tester).simulation!.bodyWeightKg, 82.5);
      await disposeApp(tester);
    });

    testWidgets('tilt limit slider saves and says it is local only', (
      tester,
    ) async {
      await pumpProfile(tester);
      expect(find.text('±2.0°'), findsOneWidget); // test factory uses 2°
      await tester.tap(find.byKey(const Key('tiltRow')));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      await _dragSliderToEnd(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('sheetValue'))).data,
        '±5.0°',
      );
      await tester.tap(find.byKey(const Key('sheetSave')));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(dashboard(tester).config.maxTiltDeg, 5.0);
      expect(find.text('±5.0°'), findsOneWidget);
      expect(
        find.textContaining('Belum dikirim ke ESP32 atau Firebase'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('dwell time is configurable from 20 to 30 seconds', (
      tester,
    ) async {
      await pumpProfile(tester);
      expect(find.text('25 detik'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dwellRow')));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      await _dragSliderToEnd(tester);
      await tester.tap(find.byKey(const Key('sheetSave')));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(dashboard(tester).config.dwellSeconds, 30);
      expect(find.text('30 detik'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('Save stays disabled until the value changes', (tester) async {
      await pumpProfile(tester);
      await tester.tap(find.byKey(const Key('dwellRow')));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(
        tester
            .widget<PrimaryPillButton>(find.byKey(const Key('sheetSave')))
            .onPressed,
        isNull,
      );
      await disposeApp(tester);
    });

    testWidgets('demo mode switch hides the simulation row', (tester) async {
      await pumpProfile(tester);
      await _scrollTo(tester, const Key('demoModeSwitch'));
      expect(find.byKey(const Key('simulationRow')), findsOneWidget);
      await tester.tap(find.byKey(const Key('demoModeSwitch')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(dashboard(tester).demoMode, isFalse);
      expect(find.byKey(const Key('simulationRow')), findsNothing);
      await disposeApp(tester);
    });

    testWidgets(
      'simulation sheet triggers a notification and a fast threshold',
      (tester) async {
        await pumpProfile(tester);
        await _scrollTo(tester, const Key('simulationRow'));
        await tester.tap(find.byKey(const Key('simulationRow')));
        await tester.pumpAndSettle(const Duration(milliseconds: 50));

        await tester.tap(find.text('10 detik (uji)'));
        await tester.pump();
        expect(monitoring(tester).alertAfter, const Duration(seconds: 10));

        await tester.ensureVisible(find.byKey(const Key('triggerAlert')));
        await tester.tap(find.byKey(const Key('triggerAlert')));
        await tester.pump();
        expect(monitoring(tester).notifications, hasLength(1));
        await disposeApp(tester);
      },
    );
  });
}
