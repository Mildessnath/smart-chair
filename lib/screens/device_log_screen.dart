import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chair_event.dart';
import '../providers/dashboard_controller.dart';
import '../widgets/adaptive_row.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/device_status_panel.dart';
import '../widgets/event_log_list.dart';
import 'section_page.dart';

enum _LogFilter {
  all('All'),
  posture('Posture'),
  warnings('Warnings'),
  errors('Errors'),
  device('Device');

  const _LogFilter(this.label);
  final String label;

  bool matches(ChairEvent e) => switch (this) {
    _LogFilter.all => true,
    _LogFilter.posture => e.type == EventType.posture,
    _LogFilter.warnings => e.severity == EventSeverity.warning,
    _LogFilter.errors => e.severity == EventSeverity.error,
    _LogFilter.device =>
      e.type == EventType.connection || e.type == EventType.sensor,
  };
}

class DeviceLogScreen extends StatefulWidget {
  const DeviceLogScreen({super.key});

  @override
  State<DeviceLogScreen> createState() => _DeviceLogScreenState();
}

class _DeviceLogScreenState extends State<DeviceLogScreen> {
  _LogFilter _filter = _LogFilter.all;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final events = ctrl.events.where(_filter.matches).toList();

    return SectionPage(
      children: [
        AdaptiveRow(
          height: 600,
          flex: const [2, 3],
          children: [
            DashboardCard(
              title: 'Device Status',
              subtitle: 'Connection and sensor health',
              child: SingleChildScrollView(
                child: DeviceStatusPanel(status: ctrl.device, now: ctrl.now),
              ),
            ),
            DashboardCard(
              title: 'Event Log',
              subtitle: '${events.length} of ${ctrl.events.length} events',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final f in _LogFilter.values)
                        ChoiceChip(
                          label: Text(f.label),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: EventLogList(events: events)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
