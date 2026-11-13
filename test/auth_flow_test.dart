import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_chair_dashboard/screens/app_root.dart';
import 'package:smart_chair_dashboard/widgets/ui/buttons.dart';

import 'test_helpers.dart';

Future<void> _pumpRoot(
  WidgetTester tester, {
  Duration splash = Duration.zero,
}) => pumpApp(tester, home: AppRoot(splashDuration: splash), activate: false);

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('emailField')),
    'alex.k@mail.com',
  );
  await tester.enterText(find.byKey(const Key('passwordField')), 'rahasia');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _enterWeight(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('weightField')), text);
  await tester.pump();
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('weightNext')));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('splash shows first, then the login screen', (tester) async {
    await _pumpRoot(tester, splash: const Duration(milliseconds: 600));
    expect(find.text('Duduk sehat, setiap hari'), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsNothing);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('login validates the form and says it is a demo', (tester) async {
    await _pumpRoot(tester);
    expect(
      find.textContaining('Mode demo: belum ada server akun'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();
    expect(find.text('Email wajib diisi.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('emailField')), 'bukan-email');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();
    expect(find.text('Format email tidak valid.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('emailField')), 'a@b.co');
    await tester.enterText(find.byKey(const Key('passwordField')), 'abc');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();
    expect(find.text('Kata sandi minimal 4 karakter.'), findsOneWidget);
    expect(session(tester).isLoggedIn, isFalse);

    // The error clears as soon as the user edits.
    await tester.enterText(find.byKey(const Key('passwordField')), 'abcd');
    await tester.pump();
    expect(find.byKey(const Key('loginError')), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('password can be revealed', (tester) async {
    await _pumpRoot(tester);
    EditableText field() => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('passwordField')),
        matching: find.byType(EditableText),
      ),
    );
    expect(field().obscureText, isTrue);
    await tester.tap(find.byTooltip('Tampilkan sandi'));
    await tester.pump();
    expect(field().obscureText, isFalse);
    await disposeApp(tester);
  });

  testWidgets('weight step: validation, stepper, and it reaches the sim', (
    tester,
  ) async {
    await _pumpRoot(tester);
    await _login(tester);
    expect(find.text('Berapa berat badanmu?'), findsOneWidget);

    PrimaryPillButton next() =>
        tester.widget<PrimaryPillButton>(find.byKey(const Key('weightNext')));
    expect(next().onPressed, isNull, reason: 'empty weight');

    await _enterWeight(tester, '25');
    expect(find.byKey(const Key('weightError')), findsOneWidget);
    expect(next().onPressed, isNull);

    await _enterWeight(tester, '68,5');
    expect(find.byKey(const Key('weightError')), findsNothing);
    expect(next().onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('weightPlus')));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('weightField')))
          .controller!
          .text,
      '69.5',
    );

    await _next(tester);
    expect(find.text('Aktifkan kursimu'), findsOneWidget);
    expect(session(tester).bodyWeightKg, 69.5);
    expect(dashboard(tester).bodyWeightKg, 69.5);
    expect(dashboard(tester).simulation!.bodyWeightKg, 69.5);
    await disposeApp(tester);
  });

  testWidgets('"Nanti saja" enters the app with the chair not active', (
    tester,
  ) async {
    await _pumpRoot(tester);
    await _login(tester);
    await _enterWeight(tester, '70');
    await _next(tester);
    await tester.tap(find.byKey(const Key('skipActivation')));
    await tester.pump(const Duration(milliseconds: 400));
    await tick(tester, 2);
    expect(find.text('Kursi belum aktif'), findsWidgets);
    expect(monitoring(tester).isActive, isFalse);
    expect(find.byKey(const Key('activateChairButton')), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('"Aktifkan kursi" activates, then the duration runs', (
    tester,
  ) async {
    await _pumpRoot(tester);
    await _login(tester);
    await _enterWeight(tester, '70');
    await _next(tester);
    await tester.tap(find.byKey(const Key('activateButton')));
    await tester.pump(const Duration(milliseconds: 400));
    await tick(tester, 12);
    expect(monitoring(tester).isActive, isTrue);
    expect(find.byKey(const Key('pauseButton')), findsOneWidget);
    expect(find.text('Tegak'), findsWidgets);
    expect(
      monitoring(tester).sittingDuration.inSeconds,
      inInclusiveRange(8, 13),
    );
    await disposeApp(tester);
  });

  testWidgets('the entered weight scales the simulated load', (tester) async {
    await _pumpRoot(tester);
    await _login(tester);
    await _enterWeight(tester, '100');
    await _next(tester);
    await tester.tap(find.byKey(const Key('activateButton')));
    await tester.pump(const Duration(milliseconds: 400));
    await tick(tester, 25);
    final total = dashboard(tester).latest!.totalLoadKg!;
    // 70 kg reference seats ~60 kg; 100 kg scales to ~86 kg.
    expect(total, inInclusiveRange(78, 94));
    await disposeApp(tester);
  });

  testWidgets('logout returns to the login screen and deactivates', (
    tester,
  ) async {
    await _pumpRoot(tester);
    await _login(tester);
    await _enterWeight(tester, '70');
    await _next(tester);
    await tester.tap(find.byKey(const Key('activateButton')));
    await tester.pump(const Duration(milliseconds: 400));
    await tick(tester, 3);

    await openTab(tester, 'Profil');
    await tester.scrollUntilVisible(
      find.byKey(const Key('logoutRow')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('logoutRow')));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('confirmLogout')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('loginButton')), findsOneWidget);
    expect(session(tester).isLoggedIn, isFalse);
    expect(monitoring(tester).isActive, isFalse);
    await disposeApp(tester);
  });
}
