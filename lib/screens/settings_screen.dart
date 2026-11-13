import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chair_config.dart';
import '../providers/dashboard_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/simulation_controls_panel.dart';
import '../widgets/status_badge.dart';
import 'section_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Unsaved slider value; null = showing the saved config.
  double? _draft;
  bool _saving = false;
  bool _switchingMode = false;

  Future<void> _save(DashboardController ctrl, double value) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ctrl.saveConfig(ctrl.config.copyWith(maxTiltDeg: value));
      if (!mounted) return;
      setState(() => _draft = null);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Max tilt ${formatDeg(value)} saved to ${ctrl.configDestination}. '
            'Not sent to ESP32 or Firebase.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setDemo(DashboardController ctrl, bool value) async {
    setState(() => _switchingMode = true);
    await ctrl.setDemoMode(value);
    if (mounted) setState(() => _switchingMode = false);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final saved = ctrl.config.maxTiltDeg;
    final value = _draft ?? saved;
    final dirty = _draft != null && (_draft! - saved).abs() > 1e-9;
    final isDefault = (value - ChairConfig.defaults.maxTiltDeg).abs() < 1e-9;

    return SectionPage(
      showStale: false,
      children: [
        DashboardCard(
          title: 'Maximum Tilt',
          subtitle: 'Correction starts when |tilt| exceeds this value',
          fill: false,
          trailing: dirty
              ? const StatusBadge(
                  label: 'Unsaved changes',
                  color: AppColors.orange,
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    formatDeg(value),
                    key: const Key('maxTiltValue'),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'saved: ${formatDeg(saved)}'
                      '${ctrl.config.updatedAt == null ? ' (default)' : ' at ${formatTime(ctrl.config.updatedAt!)}'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                key: const Key('maxTiltSlider'),
                value: value,
                min: ChairConfig.minTilt,
                max: ChairConfig.maxTilt,
                divisions: 50,
                label: formatDeg(value),
                onChanged: _saving ? null : (v) => setState(() => _draft = v),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0°',
                    style: TextStyle(fontSize: 11, color: AppColors.textFaint),
                  ),
                  Text(
                    '5°',
                    style: TextStyle(fontSize: 11, color: AppColors.textFaint),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    key: const Key('saveButton'),
                    onPressed: dirty && !_saving
                        ? () => _save(ctrl, value)
                        : null,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('resetButton'),
                    onPressed: isDefault || _saving
                        ? null
                        : () => setState(
                            () => _draft = ChairConfig.defaults.maxTiltDeg,
                          ),
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: Text(
                      'Reset to default (${formatDeg(ChairConfig.defaults.maxTiltDeg)})',
                    ),
                  ),
                  if (dirty)
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _draft = null),
                      child: const Text('Discard'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Stage 1: settings change local app state only. They are not '
                'sent to the ESP32 or stored in Firebase yet.',
                style: TextStyle(fontSize: 12, color: AppColors.textFaint),
              ),
            ],
          ),
        ),
        DashboardCard(
          title: 'Data Source',
          fill: false,
          child: SwitchListTile(
            key: const Key('demoModeSwitch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Demo Mode'),
            subtitle: Text(
              ctrl.demoMode
                  ? 'On — dashboard shows simulated data from MockChairRepository.'
                  : 'Off — no real device backend is configured yet, so the '
                        'device shows Offline with no data.',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            value: ctrl.demoMode,
            onChanged: _switchingMode ? null : (v) => _setDemo(ctrl, v),
          ),
        ),
        DashboardCard(
          title: 'Simulation Controls',
          subtitle: 'For testing UI states with the mock repository',
          fill: false,
          child: SimulationControlsPanel(ctrl: ctrl),
        ),
      ],
    );
  }
}
