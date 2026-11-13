import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chair_event.dart';
import '../providers/dashboard_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/adaptive_row.dart';
import '../widgets/correction_panel.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/event_log_list.dart';
import 'section_page.dart';

class CorrectionScreen extends StatelessWidget {
  const CorrectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final limit = ctrl.config.maxTiltDeg;
    final events = ctrl.events
        .where(
          (e) => e.type == EventType.tilt || e.type == EventType.correction,
        )
        .toList();

    return SectionPage(
      children: [
        AdaptiveRow(
          height: 330,
          children: [
            DashboardCard(
              title: 'Correction Angle',
              subtitle: 'Actual vs target seat angle',
              child: CorrectionPanel(
                correction: ctrl.latest?.correction,
                maxTiltDeg: limit,
              ),
            ),
            DashboardCard(
              title: 'Correction Events',
              subtitle: 'Limit exceeded / settled',
              child: EventLogList(events: events, dense: true),
            ),
          ],
        ),
        DashboardCard(
          title: 'How correction is simulated',
          fill: false,
          child: Text(
            '• Actual angle = simulated seat pitch (no IMU connected).\n'
            '• Target angle = 0° (level). This is a simulator assumption; the '
            'final control target is not decided yet.\n'
            '• Correction starts when |actual| exceeds the configured limit '
            '(currently ±${formatDeg(limit)}), moves at '
            '0.6°/s and stops within ±0.3° of the target.\n'
            '• Values tagged SIMULATED never come from hardware. When a real '
            'device is connected, values will be tagged SENSOR.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
