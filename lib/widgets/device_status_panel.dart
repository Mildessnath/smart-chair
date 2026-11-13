import 'package:flutter/material.dart';

import '../models/device_status.dart';
import '../models/load_cell.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'state_views.dart';
import 'status_badge.dart';

Color sensorHealthColor(SensorHealth h) => switch (h) {
  SensorHealth.ok => AppColors.green,
  SensorHealth.fault => AppColors.red,
  SensorHealth.noSignal => AppColors.slate,
};

/// Connection, heartbeat and per-sensor health.
class DeviceStatusPanel extends StatelessWidget {
  const DeviceStatusPanel({super.key, required this.status, required this.now});

  final DeviceStatus? status;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = status;
    if (s == null) {
      return const EmptyState(
        icon: Icons.memory,
        title: 'Device status unknown',
        message: 'No status received from the repository.',
      );
    }
    final hb = s.lastHeartbeat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
          'Connection',
          StatusBadge(
            label: s.connection.label,
            color: AppColors.connection(s.connection),
          ),
        ),
        _Row(
          'Last heartbeat',
          Text(
            hb == null
                ? 'never'
                : '${formatTime(hb)} (${formatAgo(now.difference(hb))})',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        _Row(
          'Firmware',
          Text(s.firmwareVersion ?? '—', style: const TextStyle(fontSize: 13)),
        ),
        _Row(
          'Wi-Fi RSSI',
          Text(
            s.wifiRssiDbm == null ? '—' : '${s.wifiRssiDbm} dBm',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 14, bottom: 8),
          child: Text(
            'SENSORS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              color: AppColors.textFaint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final p in LoadCellPosition.values)
          _Row(
            'Load cell ${p.label}',
            StatusBadge(
              label: s.loadCellHealth[p]?.label ?? 'Unknown',
              color: sensorHealthColor(
                s.loadCellHealth[p] ?? SensorHealth.noSignal,
              ),
            ),
          ),
        _Row(
          'Tilt sensor (IMU)',
          StatusBadge(
            label: s.tiltSensorHealth.label,
            color: sensorHealthColor(s.tiltSensorHealth),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
        value,
      ],
    ),
  );
}
