import 'package:flutter/material.dart';

import '../models/chair_event.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'state_views.dart';

Color severityColor(EventSeverity s) => switch (s) {
  EventSeverity.info => AppColors.blue,
  EventSeverity.warning => AppColors.orange,
  EventSeverity.error => AppColors.red,
};

IconData severityIcon(EventSeverity s) => switch (s) {
  EventSeverity.info => Icons.info_outline,
  EventSeverity.warning => Icons.warning_amber_rounded,
  EventSeverity.error => Icons.error_outline,
};

/// Scrollable list of events, newest first.
class EventLogList extends StatelessWidget {
  const EventLogList({super.key, required this.events, this.dense = false});

  final List<ChairEvent> events;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const EmptyState(
        icon: Icons.event_note,
        title: 'No events',
        message: 'Posture changes, warnings and errors will appear here.',
      );
    }
    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, i) => _EventRow(event: events[i], dense: dense),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.dense});
  final ChairEvent event;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = severityColor(event.severity);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 7 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(severityIcon(event.severity), size: 16, color: color),
          const SizedBox(width: 10),
          SizedBox(
            width: dense ? 58 : 118,
            child: Text(
              dense
                  ? formatTime(event.timestamp)
                  : formatDateTime(event.timestamp),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (!dense) ...[
            SizedBox(
              width: 86,
              child: Text(
                event.type.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 0.6,
                  color: AppColors.textFaint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          Expanded(
            child: Text(
              event.message,
              style: TextStyle(
                fontSize: 12.5,
                color: event.severity == EventSeverity.info
                    ? AppColors.text
                    : color,
              ),
            ),
          ),
          if (event.simulated && !dense)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'SIM',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.violet,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
