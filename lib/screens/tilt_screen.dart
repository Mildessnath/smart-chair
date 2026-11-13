import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/history_stats.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/metric_tile.dart';
import '../widgets/state_views.dart';
import '../widgets/tilt_chart.dart';
import 'section_page.dart';

class TiltScreen extends StatefulWidget {
  const TiltScreen({super.key});

  @override
  State<TiltScreen> createState() => _TiltScreenState();
}

class _TiltScreenState extends State<TiltScreen> {
  Duration _window = const Duration(minutes: 5);

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final history = ctrl.history;
    final limit = ctrl.config.maxTiltDeg;
    final tilt = ctrl.latest?.tiltAngleDeg;
    final stats = tiltStats(history, limit);
    final recent = history.reversed.take(12).toList();

    return SectionPage(
      children: [
        TileGrid(
          children: [
            MetricTile(
              label: 'Current tilt',
              value: formatSignedDeg(tilt),
              caption: tilt == null
                  ? 'no data'
                  : (tilt.abs() > limit ? 'over limit' : 'within limit'),
              icon: Icons.straighten,
              color: tilt != null && tilt.abs() > limit
                  ? AppColors.orange
                  : AppColors.cyan,
            ),
            MetricTile(
              label: 'Configured limit',
              value: '±${formatDeg(limit)}',
              caption: 'Change in Settings',
              icon: Icons.vertical_align_center,
              color: AppColors.blue,
            ),
            MetricTile(
              label: 'Range in history',
              value: stats.min == null
                  ? '—'
                  : '${formatSignedDeg(stats.min)} … ${formatSignedDeg(stats.max)}',
              caption: 'min … max',
              icon: Icons.unfold_more,
              color: AppColors.teal,
            ),
            MetricTile(
              label: 'Time over limit',
              value: '${stats.timeOverLimit.inSeconds}s',
              caption: 'of ${stats.covered.inSeconds}s recorded',
              icon: Icons.timer_outlined,
              color: AppColors.orange,
            ),
          ],
        ),
        SizedBox(
          height: 420,
          child: DashboardCard(
            title: 'Tilt Angle over Time',
            subtitle: 'Positive = reclined back · dashed = ±limit · dotted = 0° target',
            trailing: SegmentedButton<Duration>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: const [
                ButtonSegment(value: Duration(minutes: 1), label: Text('1m')),
                ButtonSegment(value: Duration(minutes: 2), label: Text('2m')),
                ButtonSegment(value: Duration(minutes: 5), label: Text('5m')),
              ],
              selected: {_window},
              onSelectionChanged: (s) => setState(() => _window = s.first),
            ),
            child: TiltChart(
              history: history,
              maxTiltDeg: limit,
              window: _window,
            ),
          ),
        ),
        DashboardCard(
          title: 'Recent Samples',
          subtitle: 'Newest first',
          fill: false,
          child: recent.isEmpty
              ? const SizedBox(
                  height: 120,
                  child: EmptyState(title: 'No samples yet'),
                )
              : Column(
                  children: [
                    for (final t in recent)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: Text(
                                formatTime(t.timestamp),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                formatSignedDeg(t.tiltAngleDeg, digits: 2),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: (t.tiltAngleDeg?.abs() ?? 0) > limit
                                      ? AppColors.orange
                                      : AppColors.text,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                t.correction.status.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.correction(
                                    t.correction.status,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
