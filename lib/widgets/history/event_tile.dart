import 'package:flutter/material.dart';

import '../../models/chair_event.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/labels_id.dart';

IconData eventIcon(ChairEvent e) {
  if (e.severity == EventSeverity.error) return AppIcons.error;
  if (e.severity == EventSeverity.warning) return AppIcons.warning;
  return switch (e.type) {
    EventType.posture => AppIcons.posture,
    EventType.tilt => AppIcons.gauge,
    EventType.correction => AppIcons.sliders,
    EventType.sensor => AppIcons.sensor,
    EventType.connection => AppIcons.online,
    EventType.config => AppIcons.settings,
    EventType.system => AppIcons.info,
  };
}

Color eventTint(ChairEvent e) => switch (e.severity) {
  EventSeverity.error => AppColors.coral.withValues(alpha: 0.28),
  EventSeverity.warning => AppColors.amber.withValues(alpha: 0.28),
  EventSeverity.info => AppColors.surface,
};

/// One event: small icon, localized text, time.
class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.event});

  final ChairEvent event;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: eventTint(event),
              shape: BoxShape.circle,
            ),
            child: Icon(eventIcon(event), size: 20),
          ),
          const SizedBox(width: AppSpace.m),
          Expanded(
            child: Text(
              eventTextId(event),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.titleSmall,
            ),
          ),
          const SizedBox(width: AppSpace.m),
          Text(formatTime(event.timestamp), style: t.bodySmall),
        ],
      ),
    );
  }
}
