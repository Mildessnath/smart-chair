import '../models/chair_telemetry.dart';
import '../models/load_cell.dart';

/// Center of pressure in normalized seat coordinates.
///
/// x: -1 = left edge of the sensor rectangle, +1 = right edge.
/// y: -1 = rear edge, +1 = front edge.
///
/// For four load cells at the corners of a rectangle, the load-weighted
/// average of the corner positions is the resultant vertical force location.
/// It says nothing about how pressure is distributed between the corners.
class CenterOfPressure {
  const CenterOfPressure(this.x, this.y);
  final double x;
  final double y;
}

/// Seat considered empty below this total load.
const double minOccupiedLoadKg = 10;

CenterOfPressure? computeCenterOfPressure(ChairTelemetry t) =>
    centerOfPressureFromLoads({
      for (final p in LoadCellPosition.values)
        if (t.cell(p).isValid) p: t.cell(p).kg!,
    });

CenterOfPressure? centerOfPressureFromLoads(Map<LoadCellPosition, double> kg) {
  if (kg.length != LoadCellPosition.values.length) return null;
  final fl = kg[LoadCellPosition.frontLeft]!;
  final fr = kg[LoadCellPosition.frontRight]!;
  final rl = kg[LoadCellPosition.rearLeft]!;
  final rr = kg[LoadCellPosition.rearRight]!;
  final total = fl + fr + rl + rr;
  if (total < minOccupiedLoadKg) return null;
  return CenterOfPressure(
    ((fr + rr) - (fl + rl)) / total,
    ((fl + fr) - (rl + rr)) / total,
  );
}
