import '../models/load_cell.dart';
import '../models/posture_state.dart';

/// Simulated link state used to exercise the UI.
enum SimLink {
  demo,
  online,
  offline;

  String get label => switch (this) {
    SimLink.demo => 'Demo',
    SimLink.online => 'Online (simulated)',
    SimLink.offline => 'Offline',
  };
}

/// Test hooks implemented only by simulated repositories. The UI shows the
/// simulation panel only when the active repository implements this.
abstract interface class SimulationControls {
  SimLink get link;
  void setLink(SimLink link);

  /// null = follow the scripted scenario.
  PostureState? get postureOverride;
  void setPostureOverride(PostureState? posture);

  Set<LoadCellPosition> get faultyCells;
  void setSensorFault(LoadCellPosition position, bool faulty);

  void injectWarning();

  /// Occupant weight used to scale the simulated load cell readings.
  double get bodyWeightKg;
  void setBodyWeight(double kg);

  /// Make the next initial load fail, to test the error state.
  bool get failNextLoad;
  void setFailNextLoad(bool value);
}
