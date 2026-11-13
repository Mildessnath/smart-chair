/// Posture classes shown on the dashboard.
///
/// The classification that produces these values is a simulation heuristic
/// (see `utils/posture_classifier.dart`) and has NOT been validated against
/// real users or a reference measurement.
enum PostureState {
  upright,
  leaningForward,
  leaningBackward,
  leaningLeft,
  leaningRight,

  /// Legs crossed / folded: load shifts diagonally across the seat.
  crossedLegs,
  unknown;

  String get label => switch (this) {
    PostureState.upright => 'Upright',
    PostureState.leaningForward => 'Leaning Forward',
    PostureState.leaningBackward => 'Leaning Backward',
    PostureState.leaningLeft => 'Leaning Left',
    PostureState.leaningRight => 'Leaning Right',
    PostureState.crossedLegs => 'Crossed Legs',
    PostureState.unknown => 'Unknown',
  };

  /// Good posture for the daily duration statistic.
  bool get isGood => this == PostureState.upright;

  /// Bad posture for the daily duration statistic. `unknown` is neither.
  bool get isBad =>
      this != PostureState.upright && this != PostureState.unknown;

  /// Stable key used for storage (e.g. Firebase).
  String get key => name;

  static PostureState fromKey(String? key) => PostureState.values.firstWhere(
    (p) => p.key == key,
    orElse: () => PostureState.unknown,
  );
}
