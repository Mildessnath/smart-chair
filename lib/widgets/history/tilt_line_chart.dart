import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/chair_telemetry.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/history_stats.dart';

/// Seat angle over time with the configured ±limit and the 0° target.
class TiltLineChart extends StatelessWidget {
  const TiltLineChart({
    super.key,
    required this.history,
    required this.maxTiltDeg,
    this.window = const Duration(minutes: 5),
  });

  final List<ChairTelemetry> history;
  final double maxTiltDeg;
  final Duration window;

  static double _x(DateTime t) => t.millisecondsSinceEpoch / 1000;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final axis = t.labelSmall!;
    final samples = history.where((s) => s.tiltAngleDeg != null).toList();
    final end = samples.last.timestamp;
    final start = end.subtract(window);
    final visible = samples.where((s) => !s.timestamp.isBefore(start)).toList();

    final spots = <FlSpot>[];
    for (var i = 0; i < visible.length; i++) {
      if (i > 0 &&
          visible[i].timestamp.difference(visible[i - 1].timestamp) >
              maxSampleGap) {
        spots.add(FlSpot.nullSpot); // break the line across data gaps
      }
      spots.add(FlSpot(_x(visible[i].timestamp), visible[i].tiltAngleDeg!));
    }

    final values = visible.map((s) => s.tiltAngleDeg!);
    final lo = math.min(values.reduce(math.min), -maxTiltDeg);
    final hi = math.max(values.reduce(math.max), maxTiltDeg);
    final xInterval = window.inSeconds <= 120 ? 30.0 : 60.0;

    HorizontalLine limitLine(double y) => HorizontalLine(
      y: y,
      color: AppColors.amber,
      strokeWidth: 1.5,
      dashArray: [6, 4],
    );

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              minX: _x(start),
              maxX: _x(end),
              minY: (lo - 1).floorToDouble(),
              maxY: (hi + 1).ceilToDouble(),
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppColors.line, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  limitLine(maxTiltDeg),
                  limitLine(-maxTiltDeg),
                  HorizontalLine(
                    y: 0,
                    color: AppColors.textSecondary,
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
                    reservedSize: 36,
                    getTitlesWidget: (v, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text('${v.round()}°', style: axis),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: xInterval,
                    reservedSize: 28,
                    getTitlesWidget: (v, meta) {
                      if (v == meta.min || v == meta.max) {
                        return const SizedBox.shrink();
                      }
                      final time = DateTime.fromMillisecondsSinceEpoch(
                        (v * 1000).round(),
                      );
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(formatHm(time), style: axis),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.ink,
                  getTooltipItems: (touched) => [
                    for (final s in touched)
                      LineTooltipItem(
                        '${formatTime(DateTime.fromMillisecondsSinceEpoch((s.x * 1000).round()))}\n'
                        '${formatSignedDeg(s.y)}',
                        t.labelMedium!.copyWith(color: AppColors.onInk),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: AppColors.ink,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
            duration: Duration.zero,
          ),
        ),
        const SizedBox(height: AppSpace.s),
        Text(
          'Garis putus-putus amber = batas ±${formatDeg(maxTiltDeg)} · '
          'positif = bersandar ke belakang',
          textAlign: TextAlign.center,
          style: axis,
        ),
      ],
    );
  }
}
