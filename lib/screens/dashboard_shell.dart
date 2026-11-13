import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_controller.dart';
import '../providers/navigation_controller.dart';
import '../widgets/sidebar.dart';
import '../widgets/state_views.dart';
import '../widgets/top_status_bar.dart';
import 'correction_screen.dart';
import 'daily_duration_screen.dart';
import 'device_log_screen.dart';
import 'overview_screen.dart';
import 'posture_screen.dart';
import 'pressure_map_screen.dart';
import 'settings_screen.dart';
import 'tilt_screen.dart';

/// Responsive frame: sidebar (desktop), icon rail (tablet), drawer (phone).
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  static const double wideBreakpoint = 1200;
  static const double railBreakpoint = 760;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= DashboardShell.wideBreakpoint;
        final rail = !wide && c.maxWidth >= DashboardShell.railBreakpoint;
        final phone = !wide && !rail;
        return Scaffold(
          key: _scaffoldKey,
          drawer: phone
              ? Drawer(
                  child: Sidebar(
                    onNavigate: () => _scaffoldKey.currentState?.closeDrawer(),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!phone) Sidebar(compact: rail),
              Expanded(
                child: Column(
                  children: [
                    TopStatusBar(
                      onMenu: phone
                          ? () => _scaffoldKey.currentState?.openDrawer()
                          : null,
                    ),
                    const Expanded(child: _Body()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final section = context.watch<NavigationController>().section;

    // Settings stay reachable while loading/erroring (e.g. to toggle Demo Mode).
    if (section != DashboardSection.settings) {
      if (ctrl.status == LoadStatus.loading) return const LoadingView();
      if (ctrl.status == LoadStatus.error) {
        return ErrorView(error: ctrl.error, onRetry: ctrl.load);
      }
    }
    return switch (section) {
      DashboardSection.overview => const OverviewScreen(),
      DashboardSection.pressure => const PressureMapScreen(),
      DashboardSection.posture => const PostureScreen(),
      DashboardSection.tilt => const TiltScreen(),
      DashboardSection.daily => const DailyDurationScreen(),
      DashboardSection.correction => const CorrectionScreen(),
      DashboardSection.device => const DeviceLogScreen(),
      DashboardSection.settings => const SettingsScreen(),
    };
  }
}
