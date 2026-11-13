import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_controller.dart';
import '../providers/navigation_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/history_stats.dart';
import '../widgets/adaptive_row.dart';
import '../widgets/correction_panel.dart';
import '../widgets/daily_duration_chart.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/event_log_list.dart';
import '../widgets/metric_tile.dart';
import '../widgets/posture_status.dart';
import '../widgets/pressure_map.dart';
import '../widgets/tilt_chart.dart';
import 'section_page.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final nav = context.read<NavigationController>();
    final latest = ctrl.latest;
    final history = ctrl.history;
    final limit = ctrl.config.maxTiltDeg;
    final tilt = latest?.tiltAngleDeg;
    final today = ctrl.today;
    final ratio = today?.goodRatio;

    return SectionPage(
      children: [
        TileGrid(
          children: [
            MetricTile(
              label: 'Posture now',
              value: latest?.posture.label ?? 'No data',
              caption: latest == null
                  ? 'Waiting for telemetry'
                  : 'held ${formatDuration(currentPostureDuration(history))}',
              icon: latest == null
                  ? Icons.help_outline
                  : postureIcon(latest.posture),
              color: latest == null
                  ? AppColors.slate
                  : AppColors.posture(latest.posture),
              onTap: () => nav.go(DashboardSection.posture),
            ),
            MetricTile(
              label: 'Seat tilt',
              value: formatSignedDeg(tilt),
              caption: 'limit ±${formatDeg(limit)}',
              icon: Icons.straighten,
              color: tilt != null && tilt.abs() > limit
                  ? AppColors.orange
                  : AppColors.cyan,
              onTap: () => nav.go(DashboardSection.tilt),
            ),
            MetricTile(
              label: 'Good posture today',
              value: today == null ? '—' : formatMinutes(today.goodMinutes),
              caption: ratio == null
                  ? 'no data today'
                  : '${(ratio * 100).toStringAsFixed(0)}% of tracked time',
              icon: Icons.check_circle_outline,
              color: AppColors.green,
              onTap: () => nav.go(DashboardSection.daily),
            ),
            MetricTile(
              label: 'Bad posture today',
              value: today == null ? '—' : formatMinutes(today.badMinutes),
              caption: ratio == null
                  ? 'no data today'
                  : '${((1 - ratio) * 100).toStringAsFixed(0)}% of tracked time',
              icon: Icons.warning_amber_rounded,
              color: AppColors.orange,
              onTap: () => nav.go(DashboardSection.daily),
            ),
          ],
        ),
        AdaptiveRow(
          height: 420,
          children: [
            DashboardCard(
              title: 'Live Pressure Map',
              subtitle: 'Top view · 4 load cells',
              onOpen: () => nav.go(DashboardSection.pressure),
              child: PressureMapView(telemetry: latest, showNote: false),
            ),
            DashboardCard(
              title: 'Posture Status',
              subtitle: 'From load-cell center of pressure',
              onOpen: () => nav.go(DashboardSection.posture),
              child: PostureStatusView(
                telemetry: latest,
                heldFor: currentPostureDuration(history),
              ),
            ),
          ],
        ),
        AdaptiveRow(
          height: 340,
          flex: const [3, 2],
          children: [
            DashboardCard(
              title: 'Tilt Angle',
              subtitle: 'Last 2 minutes · ±${formatDeg(limit)} limit',
              onOpen: () => nav.go(DashboardSection.tilt),
              child: TiltChart(
                history: history,
                maxTiltDeg: limit,
                window: const Duration(minutes: 2),
              ),
            ),
            DashboardCard(
              title: 'Correction Angle',
              subtitle: 'Actual vs target',
              onOpen: () => nav.go(DashboardSection.correction),
              child: CorrectionPanel(
                correction: latest?.correction,
                maxTiltDeg: limit,
              ),
            ),
          ],
        ),
        AdaptiveRow(
          height: 340,
          flex: const [3, 2],
          children: [
            DashboardCard(
              title: 'Daily Posture Duration',
              subtitle: 'Last 7 days · minutes',
              onOpen: () => nav.go(DashboardSection.daily),
              child: DailyDurationChart(
                days: ctrl.dailySummaries,
                today: ctrl.now,
              ),
            ),
            DashboardCard(
              title: 'Recent Events',
              subtitle: '${ctrl.events.length} in log',
              onOpen: () => nav.go(DashboardSection.device),
              child: EventLogList(
                events: ctrl.events.take(30).toList(),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
