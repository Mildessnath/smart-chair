import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/correction_state.dart';
import '../providers/dashboard_controller.dart';
import '../providers/navigation_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'status_badge.dart';

/// Header: section title, device status, last update, data quality flags.
class TopStatusBar extends StatelessWidget {
  const TopStatusBar({super.key, this.onMenu});

  /// Shown as a hamburger button on narrow layouts.
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final section = context.watch<NavigationController>().section;
    final device = ctrl.device;
    final latest = ctrl.latest;

    final badges = <Widget>[
      if (device != null)
        StatusBadge(
          label: device.connection.label,
          color: AppColors.connection(device.connection),
          tooltip: device.lastHeartbeat == null
              ? 'No heartbeat received'
              : 'Last heartbeat ${formatTime(device.lastHeartbeat!)}',
        ),
      if (ctrl.isStale)
        const StatusBadge(
          label: 'STALE DATA',
          color: AppColors.orange,
          icon: Icons.history_toggle_off,
        ),
      if (latest?.source == DataSource.simulated) const SimulatedTag(),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final title = Row(
            children: [
              if (onMenu != null) ...[
                IconButton(
                  onPressed: onMenu,
                  icon: const Icon(Icons.menu),
                  tooltip: 'Menu',
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      latest == null
                          ? 'No data received yet'
                          : 'Last update ${formatTime(latest.timestamp)} · '
                                '${formatAgo(ctrl.dataAge!)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final badgeWrap = Wrap(spacing: 8, runSpacing: 8, children: badges);
          if (c.maxWidth >= 700) {
            return Row(
              children: [
                Expanded(child: title),
                const SizedBox(width: 16),
                badgeWrap,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 10), badgeWrap],
          );
        },
      ),
    );
  }
}
