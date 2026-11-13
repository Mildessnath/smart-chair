import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chair_config.dart';
import '../../providers/dashboard_controller.dart';
import '../../providers/monitoring_controller.dart';
import '../../providers/user_session.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui/settings_row.dart';
import 'profile_sheets.dart';

/// Profil: account, chair, correction settings and the demo switches.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _saveConfig(
    BuildContext context,
    DashboardController ctrl,
    ChairConfig next,
    String what,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await ctrl.saveConfig(next);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$what disimpan di ${ctrl.configDestination}. '
          'Belum dikirim ke ESP32 atau Firebase.',
        ),
      ),
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    UserSession session,
    MonitoringController monitoring,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Kursi dinonaktifkan dan kamu perlu masuk lagi untuk melanjutkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            key: const Key('confirmLogout'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    monitoring.deactivate();
    session.logout();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSession>();
    final ctrl = context.watch<DashboardController>();
    final monitoring = context.watch<MonitoringController>();
    final t = Theme.of(context).textTheme;
    final cfg = ctrl.config;
    final since = monitoring.activatedAt;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.m,
        AppSpace.screen,
        AppSpace.xl,
      ),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  session.isLoggedIn ? session.initials : '?',
                  key: const Key('avatar'),
                  style: t.displaySmall,
                ),
              ),
              const SizedBox(height: AppSpace.m),
              Text(
                session.displayName,
                key: const Key('profileName'),
                style: t.headlineSmall,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(session.email ?? '', style: t.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        Text('Kursi', style: t.titleMedium),
        const SizedBox(height: AppSpace.s),
        RowGroup(
          children: [
            SettingsRow(
              icon: AppIcons.power,
              title: 'Kursi aktif',
              subtitle: monitoring.isActive
                  ? (since == null ? 'Aktif' : 'Sejak ${formatTime(since)}')
                  : 'Durasi duduk belum dihitung',
              trailing: Switch(
                key: const Key('chairActiveSwitch'),
                value: monitoring.isActive,
                onChanged: (v) =>
                    v ? monitoring.activate() : monitoring.deactivate(),
              ),
            ),
            SettingsRow(
              icon: AppIcons.timer,
              title: 'Durasi duduk sesi ini',
              value: monitoring.isActive
                  ? formatClock(monitoring.sittingDuration)
                  : '—',
            ),
            SettingsRow(
              key: const Key('weightRow'),
              icon: AppIcons.weight,
              title: 'Berat badan',
              value: session.bodyWeightKg == null
                  ? 'Belum diisi'
                  : '${session.bodyWeightKg!.toStringAsFixed(session.bodyWeightKg! == session.bodyWeightKg!.roundToDouble() ? 0 : 1)} kg',
              onTap: () =>
                  showWeightSheet(context, current: session.bodyWeightKg),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.l),
        Text('Koreksi & notifikasi', style: t.titleMedium),
        const SizedBox(height: AppSpace.s),
        RowGroup(
          children: [
            SettingsRow(
              key: const Key('tiltRow'),
              icon: AppIcons.gauge,
              title: 'Batas kemiringan',
              value: '±${formatDeg(cfg.maxTiltDeg)}',
              onTap: () => showSliderSheet(
                context,
                title: 'Batas kemiringan',
                description:
                    'Koreksi dipertimbangkan jika sudut kursi melewati nilai '
                    'ini (0°–5°).',
                min: ChairConfig.minTilt,
                max: ChairConfig.maxTilt,
                divisions: 50,
                initial: cfg.maxTiltDeg,
                format: (v) => '±${formatDeg(v)}',
                onSave: (v) => _saveConfig(
                  context,
                  ctrl,
                  ctrl.config.copyWith(maxTiltDeg: v),
                  'Batas kemiringan',
                ),
              ),
            ),
            SettingsRow(
              key: const Key('dwellRow'),
              icon: AppIcons.timer,
              title: 'Waktu tunggu koreksi',
              value: '${cfg.dwellSeconds} detik',
              onTap: () => showSliderSheet(
                context,
                title: 'Waktu tunggu koreksi',
                description:
                    'Postur buruk harus bertahan selama ini sebelum kursi '
                    'mengoreksi sudut (20–30 detik).',
                min: ChairConfig.minDwellSeconds.toDouble(),
                max: ChairConfig.maxDwellSeconds.toDouble(),
                divisions:
                    ChairConfig.maxDwellSeconds - ChairConfig.minDwellSeconds,
                initial: cfg.dwellSeconds.toDouble(),
                format: (v) => '${v.round()} detik',
                onSave: (v) => _saveConfig(
                  context,
                  ctrl,
                  ctrl.config.copyWith(dwellSeconds: v.round()),
                  'Waktu tunggu koreksi',
                ),
              ),
            ),
            SettingsRow(
              icon: AppIcons.notifications,
              title: 'Notifikasi tekanan',
              value: 'Setelah ${monitoring.alertAfterLabel}',
            ),
          ],
        ),
        const SizedBox(height: AppSpace.l),
        Text('Aplikasi', style: t.titleMedium),
        const SizedBox(height: AppSpace.s),
        RowGroup(
          children: [
            SettingsRow(
              icon: AppIcons.demo,
              title: 'Mode demo',
              subtitle: ctrl.demoMode
                  ? 'Data simulasi dari MockChairRepository'
                  : 'Belum ada perangkat terhubung',
              trailing: Switch(
                key: const Key('demoModeSwitch'),
                value: ctrl.demoMode,
                onChanged: ctrl.setDemoMode,
              ),
            ),
            if (ctrl.simulation != null)
              SettingsRow(
                key: const Key('simulationRow'),
                icon: AppIcons.sliders,
                title: 'Kontrol simulasi',
                subtitle: 'Paksa postur, sensor rusak, uji notifikasi',
                onTap: () => showSimulationSheet(context),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.l),
        RowGroup(
          children: [
            SettingsRow(
              key: const Key('logoutRow'),
              icon: AppIcons.signOut,
              title: 'Keluar',
              destructive: true,
              onTap: () => _confirmLogout(context, session, monitoring),
            ),
          ],
        ),
      ],
    );
  }
}
