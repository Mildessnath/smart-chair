import 'load_cell.dart';

enum DeviceConnection {
  online,
  offline,
  demo;

  String get label => switch (this) {
    DeviceConnection.online => 'Online',
    DeviceConnection.offline => 'Offline',
    DeviceConnection.demo => 'Demo Mode',
  };

  static DeviceConnection fromKey(String? key) => DeviceConnection.values
      .firstWhere((c) => c.name == key, orElse: () => DeviceConnection.offline);
}

class DeviceStatus {
  const DeviceStatus({
    required this.connection,
    required this.lastHeartbeat,
    required this.loadCellHealth,
    required this.tiltSensorHealth,
    this.firmwareVersion,
    this.wifiRssiDbm,
  });

  factory DeviceStatus.offline({DateTime? lastHeartbeat}) => DeviceStatus(
    connection: DeviceConnection.offline,
    lastHeartbeat: lastHeartbeat,
    loadCellHealth: {
      for (final p in LoadCellPosition.values) p: SensorHealth.noSignal,
    },
    tiltSensorHealth: SensorHealth.noSignal,
  );

  final DeviceConnection connection;
  final DateTime? lastHeartbeat;
  final Map<LoadCellPosition, SensorHealth> loadCellHealth;
  final SensorHealth tiltSensorHealth;
  final String? firmwareVersion;
  final int? wifiRssiDbm;

  int get faultCount =>
      loadCellHealth.values.where((h) => h == SensorHealth.fault).length +
      (tiltSensorHealth == SensorHealth.fault ? 1 : 0);

  Map<String, dynamic> toMap() => {
    'connection': connection.name,
    'lastHeartbeat': lastHeartbeat?.millisecondsSinceEpoch,
    'sensors': {
      for (final e in loadCellHealth.entries) e.key.key: e.value.name,
      'tilt': tiltSensorHealth.name,
    },
    'firmware': firmwareVersion,
    'rssi': wifiRssiDbm,
  };

  factory DeviceStatus.fromMap(Map<String, dynamic> map) {
    final sensors = (map['sensors'] as Map?)?.cast<String, dynamic>() ?? {};
    final hb = map['lastHeartbeat'] as int?;
    return DeviceStatus(
      connection: DeviceConnection.fromKey(map['connection'] as String?),
      lastHeartbeat: hb == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(hb),
      loadCellHealth: {
        for (final p in LoadCellPosition.values)
          p: SensorHealth.fromKey(sensors[p.key] as String?),
      },
      tiltSensorHealth: SensorHealth.fromKey(sensors['tilt'] as String?),
      firmwareVersion: map['firmware'] as String?,
      wifiRssiDbm: map['rssi'] as int?,
    );
  }
}
