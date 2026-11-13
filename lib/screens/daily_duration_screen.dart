import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/daily_duration_chart.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/metric_tile.dart';
import '../widgets/state_views.dart';
import 'section_page.dart';

class DailyDurationScreen extends StatelessWidget {
  const DailyDurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final days = ctrl.dailySummaries;
    final today = ctrl.today;
    final avgGood = days.isEmpty
        ? null
        : days.fold<double>(0, (s, d) => s + d.goodMinutes) / days.length;
    final ratio = today?.goodRatio;

    return SectionPage(
      children: [
        TileGrid(
          children: [
            MetricTile(
              label: 'Good posture today',
              value: today == null ? '—' : formatMinutes(today.goodMinutes),
              icon: Icons.check_circle_outline,
              color: AppColors.green,
            ),
            MetricTile(
              label: 'Bad posture today',
              value: today == null ? '—' : formatMinutes(today.badMinutes),
              icon: Icons.warning_amber_rounded,
              color: AppColors.orange,
            ),
            MetricTile(
              label: 'Good-posture ratio today',
              value: ratio == null
                  ? '—'
                  : '${(ratio * 100).toStringAsFixed(0)}%',
              caption: 'Unknown / empty seat excluded',
              icon: Icons.pie_chart_outline,
              color: AppColors.cyan,
            ),
            MetricTile(
              label: '${days.length}-day average (good)',
              value: avgGood == null ? '—' : formatMinutes(avgGood),
              icon: Icons.calendar_month_outlined,
              color: AppColors.blue,
            ),
          ],
        ),
        SizedBox(
          height: 400,
          child: DashboardCard(
            title: 'Daily Posture Duration',
            subtitle: 'Minutes per day · simulated history, today updates live',
            child: DailyDurationChart(days: days, today: ctrl.now),
          ),
        ),
        DashboardCard(
          title: 'Daily Summary',
          fill: false,
          child: days.isEmpty
              ? const SizedBox(
                  height: 120,
                  child: EmptyState(title: 'No days recorded'),
                )
              : Column(
                  children: [
                    const _SummaryRow(
                      cells: ['DATE', 'GOOD', 'BAD', 'TOTAL', 'GOOD %'],
                      header: true,
                    ),
                    const Divider(color: AppColors.border),
                    for (final d in days.reversed)
                      _SummaryRow(
                        cells: [
                          '${formatWeekday(d.date)}, ${formatDate(d.date)}',
                          formatMinutes(d.goodMinutes),
                          formatMinutes(d.badMinutes),
                          formatMinutes(d.totalMinutes),
                          d.goodRatio == null
                              ? '—'
                              : '${(d.goodRatio! * 100).toStringAsFixed(0)}%',
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.cells, this.header = false});
  final List<String> cells;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final style = header
        ? const TextStyle(
            fontSize: 11,
            color: AppColors.textFaint,
            fontWeight: FontWeight.w700,
          )
        : const TextStyle(fontSize: 13);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: i == 0 ? 3 : 2,
              child: Text(
                cells[i],
                style: !header && i == 1
                    ? style.copyWith(color: AppColors.green)
                    : (!header && i == 2
                          ? style.copyWith(color: AppColors.orange)
                          : style),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
