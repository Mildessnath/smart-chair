// Dev entrypoint: the real app (SmartChairApp + AppShell) with the mock
// simulator preset from URL query parameters, so UI states can be reviewed or
// screenshotted without clicking through Settings.
//
//   flutter run -d chrome -t lib/main_states.dart
//   http://localhost:PORT/?posture=backward&paused=1
//
//   posture = upright | forward | backward | left | right | crossed | empty
//   paused  = 1 to start with correction paused
//   active  = 0 to start with the chair NOT activated (default: activated)
//   weight  = body weight in kg (default 70)
//   tab     = pressure | notifications | history | profile (default home)
//   step    = login | weight | activation (shows the sign-in flow instead)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'models/chair_config.dart';
import 'models/posture_state.dart';
import 'providers/dashboard_controller.dart';
import 'providers/monitoring_controller.dart';
import 'providers/user_session.dart';
import 'repositories/chair_repository.dart';
import 'repositories/disconnected_chair_repository.dart';
import 'repositories/mock_chair_repository.dart';
import 'screens/app_root.dart';
import 'screens/app_shell.dart';

const _postures = {
  'upright': PostureState.upright,
  'forward': PostureState.leaningForward,
  'backward': PostureState.leaningBackward,
  'left': PostureState.leaningLeft,
  'right': PostureState.leaningRight,
  'crossed': PostureState.crossedLegs,
  'empty': PostureState.unknown,
};

void main() {
  final q = Uri.base.queryParameters;
  ChairRepository factory({
    required bool demoMode,
    required ChairConfig config,
  }) {
    if (!demoMode) return DisconnectedChairRepository(initialConfig: config);
    final repo = MockChairRepository(
      initialConfig: config,
      seedHistory: const Duration(seconds: 30),
    );
    repo.setPostureOverride(_postures[q['posture']]);
    if (q['paused'] == '1') repo.setCorrectionPaused(true);
    return repo;
  }

  runApp(
    SmartChairApp(
      repositoryFactory: factory,
      home: _Preset(
        query: q,
        child: q['step'] == null
            ? AppShell(
                initialTab: ShellTab.values.firstWhere(
                  (t) => t.name == q['tab'],
                  orElse: () => ShellTab.home,
                ),
              )
            : const AppRoot(splashDuration: Duration.zero),
      ),
      seedDemoNotifications: true,
    ),
  );
}

/// Applies the URL presets once the providers exist.
class _Preset extends StatefulWidget {
  const _Preset({required this.query, required this.child});

  final Map<String, String> query;
  final Widget child;

  @override
  State<_Preset> createState() => _PresetState();
}

class _PresetState extends State<_Preset> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final q = widget.query;
      final step = q['step'];
      final weight = double.tryParse(q['weight'] ?? '') ?? 70;
      final session = context.read<UserSession>();
      final dashboard = context.read<DashboardController>();

      // Sign in (and enter the weight) as far as the requested step needs.
      if (step != 'login') {
        session.login(email: 'alex.k@mail.com', password: 'rahasia');
      }
      if (step != 'login' && step != 'weight') {
        session.setBodyWeight(weight);
        dashboard.setBodyWeight(weight);
      }
      if (step == null && q['active'] != '0') {
        context.read<MonitoringController>().activate();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
