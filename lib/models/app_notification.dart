enum NotificationKind { pressure, system }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.timestamp,
    required this.title,
    required this.body,
    this.kind = NotificationKind.pressure,
    this.read = false,
    this.simulated = true,
  });

  final String id;
  final DateTime timestamp;
  final String title;
  final String body;
  final NotificationKind kind;
  final bool read;

  /// Produced from simulated data (or seeded demo content).
  final bool simulated;

  AppNotification markRead() => AppNotification(
    id: id,
    timestamp: timestamp,
    title: title,
    body: body,
    kind: kind,
    read: true,
    simulated: simulated,
  );
}
