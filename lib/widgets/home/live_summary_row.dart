import 'package:flutter/material.dart';

import '../../models/chair_telemetry.dart';
import '../../models/load_cell.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/labels_id.dart';
import '../ui/app_card.dart';

/// Heat scale maximum for one corner, relative to the user's weight.
/// A corner carrying ~20% of body weight (typical upright) lands in the
/// light half of the lime → coral scale.
double heatScaleMaxKg(double? bodyWeightKg) => (bodyWeightKg ?? 70) * 0.5;

/// Swipeable "Ringkasan live": pressure, seat angle, sitting duration.
class LiveSummaryRow extends StatelessWidget {
  const LiveSummaryRow({
    super.key,
    required this.telemetry,
    required this.maxTiltDeg,
    required this.bodyWeightKg,
    required this.chairActive,
    required this.sitting,
    required this.abnormalFor,
    required this.onPressure,
    required this.onAngle,
    required this.onDuration,
  });

  final ChairTelemetry? telemetry;
  final double maxTiltDeg;
  final double? bodyWeightKg;
  final bool chairActive;
  final Duration sitting;

  /// How long the pressure has been abnormal, if it currently is.
  final Duration? abnormalFor;
  final VoidCallback onPressure;
  final VoidCallback onAngle;
  final VoidCallback onDuration;

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    final tilt = t?.tiltAngleDeg;
    final over = tilt != null && tilt.abs() > maxTiltDeg;
    final status = pressureStatusOf(t);
    final abnormal = status == PressureStatus.abnormal;

    final pressureCaption = abnormal && abnormalFor != null
        ? 'Tidak normal · ${formatDuration(abnormalFor!)}'
        : status.label;

    return SizedBox(
      height: 152,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        children: [
          SummaryCard(
            key: const Key('cardPressure'),
            icon: AppIcons.pressure,
            label: 'Peta tekanan',
            value: formatKg(t?.totalLoadKg),
            caption: pressureCaption,
            captionColor: abnormal || status == PressureStatus.sensorFault
                ? AppColors.red
                : null,
            accessory: _HeatGrid(
              telemetry: t,
              scaleMaxKg: heatScaleMaxKg(bodyWeightKg),
            ),
            onTap: onPressure,
          ),
          const SizedBox(width: AppSpace.m),
          SummaryCard(
            key: const Key('cardAngle'),
            icon: AppIcons.gauge,
            label: 'Sudut kursi',
            value: formatSignedDeg(tilt),
            caption: over
                ? 'Melewati batas ±${formatDeg(maxTiltDeg)}'
                : 'Batas ±${formatDeg(maxTiltDeg)}',
            captionColor: over ? AppColors.red : null,
            onTap: onAngle,
          ),
          const SizedBox(width: AppSpace.m),
          SummaryCard(
            key: const Key('cardDuration'),
            icon: AppIcons.timer,
            label: 'Durasi duduk',
            value: chairActive ? formatClock(sitting) : '—',
            caption: !chairActive
                ? 'Kursi belum aktif'
                : (isSeatOccupied(t) ? 'Sejak diaktifkan' : 'Kursi kosong'),
            onTap: onDuration,
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    this.captionColor,
    this.accessory,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color? captionColor;

  /// Small visual at the top-right (e.g. heat grid).
  final Widget? accessory;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      width: 176,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpace.m),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20),
                ),
                const Spacer(),
                ?accessory,
              ],
            ),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall,
            ),
            const SizedBox(height: AppSpace.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: t.headlineSmall),
            ),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.labelSmall!.copyWith(color: captionColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2×2 thumbnail of the four load cells (FL FR / RL RR), lime → coral.
class _HeatGrid extends StatelessWidget {
  const _HeatGrid({required this.telemetry, required this.scaleMaxKg});

  final ChairTelemetry? telemetry;
  final double scaleMaxKg;

  @override
  Widget build(BuildContext context) {
    Widget cell(LoadCellPosition p) {
      final r = telemetry?.cell(p);
      final color = r != null && r.isValid
          ? AppColors.heat(r.kg! / scaleMaxKg)
          : AppColors.line;
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            cell(LoadCellPosition.frontLeft),
            const SizedBox(width: 4),
            cell(LoadCellPosition.frontRight),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            cell(LoadCellPosition.rearLeft),
            const SizedBox(width: 4),
            cell(LoadCellPosition.rearRight),
          ],
        ),
      ],
    );
  }
}
