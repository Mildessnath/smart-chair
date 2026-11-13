import 'package:flutter_test/flutter_test.dart';
import 'package:smart_chair_dashboard/providers/user_session.dart';
import 'package:smart_chair_dashboard/screens/notifications/notifications_screen.dart';
import 'package:smart_chair_dashboard/utils/labels_id.dart';
import 'package:smart_chair_dashboard/models/chair_event.dart';
import 'package:smart_chair_dashboard/models/posture_state.dart';

void main() {
  group('parseBodyWeight', () {
    test('accepts integers, decimals with comma or dot, and a kg suffix', () {
      expect(parseBodyWeight('70'), 70);
      expect(parseBodyWeight('68,5'), 68.5);
      expect(parseBodyWeight('68.5'), 68.5);
      expect(parseBodyWeight(' 72 kg '), 72);
    });

    test('rejects empty, non-numeric and out-of-range values', () {
      expect(parseBodyWeight(''), isNull);
      expect(parseBodyWeight('abc'), isNull);
      expect(parseBodyWeight('29.9'), isNull);
      expect(parseBodyWeight('201'), isNull);
      expect(parseBodyWeight('30'), 30);
      expect(parseBodyWeight('200'), 200);
    });
  });

  group('UserSession (demo login)', () {
    test('validates email and password', () {
      expect(UserSession.validateEmail(''), isNotNull);
      expect(UserSession.validateEmail('alex'), isNotNull);
      expect(UserSession.validateEmail('alex@mail'), isNotNull);
      expect(UserSession.validateEmail('alex@mail.com'), isNull);
      expect(UserSession.validatePassword(''), isNotNull);
      expect(UserSession.validatePassword('abc'), isNotNull);
      expect(UserSession.validatePassword('abcd'), isNull);
    });

    test('login success sets the profile; failure does not', () {
      final s = UserSession();
      expect(s.login(email: 'bad', password: 'abcd'), isNotNull);
      expect(s.isLoggedIn, isFalse);
      expect(s.login(email: 'alex.k@mail.com', password: 'abcd'), isNull);
      expect(s.isLoggedIn, isTrue);
      expect(s.displayName, 'Alex');
      expect(s.initials, 'A');
    });

    test('logout clears everything, including the onboarding steps', () {
      final s = UserSession()
        ..login(email: 'alex@mail.com', password: 'abcd')
        ..setBodyWeight(70)
        ..completeChairPrompt();
      expect(s.bodyWeightKg, 70);
      expect(s.chairPromptSeen, isTrue);
      s.logout();
      expect(s.isLoggedIn, isFalse);
      expect(s.bodyWeightKg, isNull);
      expect(s.chairPromptSeen, isFalse);
    });
  });

  test('notification groups: Hari ini / Kemarin / date', () {
    final now = DateTime(2026, 11, 13, 14);
    expect(
      NotificationsScreen.groupLabel(DateTime(2026, 11, 13, 0, 1), now),
      'Hari ini',
    );
    expect(
      NotificationsScreen.groupLabel(DateTime(2026, 11, 12, 23, 59), now),
      'Kemarin',
    );
    expect(
      NotificationsScreen.groupLabel(DateTime(2026, 11, 10, 9), now),
      '10 Nov 2026',
    );
  });

  group('eventTextId', () {
    ChairEvent event(String? code, [Map<String, Object?> args = const {}]) =>
        ChairEvent(
          id: 'e',
          timestamp: DateTime(2026, 11, 13, 10),
          type: EventType.posture,
          severity: EventSeverity.info,
          message: 'English fallback',
          code: code,
          args: args,
        );

    test('localizes known codes', () {
      expect(
        eventTextId(
          event('posture_changed', {'from': 'upright', 'to': 'crossedLegs'}),
        ),
        'Postur berubah: Tegak → Melipat kaki',
      );
      expect(
        eventTextId(
          event('posture_prolonged', {'posture': 'leaningLeft', 'seconds': 15}),
        ),
        'Miring ke kiri lebih dari 15 detik',
      );
      expect(
        eventTextId(
          event('tilt_exceeded', {'angle': 3.4, 'limit': 3.0, 'paused': true}),
        ),
        'Sudut +3.4° melewati batas ±3.0° · koreksi dijeda',
      );
      expect(
        eventTextId(event('dwell_started', {'seconds': 25})),
        'Koreksi dimulai dalam 25 detik jika postur belum membaik',
      );
      expect(
        eventTextId(event('dwell_cancelled', {'reason': 'improved'})),
        'Postur membaik, koreksi dibatalkan',
      );
      expect(
        eventTextId(event('correction_settled', {'angle': 0.2})),
        'Koreksi selesai di +0.2°',
      );
      expect(
        eventTextId(event('correction_pause_changed', {'paused': false})),
        'Koreksi dilanjutkan',
      );
      expect(
        eventTextId(
          event('sensor_fault_changed', {
            'position': 'rearLeft',
            'faulty': true,
          }),
        ),
        'Load cell belakang kiri tidak terbaca',
      );
    });

    test('falls back to the English message', () {
      expect(eventTextId(event(null)), 'English fallback');
      expect(eventTextId(event('something_new')), 'English fallback');
      // Known code but missing/invalid arguments must not throw.
      expect(eventTextId(event('posture_changed')), 'English fallback');
      expect(
        eventTextId(event('posture_changed', {'from': 'x', 'to': 'y'})),
        'English fallback',
      );
    });

    test('code and args survive a map round-trip', () {
      final e = event('tilt_exceeded', {'angle': 3.4, 'limit': 3.0});
      final back = ChairEvent.fromMap('e', e.toMap());
      expect(back.code, 'tilt_exceeded');
      expect(back.args['angle'], 3.4);
      final old = ChairEvent.fromMap('o', {
        'ts': 1,
        'type': 'system',
        'severity': 'info',
        'message': 'm',
      });
      expect(old.code, isNull);
      expect(old.args, isEmpty);
    });
  });

  test('every posture has an Indonesian title', () {
    for (final p in PostureState.values) {
      expect(postureTitleId(p), isNotEmpty);
    }
    expect(postureTitleId(PostureState.crossedLegs), 'Melipat kaki');
  });
}
