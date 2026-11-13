import 'package:flutter/material.dart';

import '../../models/chair_telemetry.dart';
import '../../models/load_cell.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/labels_id.dart';
import '../../utils/pressure_math.dart';

/// Corner sensors sit at ±[_inset] of the seat half-width / half-depth.
const double _inset = 0.62;

/// Top-view seat with the four load cells and the center of pressure.
///
/// Colors encode the load at each corner only (lime → amber → coral); the
/// seat is not sampled in between, so this is an estimate from four points,
/// not a measured pressure distribution.
class PressureMap extends StatelessWidget {
  const PressureMap({
    super.key,
    required this.telemetry,
    required this.scaleMaxKg,
  });

  final ChairTelemetry? telemetry;
  final double scaleMaxKg;

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    final cop = t?.centerOfPressure;
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _SeatPainter(t, cop, scaleMaxKg)),
            ),
            Align(
              alignment: const Alignment(0, -0.96),
              child: Text(
                'DEPAN',
                style: Theme.of(context).textTheme.labelSmall!
                    .copyWith(letterSpacing: 2, fontWeight: FontWeight.w700),
              ),
            ),
            if (t != null)
              for (final p in LoadCellPosition.values)
                Align(
                  alignment: Alignment(
                    p.isLeft ? -_inset : _inset,
                    p.isFront ? -_inset : _inset,
                  ),
                  child: _CellChip(
                    reading: t.cell(p),
                    compact: c.maxWidth < 260,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _CellChip extends StatelessWidget {
  const _CellChip({required this.reading, required this.compact});

  final LoadCellReading reading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final valid = reading.isValid;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: valid ? AppColors.line : AppColors.coral,
          width: valid ? 1 : 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cellLabelId(reading.position),
            maxLines: 1,
            style: t.labelSmall!.copyWith(fontSize: compact ? 9 : 10),
          ),
          Text(
            valid ? formatKg(reading.kg) : 'FAULT',
            maxLines: 1,
            style: t.titleSmall!.copyWith(fontSize: compact ? 11 : 13),
          ),
        ],
      ),
    );
  }
}

class _SeatPainter extends CustomPainter {
  _SeatPainter(this.t, this.cop, this.scaleMaxKg);

  final ChairTelemetry? t;
  final CenterOfPressure? cop;
  final double scaleMaxKg;

  @override
  void paint(Canvas canvas, Size size) {
    final seat = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.04,
        size.height * 0.07,
        size.width * 0.92,
        size.height * 0.89,
      ),
      Radius.circular(size.width * 0.14),
    );
    canvas.drawRRect(seat, Paint()..color = AppColors.background);
    final center = seat.center;
    final hx = seat.width / 2 * _inset;
    final hy = seat.height / 2 * _inset;

    final data = t;
    if (data != null) {
      canvas.save();
      canvas.clipRRect(seat);
      for (final p in LoadCellPosition.values) {
        final r = data.cell(p);
        if (!r.isValid) continue;
        final pos = center.translate(p.isLeft ? -hx : hx, p.isFront ? -hy : hy);
        final radius = seat.width * 0.4;
        final color = AppColors.heat(r.kg! / scaleMaxKg);
        canvas.drawCircle(
          pos,
          radius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                color.withValues(alpha: 0.95),
                color.withValues(alpha: 0.4),
                color.withValues(alpha: 0),
              ],
              stops: const [0, 0.5, 1],
            ).createShader(Rect.fromCircle(center: pos, radius: radius)),
        );
      }
      canvas.restore();
    }

    canvas.drawRRect(
      seat,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.line,
    );
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.line;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: hx * 2, height: hy * 2),
      guide,
    );
    canvas.drawLine(center.translate(-hx, 0), center.translate(hx, 0), guide);
    canvas.drawLine(center.translate(0, -hy), center.translate(0, hy), guide);

    final c = cop;
    if (c != null) {
      final pos = center.translate(c.x * hx, -c.y * hy);
      canvas.drawCircle(pos, 10, Paint()..color = AppColors.ink);
      canvas.drawCircle(
        pos,
        10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.background,
      );
      canvas.drawCircle(pos, 3.5, Paint()..color = AppColors.background);
    }
  }

  @override
  bool shouldRepaint(_SeatPainter old) =>
      old.t != t || old.scaleMaxKg != scaleMaxKg;
}

/// Lime → coral scale with the CoP marker explained.
class PressureLegend extends StatelessWidget {
  const PressureLegend({super.key, required this.scaleMaxKg});

  final double scaleMaxKg;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpace.m,
      runSpacing: AppSpace.s,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ringan', style: t.labelSmall),
            const SizedBox(width: AppSpace.s),
            Container(
              width: 96,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [for (var i = 0; i <= 8; i++) AppColors.heat(i / 8)],
                ),
              ),
            ),
            const SizedBox(width: AppSpace.s),
            Text('≥ ${scaleMaxKg.toStringAsFixed(0)} kg', style: t.labelSmall),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpace.s),
            Text('Titik tekanan', style: t.labelSmall),
          ],
        ),
      ],
    );
  }
}
