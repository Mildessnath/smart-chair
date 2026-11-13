import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../providers/monitoring_controller.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui/section_header.dart';
import '../auth/auth_widgets.dart' show FormNotice;

/// Notifikasi: pressure alerts, grouped "Hari ini" / "Kemarin" / date.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  /// Group label for [when], relative to [now].
  static String groupLabel(DateTime when, DateTime now) {
    final today = dayOf(now);
    final day = dayOf(when);
    if (day == today) return 'Hari ini';
    if (day == today.subtract(const Duration(days: 1))) return 'Kemarin';
    return formatDate(when);
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<MonitoringController>();
    final t = Theme.of(context).textTheme;
    final now = m.dashboard.now;
    final items = m.notifications;

    // Items are newest first, so groups come out in that order too.
    final groups = <String, List<AppNotification>>{};
    for (final n in items) {
      groups.putIfAbsent(groupLabel(n.timestamp, now), () => []).add(n);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.m,
        AppSpace.screen,
        AppSpace.l,
      ),
      children: [
        Row(
          children: [
            Expanded(child: Text('Notifikasi', style: t.headlineSmall)),
            TextButton(
              key: const Key('markAllRead'),
              onPressed: m.unreadCount == 0 ? null : m.markAllRead,
              child: const Text('Tandai dibaca'),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s),
        FormNotice(
          icon: AppIcons.info,
          message: m.isActive
              ? 'Kamu diberi tahu jika tekanan duduk tidak normal lebih dari '
                    '${m.alertAfterLabel}.'
              : 'Kursi belum aktif, jadi pemantauan tekanan belum berjalan. '
                    'Aktifkan kursi di Beranda.',
        ),
        const SizedBox(height: AppSpace.l),
        if (items.isEmpty)
          const _Empty()
        else
          for (final e in groups.entries) ...[
            SectionHeader(title: e.key),
            const SizedBox(height: AppSpace.s),
            for (final n in e.value)
              _NotificationRow(
                key: Key('notification_${n.id}'),
                notification: n,
                onTap: () => m.markRead(n.id),
              ),
            const SizedBox(height: AppSpace.m),
          ],
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(AppIcons.notifications, size: 28),
          ),
          const SizedBox(height: AppSpace.m),
          Text('Belum ada notifikasi', style: t.titleMedium),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Notifikasi muncul saat tekanan duduk tidak normal.',
            textAlign: TextAlign.center,
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final n = notification;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.28),
                shape: BoxShape.circle,
              ),
              child: const Icon(AppIcons.warning, size: 20),
            ),
            const SizedBox(width: AppSpace.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: n.read
                        ? t.titleSmall!.copyWith(fontWeight: FontWeight.w600)
                        : t.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(n.body, style: t.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.m),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatHm(n.timestamp), style: t.bodySmall),
                const SizedBox(height: AppSpace.xs),
                if (!n.read)
                  Container(
                    key: const Key('unreadDot'),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.lime,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
