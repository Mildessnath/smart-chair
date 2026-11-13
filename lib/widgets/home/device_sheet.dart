import 'package:flutter/material.dart';

import '../../models/device_status.dart';
import '../../models/load_cell.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../ui/status_pill.dart';

/// Bottom sheet opened by the menu button: connection and sensor summary.
Future<void> showDeviceSheet(
  BuildContext context, {
  required DeviceStatus? status,
  required DateTime now,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _DeviceSheet(status: status, now: now),
);

String connectionLabel(DeviceConnection c) => switch (c) {
  DeviceConnection.online => 'Online',
  DeviceConnection.offline => 'Offline',
  DeviceConnection.demo => 'Mode demo',
};

class _DeviceSheet extends StatelessWidget {
  const _DeviceSheet({required this.status, required this.now});
  final DeviceStatus? status;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = status;
    final hb = s?.lastHeartbeat;
    final okCells = s == null
        ? 0
        : s.loadCellHealth.values.where((h) => h == SensorHealth.ok).length;

    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
      child: Row(
        children: [
          Expanded(child: Text(label, style: t.bodyMedium)),
          value,
        ],
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          0,
          AppSpace.screen,
          AppSpace.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status perangkat', style: t.titleLarge),
            const SizedBox(height: AppSpace.m),
            row(
              'Koneksi',
              s == null
                  ? const StatusPill(label: 'Tidak diketahui')
                  : StatusPill(
                      label: connectionLabel(s.connection),
                      tone: StatusTone.connection(s.connection),
                    ),
            ),
            row(
              'Heartbeat terakhir',
              Text(
                hb == null
                    ? 'Belum ada'
                    : '${formatTime(hb)} · ${formatAgo(now.difference(hb))}',
                style: t.titleSmall,
              ),
            ),
            row(
              'Sensor beban',
              Text('$okCells dari 4 normal', style: t.titleSmall),
            ),
            row(
              'Sensor kemiringan',
              Text(s?.tiltSensorHealth.label ?? '—', style: t.titleSmall),
            ),
            row(
              'Firmware',
              Text(s?.firmwareVersion ?? '—', style: t.titleSmall),
            ),
          ],
        ),
      ),
    );
  }
}
