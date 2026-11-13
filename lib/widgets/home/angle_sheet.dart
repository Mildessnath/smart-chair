import 'package:flutter/material.dart';

import '../../models/chair_telemetry.dart';
import '../../models/correction_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/labels_id.dart';

/// Detail of the seat angle: actual vs target vs limit.
Future<void> showAngleSheet(
  BuildContext context, {
  required ChairTelemetry? telemetry,
  required double maxTiltDeg,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (_) => _AngleSheet(telemetry: telemetry, maxTiltDeg: maxTiltDeg),
);

class _AngleSheet extends StatelessWidget {
  const _AngleSheet({required this.telemetry, required this.maxTiltDeg});

  final ChairTelemetry? telemetry;
  final double maxTiltDeg;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = telemetry?.correction;
    final actual = telemetry?.tiltAngleDeg;

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
      child: Row(
        children: [
          Expanded(child: Text(label, style: t.bodyMedium)),
          Text(value, style: t.titleSmall),
        ],
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          0,
          AppSpace.screen,
          AppSpace.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sudut kursi', style: t.titleLarge),
            const SizedBox(height: AppSpace.xs),
            Text(
              formatSignedDeg(actual),
              key: const Key('angleSheetValue'),
              style: t.displaySmall,
            ),
            Text('Positif = bersandar ke belakang', style: t.bodySmall),
            const SizedBox(height: AppSpace.m),
            row('Target', formatSignedDeg(c?.targetAngleDeg)),
            row('Selisih', formatSignedDeg(c?.errorDeg)),
            row('Batas', '±${formatDeg(maxTiltDeg)}'),
            row(
              'Status koreksi',
              c == null ? '—' : correctionStatusId(c.status),
            ),
            const SizedBox(height: AppSpace.s),
            Text(
              c?.source == DataSource.sensor
                  ? 'Dibaca dari sensor kemiringan.'
                  : 'Nilai simulasi, bukan dari sensor.',
              style: t.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
