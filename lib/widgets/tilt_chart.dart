import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/chair_telemetry.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/history_stats.dart';
import 'state_views.dart';

/// Seat tilt vs time with the configured ±limit and the 0° target.
class TiltChart extends StatelessWidget {
  const TiltChart({
    super.key,
    required this.history,
    required this.maxTiltDeg,
    this.window = const Duration(minutes: 5),
  });

  final List<ChairTelemetry> history;
  final double maxTiltDeg;

  /// Only samples within this window before the latest one are drawn.
  final Duration window;

  static double _x(DateTime t) => t.millisecondsSinceEpoch / 1000;

  @override
  Widget build(BuildContext context) {
    final samples = history.where((t) => t.tiltAngleDeg != null).toList();
    if (samples.length < 2) {
      return const EmptyState(
        icon: Icons.show_chart,
        title: 'No tilt data yet',
        message: 'The chart appears after at least two samples.',
      );
    }
    final end = samples.last.timestamp;
    final start = end.subtract(window);
    final visible = samples.where((t) => !t.timestamp.isBefore(start)).toList();

    final spots = <FlSpot>[];
    for (var i = 0; i < visible.length; i++) {
      if (i > 0 &&
          visible[i].timestamp.difference(visible[i - 1].timestamp) >
              maxSampleGap) {
        spots.add(FlSpot.nullSpot); // break the line across data gaps
      }
      spots.add(FlSpot(_x(visible[i].timestamp), visible[i].tiltAngleDeg!));
    }

    final values = visible.map((t) => t.tiltAngleDeg!);
    final lo = math.min(values.reduce(math.min), -maxTiltDeg);
    final hi = math.max(values.reduce(math.max), maxTiltDeg);
    final minY = (lo - 1).floorToDouble();
    final maxY = (hi + 1).ceilToDouble();
    final span = window.inSeconds;
    final xInterval = span <= 120 ? 30.0 : 60.0;

    HorizontalLine limitLine(double y) => HorizontalLine(
      y: y,
      color: AppColors.orange.withValues(alpha: 0.8),
      strokeWidth: 1.2,
      dashArray: [6, 4],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        style: const TextStyle(fontSize: 10, color: AppColors.orange),
        labelResolver: (l) => 'limit ${formatSignedDeg(l.y)}',
      ),
    );

    return LineChart(
      LineChartData(
        minX: _x(start),
        maxX: _x(end),
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          drawVerticalLine: true,
          horizontalInterval: 2,
          verticalInterval: xInterval,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.border, strokeWidth: 0.6),
          getDrawingVerticalLine: (_) =>
              const FlLine(color: AppColors.border, strokeWidth: 0.6),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            limitLine(maxTiltDeg),
            limitLine(-maxTiltDeg),
            HorizontalLine(
              y: 0,
              color: AppColors.teal.withValues(alpha: 0.6),
              strokeWidth: 1,
              dashArray: [2, 4],
            ),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              reservedSize: 38,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  '${v.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: xInterval,
              reservedSize: 26,
              getTitlesWidget: (v, meta) {
                if (v == meta.min || v == meta.max) {
                  return const SizedBox.shrink();
                }
                final t = DateTime.fromMillisecondsSinceEpoch(
                  (v * 1000).round(),
                );
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    formatTime(t),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceAlt,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${formatTime(DateTime.fromMillisecondsSinceEpoch((s.x * 1000).round()))}\n'
                  '${formatSignedDeg(s.y)}',
                  TextStyle(
                    color: s.y.abs() > maxTiltDeg
                        ? AppColors.orange
                        : AppColors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: AppColors.cyan,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}
