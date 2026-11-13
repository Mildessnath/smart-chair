/// Physical placement of the four load cells under the seat (top view).
enum LoadCellPosition {
  frontLeft,
  frontRight,
  rearLeft,
  rearRight;

  String get label => switch (this) {
    LoadCellPosition.frontLeft => 'Front-Left',
    LoadCellPosition.frontRight => 'Front-Right',
    LoadCellPosition.rearLeft => 'Rear-Left',
    LoadCellPosition.rearRight => 'Rear-Right',
  };

  String get shortLabel => switch (this) {
    LoadCellPosition.frontLeft => 'FL',
    LoadCellPosition.frontRight => 'FR',
    LoadCellPosition.rearLeft => 'RL',
    LoadCellPosition.rearRight => 'RR',
  };

  /// Storage key (e.g. `loadCells/fl`).
  String get key => shortLabel.toLowerCase();

  bool get isFront =>
      this == LoadCellPosition.frontLeft || this == LoadCellPosition.frontRight;
  bool get isLeft =>
      this == LoadCellPosition.frontLeft || this == LoadCellPosition.rearLeft;

  static LoadCellPosition? fromKey(String key) {
    for (final p in LoadCellPosition.values) {
      if (p.key == key) return p;
    }
    return null;
  }
}

enum SensorHealth {
  ok,
  fault,
  noSignal;

  String get label => switch (this) {
    SensorHealth.ok => 'OK',
    SensorHealth.fault => 'Fault',
    SensorHealth.noSignal => 'No signal',
  };

  static SensorHealth fromKey(String? key) => SensorHealth.values.firstWhere(
    (h) => h.name == key,
    orElse: () => SensorHealth.noSignal,
  );
}

/// One load cell sample. [kg] is the load in kilograms (null when invalid).
class LoadCellReading {
  const LoadCellReading({
    required this.position,
    required this.kg,
    this.health = SensorHealth.ok,
  });

  final LoadCellPosition position;
  final double? kg;
  final SensorHealth health;

  bool get isValid => health == SensorHealth.ok && kg != null;

  Map<String, dynamic> toMap() => {'kg': kg, 'health': health.name};

  factory LoadCellReading.fromMap(
    LoadCellPosition position,
    Map<String, dynamic> map,
  ) => LoadCellReading(
    position: position,
    kg: (map['kg'] as num?)?.toDouble(),
    health: SensorHealth.fromKey(map['health'] as String?),
  );
}
