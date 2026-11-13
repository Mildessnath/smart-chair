import '../models/chair_event.dart';
import '../models/chair_telemetry.dart';
import '../models/correction_state.dart';
import '../models/load_cell.dart';
import '../models/posture_state.dart';
import 'formatters.dart';
import 'pressure_math.dart';

/// Indonesian UI labels. Model enums keep English labels for logs/storage.
String postureTitleId(PostureState p) => switch (p) {
  PostureState.upright => 'Tegak',
  PostureState.leaningForward => 'Condong ke depan',
  PostureState.leaningBackward => 'Condong ke belakang',
  PostureState.leaningLeft => 'Miring ke kiri',
  PostureState.leaningRight => 'Miring ke kanan',
  PostureState.crossedLegs => 'Melipat kaki',
  PostureState.unknown => 'Tidak diketahui',
};

String cellLabelId(LoadCellPosition p) => switch (p) {
  LoadCellPosition.frontLeft => 'Depan kiri',
  LoadCellPosition.frontRight => 'Depan kanan',
  LoadCellPosition.rearLeft => 'Belakang kiri',
  LoadCellPosition.rearRight => 'Belakang kanan',
};

String correctionStatusId(CorrectionStatus s) => switch (s) {
  CorrectionStatus.withinLimit => 'Dalam batas',
  CorrectionStatus.pending => 'Menunggu koreksi',
  CorrectionStatus.correcting => 'Mengoreksi',
  CorrectionStatus.paused => 'Dijeda',
  CorrectionStatus.unavailable => 'Tidak tersedia',
  CorrectionStatus.fault => 'Gangguan',
};

/// How the pressure distribution should be judged right now.
enum PressureStatus {
  noData,
  emptySeat,
  sensorFault,
  normal,

  /// Seat is occupied but the load pattern is not an upright posture.
  abnormal;

  String get label => switch (this) {
    PressureStatus.noData => 'Belum ada data',
    PressureStatus.emptySeat => 'Kursi kosong',
    PressureStatus.sensorFault => 'Sensor bermasalah',
    PressureStatus.normal => 'Normal',
    PressureStatus.abnormal => 'Tidak normal',
  };
}

PressureStatus pressureStatusOf(ChairTelemetry? t) {
  if (t == null) return PressureStatus.noData;
  if (!t.allCellsValid) return PressureStatus.sensorFault;
  if ((t.totalLoadKg ?? 0) < minOccupiedLoadKg) return PressureStatus.emptySeat;
  return t.posture.isBad ? PressureStatus.abnormal : PressureStatus.normal;
}

/// Seat is occupied when all sensors report and the load is above the
/// occupancy threshold.
bool isSeatOccupied(ChairTelemetry? t) =>
    t != null && (t.totalLoadKg ?? 0) >= minOccupiedLoadKg;

/// Parses a body weight typed by the user. Accepts "70", "70,5", "70.5 kg".
/// Returns null when it is not a number or outside the plausible range.
double? parseBodyWeight(String input) {
  final cleaned = input
      .toLowerCase()
      .replaceAll('kg', '')
      .replaceAll(',', '.')
      .trim();
  final v = double.tryParse(cleaned);
  if (v == null || v < minBodyWeightKg || v > maxBodyWeightKg) return null;
  return v;
}

const double minBodyWeightKg = 30;
const double maxBodyWeightKg = 200;

/// Short Indonesian weekday ("Sen" … "Min").
String weekdayShortId(DateTime d) =>
    const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][d.weekday - 1];

/// Localized one-line text for [e]. Events without a [ChairEvent.code], or
/// with an unknown one, fall back to the English [ChairEvent.message].
String eventTextId(ChairEvent e) {
  PostureState? posture(String key) {
    final name = e.args[key];
    for (final p in PostureState.values) {
      if (p.name == name) return p;
    }
    return null;
  }

  num? number(String key) => e.args[key] is num ? e.args[key] as num : null;

  switch (e.code) {
    case 'posture_changed':
      final from = posture('from');
      final to = posture('to');
      if (from != null && to != null) {
        return 'Postur berubah: ${postureTitleId(from)} → '
            '${postureTitleId(to)}';
      }
    case 'posture_prolonged':
      final p = posture('posture');
      final s = number('seconds');
      if (p != null && s != null) {
        return '${postureTitleId(p)} lebih dari ${s.round()} detik';
      }
    case 'tilt_exceeded':
      final angle = number('angle');
      final limit = number('limit');
      if (angle != null && limit != null) {
        final paused = e.args['paused'] == true ? ' · koreksi dijeda' : '';
        return 'Sudut ${formatSignedDeg(angle.toDouble())} melewati batas '
            '±${formatDeg(limit.toDouble())}$paused';
      }
    case 'dwell_started':
      final s = number('seconds');
      if (s != null) {
        return 'Koreksi dimulai dalam ${s.round()} detik jika postur belum '
            'membaik';
      }
    case 'dwell_cancelled':
      return e.args['reason'] == 'paused'
          ? 'Koreksi dijeda, hitung mundur dibatalkan'
          : 'Postur membaik, koreksi dibatalkan';
    case 'correction_started':
      return 'Kursi mulai mengoreksi sudut';
    case 'correction_stopped':
      return 'Koreksi dijeda, kursi berhenti bergerak';
    case 'correction_settled':
      final angle = number('angle');
      if (angle != null) {
        return 'Koreksi selesai di ${formatSignedDeg(angle.toDouble())}';
      }
    case 'correction_pause_changed':
      return e.args['paused'] == true
          ? 'Koreksi dijeda'
          : 'Koreksi dilanjutkan';
    case 'sensor_fault_changed':
      final name = e.args['position'];
      for (final p in LoadCellPosition.values) {
        if (p.name == name) {
          return e.args['faulty'] == true
              ? 'Load cell ${cellLabelId(p).toLowerCase()} tidak terbaca'
              : 'Load cell ${cellLabelId(p).toLowerCase()} kembali normal';
        }
      }
    case 'link_lost':
      return 'Koneksi ke kursi terputus';
    case 'link_changed':
      return 'Status koneksi berubah';
  }
  return e.message;
}
