import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chair_event.dart';
import '../../providers/dashboard_controller.dart';
import '../../providers/monitoring_controller.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/history_stats.dart';
import '../../widgets/history/duration_chart.dart';
import '../../widgets/history/event_tile.dart';
import '../../widgets/history/tilt_line_chart.dart';
import '../../widgets/state_views.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/section_header.dart';
import '../../widgets/ui/stat_tile.dart';

enum _Chart { duration, angle }

enum _Filter {
  all('Semua'),
  posture('Postur'),
  correction('Koreksi'),
  device('Perangkat');

  const _Filter(this.label);
  final String label;

  bool matches(ChairEvent e) => switch (this) {
    _Filter.all => true,
    _Filter.posture => e.type == EventType.posture,
    _Filter.correction =>
      e.type == EventType.tilt || e.type == EventType.correction,
    _Filter.device =>
      e.type == EventType.sensor ||
          e.type == EventType.connection ||
          e.type == EventType.system,
  };
}

/// Simulator/dev chatter (e.g. "forcing Upright") is not user history.
bool _isUserEvent(ChairEvent e) =>
    e.type != EventType.system && e.type != EventType.config ||
    e.severity != EventSeverity.info;

/// Riwayat: one big chart (switchable), a short summary, then the events.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _Chart _chart = _Chart.duration;
  _Filter _filter = _Filter.all;

  static const int _maxEvents = 40;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final monitoring = context.watch<MonitoringController>();
    if (ctrl.status == LoadStatus.loading) return const LoadingView();
    if (ctrl.status == LoadStatus.error) {
      return ErrorView(error: ctrl.error, onRetry: ctrl.load);
    }

    final t = Theme.of(context).textTheme;
    final events = ctrl.events
        .where(_isUserEvent)
        .where(_filter.matches)
        .take(_maxEvents)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.m,
        AppSpace.screen,
        AppSpace.l,
      ),
      children: [
        Text('Riwayat', style: t.headlineSmall),
        const SizedBox(height: AppSpace.xs),
        Text(
          ctrl.demoMode
              ? 'Data dari kursi (simulasi)'
              : 'Belum ada perangkat terhubung',
          style: t.bodySmall,
        ),
        const SizedBox(height: AppSpace.m),
        SegmentedButton<_Chart>(
          key: const Key('historySegments'),
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _Chart.duration, label: Text('Durasi postur')),
            ButtonSegment(value: _Chart.angle, label: Text('Sudut kursi')),
          ],
          selected: {_chart},
          onSelectionChanged: (s) => setState(() => _chart = s.first),
        ),
        const SizedBox(height: AppSpace.m),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.m),
          child: SizedBox(
            height: 280,
            child: _chart == _Chart.duration
                ? _durationChart(ctrl)
                : _angleChart(ctrl),
          ),
        ),
        const SizedBox(height: AppSpace.m),
        _chart == _Chart.duration
            ? _durationStats(ctrl, monitoring)
            : _angleStats(ctrl),
        const SizedBox(height: AppSpace.xl),
        const SectionHeader(title: 'Kejadian'),
        const SizedBox(height: AppSpace.s),
        Wrap(
          spacing: AppSpace.s,
          runSpacing: AppSpace.s,
          children: [
            for (final f in _Filter.values)
              ChoiceChip(
                key: Key('filter_${f.name}'),
                label: Text(f.label),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s),
        if (events.isEmpty)
          const _EmptyEvents()
        else
          for (final e in events)
            EventTile(key: Key('event_${e.id}'), event: e),
      ],
    );
  }

  Widget _durationChart(DashboardController ctrl) {
    if (ctrl.dailySummaries.isEmpty) {
      return const _EmptyChart(
        title: 'Belum ada riwayat durasi',
        message: 'Durasi postur harian muncul setelah kursi merekam data.',
      );
    }
    return DurationChart(days: ctrl.dailySummaries, today: ctrl.now);
  }

  Widget _angleChart(DashboardController ctrl) {
    final withAngle = ctrl.history.where((s) => s.tiltAngleDeg != null);
    if (withAngle.length < 2) {
      return const _EmptyChart(
        title: 'Belum ada data sudut',
        message: 'Grafik muncul setelah minimal dua pembacaan.',
      );
    }
    return TiltLineChart(
      history: ctrl.history,
      maxTiltDeg: ctrl.config.maxTiltDeg,
      window: ctrl.historyWindow,
    );
  }

  Widget _durationStats(DashboardController ctrl, MonitoringController m) {
    final today = ctrl.today;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                key: const Key('statGood'),
                label: 'Tegak hari ini',
                value: today == null ? '—' : formatMinutes(today.goodMinutes),
              ),
            ),
            const SizedBox(width: AppSpace.m),
            Expanded(
              child: StatTile(
                key: const Key('statBad'),
                label: 'Tidak ideal',
                value: today == null ? '—' : formatMinutes(today.badMinutes),
              ),
            ),
            const SizedBox(width: AppSpace.m),
            Expanded(
              child: StatTile(
                key: const Key('statSession'),
                label: 'Sesi ini',
                value: m.isActive ? formatClock(m.sittingDuration) : '—',
                caption: m.isActive ? null : 'Kursi belum aktif',
              ),
            ),
          ],
        ),
        if (m.isActive) ...[
          const SizedBox(height: AppSpace.s),
          Text(
            'Sesi ini: tegak ${formatClock(m.sessionGoodDuration)} · '
            'tidak ideal ${formatClock(m.sessionBadDuration)}',
            key: const Key('sessionSplit'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _angleStats(DashboardController ctrl) {
    final limit = ctrl.config.maxTiltDeg;
    final stats = tiltStats(ctrl.history, limit);
    return Row(
      children: [
        Expanded(
          child: StatTile(
            key: const Key('statNow'),
            label: 'Sekarang',
            value: formatSignedDeg(ctrl.latest?.tiltAngleDeg),
          ),
        ),
        const SizedBox(width: AppSpace.m),
        Expanded(
          child: StatTile(
            key: const Key('statRange'),
            label: 'Rentang',
            value: stats.min == null
                ? '—'
                : '${formatSignedDeg(stats.min, digits: 0)} … '
                      '${formatSignedDeg(stats.max, digits: 0)}',
          ),
        ),
        const SizedBox(width: AppSpace.m),
        Expanded(
          child: StatTile(
            key: const Key('statOver'),
            label: 'Di atas batas',
            value: formatDuration(stats.timeOverLimit),
            caption: 'batas ±${formatDeg(limit)}',
          ),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.chart, size: 32, color: AppColors.textSecondary),
          const SizedBox(height: AppSpace.s),
          Text(title, style: t.titleSmall),
          const SizedBox(height: AppSpace.xs),
          Text(message, textAlign: TextAlign.center, style: t.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.l),
      child: Center(
        child: Text(
          'Belum ada kejadian untuk filter ini.',
          style: t.bodyMedium!.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
