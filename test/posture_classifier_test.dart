import 'package:flutter_test/flutter_test.dart';
import 'package:smart_chair_dashboard/models/load_cell.dart';
import 'package:smart_chair_dashboard/models/posture_state.dart';
import 'package:smart_chair_dashboard/services/chair_simulator.dart';
import 'package:smart_chair_dashboard/utils/posture_classifier.dart';
import 'package:smart_chair_dashboard/utils/pressure_math.dart';

Map<LoadCellPosition, LoadCellReading> cells(List<double> kg) => {
  for (final p in LoadCellPosition.values)
    p: LoadCellReading(position: p, kg: kg[p.index]),
};

void main() {
  const classifier = PostureClassifier();

  test('each simulator load profile is classified as its own posture', () {
    for (final entry in ChairSimulator.loadProfiles.entries) {
      expect(
        classifier.classify(cells(entry.value)).posture,
        entry.key,
        reason: entry.key.label,
      );
    }
  });

  test('faulty sensor yields unknown', () {
    final c = cells([13, 13, 17, 17]);
    c[LoadCellPosition.rearLeft] = const LoadCellReading(
      position: LoadCellPosition.rearLeft,
      kg: null,
      health: SensorHealth.fault,
    );
    expect(classifier.classify(c).posture, PostureState.unknown);
  });

  test('center of pressure is the load-weighted corner average', () {
    final cop = centerOfPressureFromLoads({
      LoadCellPosition.frontLeft: 10,
      LoadCellPosition.frontRight: 30,
      LoadCellPosition.rearLeft: 10,
      LoadCellPosition.rearRight: 30,
    })!;
    expect(cop.x, closeTo(0.5, 1e-9)); // (60 - 20) / 80
    expect(cop.y, closeTo(0, 1e-9));
  });

  test('center of pressure is null for an empty seat', () {
    expect(
      centerOfPressureFromLoads({
        for (final p in LoadCellPosition.values) p: 0.5,
      }),
      isNull,
    );
  });

  group('crossed legs (diagonal load pattern)', () {
    test('FR + RL heavy and FL + RR heavy are both crossed legs', () {
      expect(
        classifier.classify(cells([8, 19, 22, 11])).posture,
        PostureState.crossedLegs,
      );
      expect(
        classifier.classify(cells([19, 8, 11, 22])).posture,
        PostureState.crossedLegs,
      );
    });

    test('plain leaning is not mistaken for crossed legs', () {
      expect(
        classifier.classify(cells([19, 9, 22, 10])).posture,
        PostureState.leaningLeft,
      );
      expect(
        classifier.classify(cells([9, 19, 10, 22])).posture,
        PostureState.leaningRight,
      );
      expect(
        classifier.classify(cells([20, 20, 10, 10])).posture,
        PostureState.leaningForward,
      );
      expect(
        classifier.classify(cells([8, 8, 22, 22])).posture,
        PostureState.leaningBackward,
      );
      expect(
        classifier.classify(cells([13, 13, 17, 17])).posture,
        PostureState.upright,
      );
    });

    test('is robust to a small amount of sensor noise', () {
      for (final noise in [-0.6, 0.0, 0.6]) {
        expect(
          classifier
              .classify(cells([8 + noise, 19 - noise, 22 + noise, 11 - noise]))
              .posture,
          PostureState.crossedLegs,
        );
      }
    });

    test('counts as bad posture and is never corrected', () {
      expect(PostureState.crossedLegs.isBad, isTrue);
      expect(PostureState.crossedLegs.isGood, isFalse);
    });
  });
}
