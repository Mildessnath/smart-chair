import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_chair_dashboard/app.dart';
import 'package:smart_chair_dashboard/models/chair_config.dart';
import 'package:smart_chair_dashboard/providers/dashboard_controller.dart';
import 'package:smart_chair_dashboard/providers/monitoring_controller.dart';
import 'package:smart_chair_dashboard/providers/user_session.dart';
import 'package:smart_chair_dashboard/repositories/chair_repository.dart';
import 'package:smart_chair_dashboard/repositories/disconnected_chair_repository.dart';
import 'package:smart_chair_dashboard/repositories/mock_chair_repository.dart';
import 'package:smart_chair_dashboard/screens/app_shell.dart';

/// Mock repository tuned for tests: no load delay, a short seed (so the
/// simulator starts upright and uncorrected) and a clock that follows the
/// test's fake time (the controller drops samples with duplicate timestamps).
ChairRepository fastFactory({
  required bool demoMode,
  required ChairConfig config,
}) => demoMode
    ? MockChairRepository(
        initialConfig: config.copyWith(maxTiltDeg: 2),
        loadDelay: Duration.zero,
        seedHistory: const Duration(seconds: 5),
        clock: () => clock.now(),
      )
    : DisconnectedChairRepository(initialConfig: config);

Future<void> pumpApp(
  WidgetTester tester, {
  Widget home = const AppShell(),
  Size size = const Size(390, 844),
  bool activate = true,
  bool seedNotifications = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    SmartChairApp(
      repositoryFactory: fastFactory,
      home: home,
      seedDemoNotifications: seedNotifications,
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  if (activate) {
    read<MonitoringController>(tester).activate();
    await tester.pump();
  }
}

T read<T>(WidgetTester tester) =>
    Provider.of<T>(tester.element(find.byType(MaterialApp)), listen: false);

DashboardController dashboard(WidgetTester tester) =>
    read<DashboardController>(tester);
MonitoringController monitoring(WidgetTester tester) =>
    read<MonitoringController>(tester);
UserSession session(WidgetTester tester) => read<UserSession>(tester);

Future<void> tick(WidgetTester tester, int seconds) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Unmounts the app so periodic timers are cancelled before the test ends.
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pump(const Duration(milliseconds: 100));
}
