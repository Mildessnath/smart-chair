import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/device_status.dart';
import '../../providers/dashboard_controller.dart';
import '../../providers/monitoring_controller.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/angle_sheet.dart';
import '../../widgets/home/device_sheet.dart';
import '../../widgets/home/hero_card.dart';
import '../../widgets/home/live_summary_row.dart';
import '../../widgets/state_views.dart';
import '../../widgets/ui/buttons.dart';
import '../../widgets/ui/section_header.dart';
import '../../widgets/ui/status_pill.dart';

/// Beranda: top bar → hero → live summary. Nothing else.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenPressure});

  /// Opens the Tekanan tab.
  final VoidCallback onOpenPressure;

  Future<void> _confirmToggle(
    BuildContext context,
    MonitoringController monitoring,
  ) async {
    final activating = !monitoring.isActive;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(activating ? 'Aktifkan kursi?' : 'Nonaktifkan kursi?'),
        content: Text(
          activating
              ? 'Durasi duduk mulai dihitung dari nol.'
              : 'Durasi duduk berhenti dihitung dan pemantauan tekanan '
                    'dihentikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            key: const Key('confirmToggle'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(activating ? 'Aktifkan' : 'Nonaktifkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    activating ? monitoring.activate() : monitoring.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final monitoring = context.watch<MonitoringController>();
    if (ctrl.status == LoadStatus.loading) return const LoadingView();
    if (ctrl.status == LoadStatus.error) {
      return ErrorView(error: ctrl.error, onRetry: ctrl.load);
    }

    const pad = EdgeInsets.symmetric(horizontal: AppSpace.screen);
    return ListView(
      padding: const EdgeInsets.only(top: AppSpace.s, bottom: AppSpace.l),
      children: [
        Padding(
          padding: pad,
          child: _TopBar(
            status: ctrl.device,
            onMenu: () =>
                showDeviceSheet(context, status: ctrl.device, now: ctrl.now),
          ),
        ),
        const SizedBox(height: AppSpace.l),
        Padding(
          padding: pad,
          child: HeroCard(
            telemetry: ctrl.latest,
            paused: ctrl.correctionPaused,
            active: monitoring.isActive,
            stale: ctrl.isStale,
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        const Padding(
          padding: pad,
          child: SectionHeader(title: 'Ringkasan live'),
        ),
        const SizedBox(height: AppSpace.m),
        LiveSummaryRow(
          telemetry: ctrl.latest,
          maxTiltDeg: ctrl.config.maxTiltDeg,
          bodyWeightKg: ctrl.bodyWeightKg,
          chairActive: monitoring.isActive,
          sitting: monitoring.sittingDuration,
          abnormalFor: monitoring.abnormalFor,
          onPressure: onOpenPressure,
          onAngle: () => showAngleSheet(
            context,
            telemetry: ctrl.latest,
            maxTiltDeg: ctrl.config.maxTiltDeg,
          ),
          onDuration: () => _confirmToggle(context, monitoring),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.status, required this.onMenu});

  final DeviceStatus? status;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = status?.connection;
    return Row(
      children: [
        RoundIconButton(
          icon: AppIcons.menu,
          tooltip: 'Status perangkat',
          onPressed: onMenu,
        ),
        Expanded(
          child: Text(
            'Smart Chair',
            textAlign: TextAlign.center,
            style: t.titleMedium,
          ),
        ),
        if (c == null)
          const StatusPill(label: '—')
        else
          StatusPill(
            key: const Key('connectionChip'),
            label: connectionLabel(c),
            tone: StatusTone.connection(c),
            icon: switch (c) {
              DeviceConnection.online => AppIcons.online,
              DeviceConnection.offline => AppIcons.offline,
              DeviceConnection.demo => AppIcons.demo,
            },
          ),
      ],
    );
  }
}

/// Sticky action above the bottom nav: activate the chair first, then
/// pause / resume automatic correction.
class ChairActionBar extends StatelessWidget {
  const ChairActionBar({super.key});

  Future<void> _togglePause(
    BuildContext context,
    DashboardController ctrl,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ctrl.setCorrectionPaused(!ctrl.correctionPaused);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal mengubah koreksi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final monitoring = context.watch<MonitoringController>();
    final ready = ctrl.status == LoadStatus.ready;
    final paused = ctrl.correctionPaused;

    final Widget button = monitoring.isActive
        ? PrimaryPillButton(
            key: const Key('pauseButton'),
            label: paused ? 'Lanjutkan koreksi' : 'Pause koreksi',
            icon: paused ? AppIcons.play : AppIcons.pause,
            expand: true,
            onPressed: ready ? () => _togglePause(context, ctrl) : null,
          )
        : PrimaryPillButton(
            key: const Key('activateChairButton'),
            label: 'Aktifkan kursi',
            icon: AppIcons.power,
            expand: true,
            onPressed: ready ? monitoring.activate : null,
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.s,
        AppSpace.screen,
        AppSpace.s,
      ),
      child: button,
    );
  }
}
