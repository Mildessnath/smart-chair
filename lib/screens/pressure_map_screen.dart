import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/load_cell.dart';
import '../providers/dashboard_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/pressure_math.dart';
import '../widgets/adaptive_row.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/device_status_panel.dart';
import '../widgets/pressure_map.dart';
import '../widgets/state_views.dart';
import '../widgets/status_badge.dart';
import 'section_page.dart';

class PressureMapScreen extends StatelessWidget {
  const PressureMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final t = ctrl.latest;
    return SectionPage(
      children: [
        AdaptiveRow(
          height: 560,
          flex: const [3, 2],
          children: [
            DashboardCard(
              title: 'Live Pressure Map',
              subtitle: t == null
                  ? 'No sample'
                  : 'Sample at ${formatTime(t.timestamp)}',
              child: PressureMapView(telemetry: t),
            ),
            DashboardCard(
              title: 'Load Cell Readings',
              subtitle: 'Unit: kilograms (kg)',
              child: t == null
                  ? const EmptyState(title: 'No readings yet')
                  : _ReadingsTable(ctrl: ctrl),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReadingsTable extends StatelessWidget {
  const _ReadingsTable({required this.ctrl});
  final DashboardController ctrl;

  @override
  Widget build(BuildContext context) {
    final t = ctrl.latest!;
    final total = t.totalLoadKg;
    final cop = t.centerOfPressure;
    const head = TextStyle(
      fontSize: 11,
      color: AppColors.textFaint,
      fontWeight: FontWeight.w700,
    );
    return ListView(
      children: [
        const Row(
          children: [
            Expanded(flex: 3, child: Text('SENSOR', style: head)),
            Expanded(flex: 2, child: Text('LOAD', style: head)),
            Expanded(flex: 2, child: Text('SHARE', style: head)),
            Expanded(flex: 2, child: Text('STATUS', style: head)),
          ],
        ),
        const Divider(color: AppColors.border),
        for (final p in LoadCellPosition.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(p.label, style: const TextStyle(fontSize: 13)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    formatKg(t.cell(p).kg),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    t.cell(p).isValid &&
                            total != null &&
                            total >= minOccupiedLoadKg
                        ? '${(t.cell(p).kg! / total * 100).toStringAsFixed(0)}%'
                        : '—',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(
                      label: t.cell(p).health.label,
                      color: sensorHealthColor(t.cell(p).health),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Divider(color: AppColors.border),
        _kv('Total seat load', formatKg(total)),
        _kv(
          'Center of pressure',
          cop == null
              ? 'n/a'
              : 'x ${cop.x.toStringAsFixed(2)}, y ${cop.y.toStringAsFixed(2)}',
        ),
        _kv(
          'Occupancy',
          total == null
              ? 'unknown (sensor fault)'
              : (total >= minOccupiedLoadKg ? 'occupied' : 'empty'),
        ),
        const SizedBox(height: 14),
        const Text(
          'How this is computed',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          'CoP x = (FR + RR − FL − RL) / total, y = (FL + FR − RL − RR) / total, '
          'in the rectangle spanned by the four load cells (−1…+1). It is the '
          'location of the resultant load, valid only when all four cells '
          'report and the seat carries at least '
          '${minOccupiedLoadKg.toStringAsFixed(0)} kg.',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
        Text(
          v,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
