import 'package:flutter/material.dart';

import '../models/chair_telemetry.dart';
import '../models/load_cell.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/pressure_math.dart';
import 'state_views.dart';

/// Load cells sit at ±[_cellInset] of the seat half-width/half-depth.
const double _cellInset = 0.62;

/// Top view of the seat with four load cells and the center of pressure.
///
/// Colors encode the load at each corner only; the seat is NOT sampled
/// in between, so this is not a physical pressure distribution.
class PressureMapView extends StatelessWidget {
  const PressureMapView({
    super.key,
    required this.telemetry,
    this.scaleMaxKg = 30,
    this.showNote = true,
  });

  final ChairTelemetry? telemetry;
  final double scaleMaxKg;
  final bool showNote;

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    if (t == null) {
      return const EmptyState(
        icon: Icons.grid_off,
        title: 'No load cell data',
        message: 'Waiting for the first telemetry sample.',
      );
    }
    final cop = t.centerOfPressure;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, c) => Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SeatPainter(t, cop, scaleMaxKg),
                      ),
                    ),
                    const Align(
                      alignment: Alignment(0, -0.97),
                      child: Text(
                        'FRONT',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: AppColors.textFaint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    for (final p in LoadCellPosition.values)
                      Align(
                        alignment: Alignment(
                          p.isLeft ? -_cellInset : _cellInset,
                          p.isFront ? -_cellInset : _cellInset,
                        ),
                        child: _CellLabel(
                          reading: t.cell(p),
                          total: t.totalLoadKg,
                          small: c.maxWidth < 240,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _Legend(scaleMaxKg: scaleMaxKg, hasCop: cop != null),
        if (showNote) ...[
          const SizedBox(height: 6),
          const Text(
            'Estimated from 4 load cells. Colors show per-corner load, '
            'not a measured pressure distribution.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textFaint),
          ),
        ],
      ],
    );
  }
}

class _CellLabel extends StatelessWidget {
  const _CellLabel({
    required this.reading,
    required this.total,
    required this.small,
  });
  final LoadCellReading reading;
  final double? total;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final valid = reading.isValid;
    final share = valid && total != null && total! >= minOccupiedLoadKg
        ? reading.kg! / total! * 100
        : null;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: valid
              ? AppColors.border
              : AppColors.red.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            reading.position.shortLabel,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            valid ? formatKg(reading.kg) : reading.health.label.toUpperCase(),
            style: TextStyle(
              fontSize: small ? 11 : 13,
              fontWeight: FontWeight.w700,
              color: valid ? AppColors.text : AppColors.red,
            ),
          ),
          if (share != null && !small)
            Text(
              '${share.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.scaleMaxKg, required this.hasCop});
  final double scaleMaxKg;
  final bool hasCop;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 11, color: AppColors.textMuted);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 6,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('0 kg', style: style),
            const SizedBox(width: 6),
            Container(
              width: 110,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    for (var i = 0; i <= 8; i++) AppColors.loadIntensity(i / 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text('≥${scaleMaxKg.toStringAsFixed(0)} kg', style: style),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: hasCop ? Colors.white : AppColors.textFaint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              hasCop ? 'Center of pressure' : 'CoP n/a (empty seat or fault)',
              style: style,
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.close,
              size: 12,
              color: AppColors.red.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 4),
            const Text('Sensor fault', style: style),
          ],
        ),
      ],
    );
  }
}

class _SeatPainter extends CustomPainter {
  _SeatPainter(this.t, this.cop, this.scaleMaxKg);
  final ChairTelemetry t;
  final CenterOfPressure? cop;
  final double scaleMaxKg;

  @override
  void paint(Canvas canvas, Size size) {
    final seat = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.04,
        size.height * 0.06,
        size.width * 0.92,
        size.height * 0.9,
      ),
      Radius.circular(size.width * 0.12),
    );
    canvas.drawRRect(seat, Paint()..color = AppColors.surfaceAlt);
    final center = seat.center;
    final hx = seat.width / 2 * _cellInset;
    final hy = seat.height / 2 * _cellInset;

    // Per-corner intensity blobs.
    canvas.save();
    canvas.clipRRect(seat);
    for (final p in LoadCellPosition.values) {
      final pos = center.translate(p.isLeft ? -hx : hx, p.isFront ? -hy : hy);
      final r = t.cell(p);
      final radius = seat.width * 0.36;
      if (!r.isValid) {
        final paint = Paint()
          ..color = AppColors.red.withValues(alpha: 0.7)
          ..strokeWidth = 2;
        const d = 9.0;
        canvas.drawLine(
          pos.translate(-d, -d - 34),
          pos.translate(d, d - 34),
          paint,
        );
        canvas.drawLine(
          pos.translate(d, -d - 34),
          pos.translate(-d, d - 34),
          paint,
        );
        continue;
      }
      final color = AppColors.loadIntensity(r.kg! / scaleMaxKg);
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.85),
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1],
          ).createShader(Rect.fromCircle(center: pos, radius: radius)),
      );
    }
    canvas.restore();

    canvas.drawRRect(
      seat,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.border,
    );

    // Sensor rectangle + crosshair.
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.textFaint.withValues(alpha: 0.35);
    canvas.drawRect(
      Rect.fromCenter(center: center, width: hx * 2, height: hy * 2),
      guide,
    );
    canvas.drawLine(center.translate(-hx, 0), center.translate(hx, 0), guide);
    canvas.drawLine(center.translate(0, -hy), center.translate(0, hy), guide);

    // Center of pressure.
    final c = cop;
    if (c != null) {
      final pos = center.translate(c.x * hx, -c.y * hy);
      canvas.drawCircle(
        pos,
        11,
        Paint()..color = Colors.white.withValues(alpha: 0.18),
      );
      canvas.drawCircle(pos, 6, Paint()..color = Colors.white);
      canvas.drawCircle(
        pos,
        6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.background,
      );
    }
  }

  @override
  bool shouldRepaint(_SeatPainter old) =>
      old.t != t || old.scaleMaxKg != scaleMaxKg;
}
