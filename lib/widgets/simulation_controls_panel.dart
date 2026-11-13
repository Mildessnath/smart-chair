import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/load_cell.dart';
import '../models/posture_state.dart';
import '../providers/dashboard_controller.dart';
import '../providers/navigation_controller.dart';
import '../repositories/simulation_controls.dart';
import '../theme/app_theme.dart';

/// Lets a developer drive the mock repository to exercise every UI state.
class SimulationControlsPanel extends StatelessWidget {
  const SimulationControlsPanel({super.key, required this.ctrl});
  final DashboardController ctrl;

  @override
  Widget build(BuildContext context) {
    final sim = ctrl.simulation;
    if (sim == null) {
      return const Text(
        'Simulation controls are only available in Demo Mode.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Device link'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final l in SimLink.values)
              ChoiceChip(
                label: Text(l.label),
                selected: sim.link == l,
                onSelected: (_) => ctrl.simulate((x) => x.setLink(l)),
              ),
          ],
        ),
        const _Hint(
          'Offline stops telemetry so the stale-data state appears after 5 s.',
        ),
        const _Label('Posture'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('Auto (scripted scenario)'),
              selected: sim.postureOverride == null,
              onSelected: (_) =>
                  ctrl.simulate((x) => x.setPostureOverride(null)),
            ),
            for (final p in PostureState.values)
              ChoiceChip(
                label: Text(p == PostureState.unknown ? 'Empty seat' : p.label),
                selected: sim.postureOverride == p,
                onSelected: (_) =>
                    ctrl.simulate((x) => x.setPostureOverride(p)),
              ),
          ],
        ),
        const _Hint(
          'Forces the simulated load profile; the classifier still decides.',
        ),
        const _Label('Load cell faults'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in LoadCellPosition.values)
              FilterChip(
                label: Text(p.label),
                selected: sim.faultyCells.contains(p),
                selectedColor: AppColors.red.withValues(alpha: 0.25),
                onSelected: (v) => ctrl.simulate((x) => x.setSensorFault(p, v)),
              ),
          ],
        ),
        const _Label('Events & errors'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => ctrl.simulate((x) => x.injectWarning()),
              icon: const Icon(Icons.add_alert_outlined, size: 18),
              label: const Text('Inject warning / error event'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                ctrl.simulate((x) => x.setFailNextLoad(true));
                ctrl.load();
                // Settings stays usable during errors; jump to a data page.
                context.read<NavigationController>().go(
                  DashboardSection.overview,
                );
              },
              icon: const Icon(Icons.cloud_off_outlined, size: 18),
              label: const Text('Reload with simulated failure'),
            ),
            OutlinedButton.icon(
              onPressed: ctrl.load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reload data'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11.5, color: AppColors.textFaint),
    ),
  );
}
