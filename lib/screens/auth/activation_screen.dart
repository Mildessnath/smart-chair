import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/monitoring_controller.dart';
import '../../providers/user_session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/chair_illustration.dart';
import '../../widgets/ui/buttons.dart';
import 'auth_widgets.dart';

/// Onboarding step 3: activate the chair, which starts the sitting duration.
class ActivationScreen extends StatelessWidget {
  const ActivationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<UserSession>();
    return AuthScaffold(
      step: 3,
      title: 'Aktifkan kursimu',
      subtitle:
          'Duduk di kursi lalu aktifkan. Durasi duduk mulai dihitung sejak '
          'kursi diaktifkan, dan kamu diberi tahu jika tekanan duduk tidak '
          'normal lebih dari 5 menit.',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryPillButton(
            key: const Key('activateButton'),
            label: 'Aktifkan kursi',
            expand: true,
            onPressed: () {
              context.read<MonitoringController>().activate();
              session.completeChairPrompt();
            },
          ),
          const SizedBox(height: AppSpace.s),
          TextButton(
            key: const Key('skipActivation'),
            onPressed: session.completeChairPrompt,
            child: const Text('Nanti saja'),
          ),
        ],
      ),
      child: const Center(child: ChairIllustration(size: 160)),
    );
  }
}
