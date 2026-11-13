import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_chair_dashboard/models/load_cell.dart';
import 'package:smart_chair_dashboard/models/posture_state.dart';
import 'package:smart_chair_dashboard/screens/app_shell.dart';

import 'test_helpers.dart';

const _tab = AppShell(initialTab: ShellTab.history);

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}

void main() {
  testWidgets('shows segments, the duration chart, stats and events', (
    tester,
  ) async {
    await pumpApp(tester, home: _tab);
    await tick(tester, 5);
    expect(find.text('Riwayat'), findsWidgets);
    expect(find.byKey(const Key('historySegments')), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    expect(find.byKey(const Key('statGood')), findsOneWidget);
    expect(find.byKey(const Key('statBad')), findsOneWidget);
    expect(find.byKey(const Key('statSession')), findsOneWidget);
    expect(find.text('Kejadian'), findsOneWidget);
    expect(find.text('Data dari kursi (simulasi)'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('the segmented control switches to the seat angle chart', (
    tester,
  ) async {
    await pumpApp(tester, home: _tab);
    await tick(tester, 6);
    await tester.tap(find.text('Sudut kursi'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
    expect(find.byKey(const Key('statNow')), findsOneWidget);
    expect(find.byKey(const Key('statRange')), findsOneWidget);
    expect(find.byKey(const Key('statOver')), findsOneWidget);

    await tester.tap(find.text('Durasi postur'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(BarChart), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('the session split appears only for an active chair', (
    tester,
  ) async {
    await pumpApp(tester, home: _tab, activate: false);
    await tick(tester, 3);
    expect(find.byKey(const Key('sessionSplit')), findsNothing);
    expect(find.text('Kursi belum aktif'), findsOneWidget);

    monitoring(tester).activate();
    await tick(tester, 10);
    expect(find.byKey(const Key('sessionSplit')), findsOneWidget);
    expect(find.textContaining('Sesi ini: tegak'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('events are localized and dev chatter is hidden', (tester) async {
    await pumpApp(tester, home: _tab);
    dashboard(tester)
        .simulate((s) => s.setPostureOverride(PostureState.leaningLeft));
    await tick(tester, 20);
    final text = find.textContaining('Postur berubah: Tegak → Miring ke kiri');
    await _scrollTo(tester, text);
    expect(text, findsOneWidget);
    expect(find.textContaining('Simulation: forcing'), findsNothing);
    expect(find.textContaining('Mock repository started'), findsNothing);
    expect(find.textContaining('Posture changed'), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('filters narrow the list to posture or correction events', (
    tester,
  ) async {
    await pumpApp(tester, home: _tab);
    dashboard(tester)
        .simulate((s) => s.setPostureOverride(PostureState.leaningBackward));
    await tick(tester, 8);

    await _scrollTo(tester, find.byKey(const Key('filter_correction')));
    await tester.tap(find.byKey(const Key('filter_correction')));
    await tester.pump();
    expect(find.textContaining('melewati batas'), findsOneWidget);
    expect(find.textContaining('Koreksi dimulai dalam'), findsOneWidget);
    expect(find.textContaining('Postur berubah'), findsNothing);

    await tester.tap(find.byKey(const Key('filter_posture')));
    await tester.pump();
    expect(find.textContaining('Postur berubah'), findsWidgets);
    expect(find.textContaining('melewati batas'), findsNothing);

    await tester.tap(find.byKey(const Key('filter_device')));
    await tester.pump();
    expect(
      find.textContaining('Belum ada kejadian untuk filter ini.'),
      findsOneWidget,
    );
    await disposeApp(tester);
  });

  testWidgets('a sensor fault shows up under Perangkat', (tester) async {
    await pumpApp(tester, home: _tab);
    await tick(tester, 2);
    dashboard(tester)
        .simulate((s) => s.setSensorFault(LoadCellPosition.frontLeft, true));
    await tick(tester, 2);
    await _scrollTo(tester, find.byKey(const Key('filter_device')));
    await tester.tap(find.byKey(const Key('filter_device')));
    await tester.pump();
    expect(
      find.textContaining('Load cell depan kiri tidak terbaca'),
      findsOneWidget,
    );
    await disposeApp(tester);
  });

  testWidgets('empty states when there is no device data', (tester) async {
    await pumpApp(tester, home: _tab);
    await dashboard(tester).setDemoMode(false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Belum ada riwayat durasi'), findsOneWidget);
    expect(find.text('Belum ada perangkat terhubung'), findsOneWidget);
    await tester.tap(find.text('Sudut kursi'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Belum ada data sudut'), findsOneWidget);
    await disposeApp(tester);
  });
}
