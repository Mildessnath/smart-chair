import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chair_telemetry.dart';
import '../../models/correction_state.dart';
import '../../models/load_cell.dart';
import '../../providers/dashboard_controller.dart';
import '../../providers/monitoring_controller.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/labels_id.dart';
import '../../utils/pressure_math.dart';
import '../../widgets/home/live_summary_row.dart' show heatScaleMaxKg;
import '../../widgets/pressure/pressure_map_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/settings_row.dart';
import '../../widgets/ui/status_pill.dart';
import '../auth/auth_widgets.dart' show FormNotice;

/// Tekanan: the pressure map plus the raw data behind it.
class PressureScreen extends StatelessWidget {
  const PressureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final monitoring = context.watch<MonitoringController>();
    if (ctrl.status == LoadStatus.loading) return const LoadingView();
    if (ctrl.status == LoadStatus.error) {
      return ErrorView(error: ctrl.error, onRetry: ctrl.load);
    }

    final t = ctrl.latest;
    final t0 = Theme.of(context).textTheme;
    final status = pressureStatusOf(t);
    final scaleMax = heatScaleMaxKg(ctrl.bodyWeightKg);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.m,
        AppSpace.screen,
        AppSpace.l,
      ),
      children: [
        Row(
          children: [
            Expanded(child: Text('Peta tekanan', style: t0.headlineSmall)),
            _StatusChip(status: status),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          t == null
              ? 'Belum ada data'
              : 'Diperbarui ${formatTime(t.timestamp)}'
                    '${t.source == DataSource.simulated ? ' · simulasi' : ''}',
          style: t0.bodySmall,
        ),
        if (status == PressureStatus.abnormal) ...[
          const SizedBox(height: AppSpace.m),
          FormNotice(
            key: const Key('abnormalNotice'),
            warning: true,
            icon: AppIcons.warning,
            message: _abnormalMessage(monitoring),
          ),
        ],
        const SizedBox(height: AppSpace.m),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.m),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: PressureMap(telemetry: t, scaleMaxKg: scaleMax),
              ),
              const SizedBox(height: AppSpace.s),
              PressureLegend(scaleMaxKg: scaleMax),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        Text('Data load cell', style: t0.titleMedium),
        const SizedBox(height: AppSpace.m),
        t == null
            ? const _NoData()
            : _CellList(telemetry: t, scaleMaxKg: scaleMax),
        const SizedBox(height: AppSpace.xl),
        Text('Ringkasan', style: t0.titleMedium),
        const SizedBox(height: AppSpace.m),
        _Summary(telemetry: t, bodyWeightKg: ctrl.bodyWeightKg),
        const SizedBox(height: AppSpace.l),
        Text(
          'Diperkirakan dari 4 load cell. Warna menunjukkan beban di tiap '
          'sudut dudukan, bukan distribusi tekanan fisik yang terukur.',
          style: t0.bodySmall,
        ),
      ],
    );
  }

  String _abnormalMessage(MonitoringController m) {
    final since = m.abnormalFor;
    final threshold = m.alertAfterLabel;
    if (!m.isActive) {
      return 'Pola beban tidak seimbang. Aktifkan kursi agar notifikasi '
          'berjalan.';
    }
    return since == null
        ? 'Pola beban tidak seimbang. Kamu diberi tahu jika berlangsung '
              'lebih dari $threshold.'
        : 'Tidak normal selama ${formatDuration(since)}. Kamu diberi tahu '
              'jika berlangsung lebih dari $threshold.';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final PressureStatus status;

  @override
  Widget build(BuildContext context) => StatusPill(
    key: const Key('pressureStatus'),
    label: status.label,
    tone: switch (status) {
      PressureStatus.normal => StatusTone.good,
      PressureStatus.abnormal => StatusTone.warning,
      PressureStatus.sensorFault => StatusTone.alert,
      _ => StatusTone.neutral,
    },
  );
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) => const EmptyState(
    title: 'Belum ada data load cell',
    message: 'Data muncul setelah kursi mengirim pembacaan pertama.',
  );
}

class _CellList extends StatelessWidget {
  const _CellList({required this.telemetry, required this.scaleMaxKg});

  final ChairTelemetry telemetry;
  final double scaleMaxKg;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final total = telemetry.totalLoadKg;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.m,
        vertical: AppSpace.s,
      ),
      child: Column(
        children: [
          for (final p in LoadCellPosition.values)
            Padding(
              key: Key('cell_${p.key}'),
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
              child: _CellRow(
                reading: telemetry.cell(p),
                share: total == null || total < minOccupiedLoadKg
                    ? null
                    : (telemetry.cell(p).kg ?? 0) / total,
                scaleMaxKg: scaleMaxKg,
                textTheme: t,
              ),
            ),
        ],
      ),
    );
  }
}

class _CellRow extends StatelessWidget {
  const _CellRow({
    required this.reading,
    required this.share,
    required this.scaleMaxKg,
    required this.textTheme,
  });

  final LoadCellReading reading;
  final double? share;
  final double scaleMaxKg;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final valid = reading.isValid;
    final fraction = valid ? (reading.kg! / scaleMaxKg).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                cellLabelId(reading.position),
                style: textTheme.titleSmall,
              ),
            ),
            if (valid) ...[
              Text(formatKg(reading.kg), style: textTheme.titleSmall),
              if (share != null) ...[
                const SizedBox(width: AppSpace.s),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(share! * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.end,
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ] else
              Text(
                reading.health.label,
                style: textTheme.titleSmall!.copyWith(color: AppColors.red),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation(AppColors.heat(fraction)),
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.telemetry, required this.bodyWeightKg});

  final ChairTelemetry? telemetry;
  final double? bodyWeightKg;

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    final total = t?.totalLoadKg;
    final cop = t?.centerOfPressure;
    final ofBody = total != null && bodyWeightKg != null && bodyWeightKg! > 0
        ? total / bodyWeightKg! * 100
        : null;

    return RowGroup(
      children: [
        SettingsRow(
          icon: AppIcons.pressure,
          title: 'Total beban',
          value: formatKg(total),
        ),
        SettingsRow(
          icon: AppIcons.weight,
          title: 'Dari berat badan',
          value: ofBody == null
              ? '—'
              : '${ofBody.toStringAsFixed(0)}% dari '
                    '${bodyWeightKg!.toStringAsFixed(0)} kg',
        ),
        SettingsRow(
          icon: AppIcons.sensor,
          title: 'Titik tekanan',
          value: cop == null
              ? '—'
              : 'x ${cop.x.toStringAsFixed(2)} · y ${cop.y.toStringAsFixed(2)}',
        ),
        SettingsRow(
          icon: AppIcons.posture,
          title: 'Postur terdeteksi',
          value: t == null ? '—' : postureTitleId(t.posture),
        ),
      ],
    );
  }
}
