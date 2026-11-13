import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/daily_posture_summary.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/labels_id.dart';

/// Grouped bars: minutes in upright (lime) vs non-upright (amber) posture
/// per day. Lime is a fill only; all text on the chart is ink / grey.
class DurationChart extends StatelessWidget {
  const DurationChart({super.key, required this.days, required this.today});

  final List<DailyPostureSummary> days;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final axis = t.labelSmall!;
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
                    const FlLine(color: AppColors.line, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 60,
                    reservedSize: 34,
                    getTitlesWidget: (v, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text('${v.round()}', style: axis),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
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
                          isToday ? 'Hari ini' : weekdayShortId(d),
                          style: axis.copyWith(
                            color: isToday
                                ? AppColors.ink
                                : AppColors.textSecondary,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.ink,
                  getTooltipItem: (group, _, rod, rodIndex) => BarTooltipItem(
                    '${formatDate(days[group.x].date)}\n'
                    '${rodIndex == 0 ? 'Tegak' : 'Tidak ideal'}: '
                    '${formatMinutes(rod.toY)}',
                    t.labelMedium!.copyWith(color: AppColors.onInk),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < days.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      _rod(days[i].goodMinutes, AppColors.lime),
                      _rod(days[i].badMinutes, AppColors.amber),
                    ],
                  ),
              ],
            ),
            duration: Duration.zero,
          ),
        ),
        const SizedBox(height: AppSpace.s),
        Wrap(
          spacing: AppSpace.m,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const _LegendDot(color: AppColors.lime, label: 'Tegak'),
            const _LegendDot(color: AppColors.amber, label: 'Tidak ideal'),
            Text('Menit per hari', style: t.labelSmall),
          ],
        ),
      ],
    );
  }

  BarChartRodData _rod(double v, Color c) => BarChartRodData(
    toY: v,
    color: c,
    width: 14,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}
