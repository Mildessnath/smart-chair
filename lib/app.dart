import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/chair_config.dart';
import 'providers/dashboard_controller.dart';
import 'providers/monitoring_controller.dart';
import 'providers/navigation_controller.dart';
import 'providers/user_session.dart';
import 'repositories/chair_repository.dart';
import 'repositories/disconnected_chair_repository.dart';
import 'repositories/mock_chair_repository.dart';
import 'screens/dashboard_shell.dart';
import 'theme/app_theme.dart';

/// Default repository wiring. Stage 2 (Firebase) replaces the non-demo branch:
/// `demoMode ? MockChairRepository(...) : FirebaseChairRepository(...)`.
ChairRepository defaultRepositoryFactory({
  required bool demoMode,
  required ChairConfig config,
}) => demoMode
    ? MockChairRepository(initialConfig: config)
    : DisconnectedChairRepository(initialConfig: config);

class SmartChairApp extends StatelessWidget {
  const SmartChairApp({
    super.key,
    this.repositoryFactory = defaultRepositoryFactory,
    this.home = const DashboardShell(),
    this.seedDemoNotifications = false,
  });

  final RepositoryFactory repositoryFactory;

  /// Root screen. Defaults to the stage-1 dashboard layout, which stays until
  /// every screen is migrated to the new `AppShell` (see `main.dart`).
  final Widget home;

  /// Adds two sample (simulated) notifications from yesterday, so the
  /// "Kemarin" group can be reviewed in demo builds.
  final bool seedDemoNotifications;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              DashboardController(repositoryFactory: repositoryFactory)..load(),
        ),
        ChangeNotifierProvider(create: (_) => NavigationController()),
        ChangeNotifierProvider(create: (_) => UserSession()),
        ChangeNotifierProvider(
          lazy: false, // start listening to telemetry immediately
          create: (ctx) => MonitoringController(
            dashboard: ctx.read<DashboardController>(),
            seedDemoNotifications: seedDemoNotifications,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Chair Dashboard',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: home,
      ),
    );
  }
}
