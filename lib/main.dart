import 'package:flutter/material.dart';

import 'app.dart';
import 'screens/app_root.dart';

void main() {
  runApp(const SmartChairApp(home: AppRoot(), seedDemoNotifications: true));
}
