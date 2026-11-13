import 'package:flutter/material.dart';

enum DashboardSection {
  overview('Overview', Icons.dashboard_outlined, Icons.dashboard),
  pressure('Pressure Map', Icons.grid_view_outlined, Icons.grid_view),
  posture('Posture', Icons.accessibility_new_outlined, Icons.accessibility_new),
  tilt('Tilt Angle', Icons.show_chart_outlined, Icons.show_chart),
  daily('Daily Duration', Icons.bar_chart_outlined, Icons.bar_chart),
  correction('Correction', Icons.tune_outlined, Icons.tune),
  device('Device & Log', Icons.memory_outlined, Icons.memory),
  settings('Settings', Icons.settings_outlined, Icons.settings);

  const DashboardSection(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class NavigationController extends ChangeNotifier {
  DashboardSection _section = DashboardSection.overview;
  DashboardSection get section => _section;

  void go(DashboardSection section) {
    if (section == _section) return;
    _section = section;
    notifyListeners();
  }
}
