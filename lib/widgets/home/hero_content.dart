import 'package:flutter/widgets.dart';

import '../../models/chair_telemetry.dart';
import '../../models/correction_state.dart';
import '../../models/posture_state.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../utils/labels_id.dart';

/// What the Beranda hero shows, derived from telemetry. Pure data so the
/// state → copy/color mapping can be unit tested without widgets.
class HeroContent {
  const HeroContent({
    required this.tone,
    required this.title,
    required this.advice,
    this.countdown,
    this.chipLabel,
    this.chipIcon,
    this.paused = false,
  });

  final StatusTone tone;

  /// Posture headline, e.g. "Tegak".
  final String title;
  final String advice;

  /// Whole seconds left while in DWELL; the hero shows this as the big number.
  final int? countdown;

  /// State chip: "Memantau", "Mengoreksi", "Koreksi dijeda", "Belum aktif".
  final String? chipLabel;
  final IconData? chipIcon;
  final bool paused;

  static const String pausedLabel = 'Koreksi dijeda';

  factory HeroContent.from(
    ChairTelemetry? t, {
    required bool paused,
    required bool active,
  }) {
    if (t == null) {
      return const HeroContent(
        tone: StatusTone.neutral,
        title: 'Belum ada data',
        advice: 'Menunggu data dari kursi.',
      );
    }
    if (!active) {
      return const HeroContent(
        tone: StatusTone.neutral,
        title: 'Kursi belum aktif',
        advice:
            'Aktifkan kursi untuk mulai menghitung durasi duduk dan '
            'memantau postur.',
        chipLabel: 'Belum aktif',
        chipIcon: AppIcons.chair,
      );
    }

    final posture = t.posture;
    final c = t.correction;
    final countdown = !paused && c.phase == ControlPhase.dwell
        ? c.dwellRemaining
        : null;

    final String title;
    final String advice;
    if (posture == PostureState.unknown) {
      switch (pressureStatusOf(t)) {
        case PressureStatus.sensorFault:
          title = 'Sensor bermasalah';
          advice =
              'Salah satu sensor beban tidak terbaca, postur tidak dinilai.';
        case PressureStatus.emptySeat:
          title = 'Kursi kosong';
          advice = 'Duduklah untuk mulai memantau postur.';
        default:
          title = 'Postur tidak diketahui';
          advice = 'Postur belum dapat dikenali.';
      }
    } else {
      title = postureTitleId(posture);
      advice = _advice(posture, paused: paused, c: c);
    }

    final (label, icon) = paused
        ? (pausedLabel, AppIcons.pause)
        : switch (c.phase) {
            ControlPhase.monitor => ('Memantau', AppIcons.sensor),
            ControlPhase.dwell => ('Bersiap koreksi', AppIcons.timer),
            ControlPhase.correct => ('Mengoreksi', AppIcons.sliders),
            ControlPhase.hold => ('Menahan posisi', AppIcons.success),
          };

    return HeroContent(
      tone: StatusTone.posture(posture),
      title: title,
      advice: advice,
      countdown: countdown,
      chipLabel: label,
      chipIcon: icon,
      paused: paused,
    );
  }

  static String _advice(
    PostureState posture, {
    required bool paused,
    required CorrectionState c,
  }) {
    if (!paused) {
      switch (c.phase) {
        case ControlPhase.dwell:
          return 'Sudut kursi akan dikoreksi dalam ${c.dwellRemaining} detik '
              'jika postur belum membaik.';
        case ControlPhase.correct:
          return 'Kursi sedang menyesuaikan sudut kembali ke level.';
        case ControlPhase.hold:
          return 'Posisi ditahan sebentar. Duduk tegak agar kursi kembali '
              'normal.';
        case ControlPhase.monitor:
          break;
      }
    }
    if (paused && posture.isBad) {
      return 'Kursi tidak akan bergerak, tetapi postur tetap dipantau.';
    }
    return switch (posture) {
      PostureState.upright => 'Bagus, pertahankan punggung menempel sandaran.',
      PostureState.leaningForward =>
        'Tegakkan punggung dan sandarkan ke sandaran kursi.',
      PostureState.leaningBackward =>
        'Duduk lebih tegak, jangan terlalu bersandar.',
      PostureState.leaningLeft ||
      PostureState.leaningRight => 'Ratakan beban pada kedua sisi dudukan.',
      PostureState.crossedLegs =>
        'Turunkan kaki dan letakkan kedua telapak di lantai.',
      PostureState.unknown => '',
    };
  }
}
