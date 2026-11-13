enum EventType { posture, tilt, correction, sensor, connection, config, system }

enum EventSeverity { info, warning, error }

class ChairEvent {
  const ChairEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.severity,
    required this.message,
    this.simulated = true,
    this.code,
    this.args = const {},
  });

  final String id;
  final DateTime timestamp;
  final EventType type;
  final EventSeverity severity;
  final String message;
  final bool simulated;

  /// Stable machine-readable kind, e.g. `posture_changed`. The UI uses it to
  /// build localized text; [message] stays an English fallback/log line.
  final String? code;

  /// Values for [code] (postures as enum names, angles in degrees, seconds).
  final Map<String, Object?> args;

  Map<String, dynamic> toMap() => {
    'ts': timestamp.millisecondsSinceEpoch,
    'type': type.name,
    'severity': severity.name,
    'message': message,
    'simulated': simulated,
    if (code != null) 'code': code,
    if (args.isNotEmpty) 'args': args,
  };

  factory ChairEvent.fromMap(String id, Map<String, dynamic> map) => ChairEvent(
    id: id,
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['ts'] as int),
    type: EventType.values.firstWhere(
      (t) => t.name == map['type'],
      orElse: () => EventType.system,
    ),
    severity: EventSeverity.values.firstWhere(
      (s) => s.name == map['severity'],
      orElse: () => EventSeverity.info,
    ),
    message: map['message'] as String? ?? '',
    simulated: map['simulated'] as bool? ?? false,
    code: map['code'] as String?,
    args: (map['args'] as Map?)?.cast<String, Object?>() ?? const {},
  );
}
