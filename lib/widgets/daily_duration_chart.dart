import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/daily_posture_summary.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'state_views.dart';

/// Grouped bars: good vs bad posture minutes per day.
class DailyDurationChart extends StatelessWidget {
  const DailyDurationChart({
    super.key,
    required this.days,
    required this.today,
  });

  final List<DailyPostureSummary> days;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart,
        title: 'No daily statistics yet',
        message: 'Daily posture durations appear once data is recorded.',
      );
    }
    final peak = days.fold<double>(
      0,
      (m, d) => math.max(m, math.max(d.goodMinutes, d.badMinutes)),
    );
    final maxY = math.max(60.0, (peak / 60).ceil() * 60.0);

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 60,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppColors.border, strokeWidth: 0.6),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'minutes',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 60,
                    reservedSize: 36,
                    getTitlesWidget: (v, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        v.toStringAsFixed(0),
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
                    reservedSize: 26,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= days.length) {
                        return const SizedBox.shrink();
                      }
                      final d = days[i].date;
                      final isToday = isSameDay(d, today);
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          isToday ? 'Today' : formatWeekday(d),
                          style: TextStyle(
                            fontSize: 11,
                            color: isToday
                                ? AppColors.cyan
                                : AppColors.textMuted,
                            fontWeight: isToday
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surfaceAlt,
                  getTooltipItem: (group, _, rod, rodIndex) => BarTooltipItem(
                    '${formatDate(days[group.x].date)}\n'
                    '${rodIndex == 0 ? 'Good' : 'Bad'}: '
                    '${rod.toY.toStringAsFixed(0)} min',
                    TextStyle(
                      color: rodIndex == 0 ? AppColors.green : AppColors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < days.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      _rod(days[i].goodMinutes, AppColors.green),
                      _rod(days[i].badMinutes, AppColors.orange),
                    ],
                  ),
              ],
            ),
            duration: Duration.zero,
          ),
        ),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 16,
          children: [
            _LegendDot(color: AppColors.green, label: 'Good posture (Upright)'),
            _LegendDot(color: AppColors.orange, label: 'Bad posture (Leaning)'),
          ],
        ),
      ],
    );
  }

  BarChartRodData _rod(double v, Color c) => BarChartRodData(
    toY: v,
    color: c,
    width: 12,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
    ],
  );
}
