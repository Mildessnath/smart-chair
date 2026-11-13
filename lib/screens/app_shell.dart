import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/monitoring_controller.dart';
import '../theme/app_icons.dart';
import '../widgets/ui/phone_frame.dart';
import 'history/history_screen.dart';
import 'home/home_screen.dart';
import 'notifications/notifications_screen.dart';
import 'pressure/pressure_screen.dart';
import 'profile/profile_screen.dart';

enum ShellTab { home, pressure, notifications, history, profile }

/// Mobile-style shell: 5-tab bottom navigation. On wide screens the app is
/// centered in a phone-width column.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = ShellTab.home});

  final ShellTab initialTab;

  static const double maxWidth = PhoneFrame.maxWidth;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late ShellTab _tab = widget.initialTab;

  void _go(ShellTab tab) => setState(() => _tab = tab);

  Widget _body() => switch (_tab) {
    ShellTab.home => HomeScreen(onOpenPressure: () => _go(ShellTab.pressure)),
    ShellTab.pressure => const PressureScreen(),
    ShellTab.notifications => const NotificationsScreen(),
    ShellTab.history => const HistoryScreen(),
    ShellTab.profile => const ProfileScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final unread = context.select<MonitoringController, int>(
      (m) => m.unreadCount,
    );

    Widget icon(IconData data, {bool badge = false}) => badge && unread > 0
        ? Badge(label: Text('$unread'), child: Icon(data))
        : Icon(data);

    return PhoneFrame(
      child: Scaffold(
        body: SafeArea(bottom: false, child: _body()),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_tab == ShellTab.home) const ChairActionBar(),
            NavigationBar(
              selectedIndex: _tab.index,
              onDestinationSelected: (i) => _go(ShellTab.values[i]),
              destinations: [
                NavigationDestination(
                  icon: icon(AppIcons.home),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: icon(AppIcons.pressure),
                  label: 'Tekanan',
                ),
                NavigationDestination(
                  icon: icon(AppIcons.notifications, badge: true),
                  label: 'Notifikasi',
                ),
                NavigationDestination(
                  icon: icon(AppIcons.history),
                  label: 'Riwayat',
                ),
                NavigationDestination(
                  icon: icon(AppIcons.user),
                  label: 'Profil',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
