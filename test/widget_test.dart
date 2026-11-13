import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_chair_dashboard/app.dart';
import 'package:smart_chair_dashboard/models/chair_config.dart';
import 'package:smart_chair_dashboard/repositories/chair_repository.dart';
import 'package:smart_chair_dashboard/repositories/disconnected_chair_repository.dart';
import 'package:smart_chair_dashboard/repositories/mock_chair_repository.dart';

ChairRepository _fastFactory({
  required bool demoMode,
  required ChairConfig config,
}) => demoMode
    ? MockChairRepository(initialConfig: config, loadDelay: Duration.zero)
    : DisconnectedChairRepository(initialConfig: config);

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SmartChairApp(repositoryFactory: _fastFactory));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  testWidgets('overview renders with simulated data', (tester) async {
    await _pumpApp(tester);
    expect(find.text('Smart Chair'), findsOneWidget);
    expect(find.text('Live Pressure Map'), findsOneWidget);
    expect(find.text('Demo Mode'), findsOneWidget);
    expect(find.text('SIMULATED'), findsWidgets);
    await _disposeApp(tester);
  });

  testWidgets('sidebar navigates to every section', (tester) async {
    await _pumpApp(tester);
    for (final label in [
      'Pressure Map',
      'Posture',
      'Tilt Angle',
      'Daily Duration',
      'Correction',
      'Device & Log',
      'Settings',
    ]) {
      await tester.tap(find.text(label).first);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: label);
    }
    await _disposeApp(tester);
  });

  for (final size in const [Size(900, 1000), Size(390, 844)]) {
    testWidgets('all sections render without overflow at ${size.width}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const SmartChairApp(repositoryFactory: _fastFactory),
      );
      await tester.pump(const Duration(milliseconds: 50));
      final phone = size.width < 760;
      for (final label in [
        'Pressure Map',
        'Posture',
        'Tilt Angle',
        'Daily Duration',
        'Correction',
        'Device & Log',
        'Settings',
        'Overview',
      ]) {
        if (phone) {
          await tester.tap(find.byTooltip('Menu'));
          await tester.pumpAndSettle(const Duration(milliseconds: 50));
          await tester.tap(
            find.descendant(
              of: find.byType(Drawer),
              matching: find.text(label),
            ),
          );
          await tester.pumpAndSettle(const Duration(milliseconds: 50));
        } else {
          await tester.tap(find.byTooltip(label));
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(tester.takeException(), isNull, reason: label);
      }
      await _disposeApp(tester);
    });
  }

  testWidgets('settings slider, save and reset change state', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Settings').first);
    await tester.pump(const Duration(milliseconds: 50));

    Text valueText() =>
        tester.widget<Text>(find.byKey(const Key('maxTiltValue')));
    FilledButton save() =>
        tester.widget<FilledButton>(find.byKey(const Key('saveButton')));

    expect(valueText().data, '3.0°');
    expect(save().onPressed, isNull);

    // Drag slider to the far right → 5.0°.
    await tester.drag(
      find.byKey(const Key('maxTiltSlider')),
      const Offset(2000, 0),
    );
    await tester.pump();
    expect(valueText().data, '5.0°');
    expect(find.text('Unsaved changes'), findsOneWidget);
    expect(save().onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Unsaved changes'), findsNothing);
    expect(find.textContaining('saved: 5.0°'), findsOneWidget);

    await tester.tap(find.byKey(const Key('resetButton')));
    await tester.pump();
    expect(valueText().data, '3.0°');
    expect(find.text('Unsaved changes'), findsOneWidget);
    await _disposeApp(tester);
  });

  testWidgets('demo mode off shows offline and empty states', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Settings').first);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('demoModeSwitch')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Offline'), findsOneWidget);

    await tester.tap(find.text('Overview').first);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('No load cell data'), findsOneWidget);
    expect(find.text('No tilt data yet'), findsOneWidget);
    await _disposeApp(tester);
  });
}
