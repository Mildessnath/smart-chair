import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Flat side-view office chair (front faces right), black + lime on white.
///
/// The backrest rotates with the measured seat tilt (positive = reclined
/// back), exaggerated so a few degrees are visible.
class ChairIllustration extends StatelessWidget {
  const ChairIllustration({super.key, this.tiltDeg, this.size = 112});

  final double? tiltDeg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ilustrasi kursi tampak samping',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: CustomPaint(painter: _ChairPainter(tiltDeg ?? 0)),
      ),
    );
  }
}

class _ChairPainter extends CustomPainter {
  _ChairPainter(this.tiltDeg);
  final double tiltDeg;

  static const double _maxVisualTilt = 18;
  static const double _tiltExaggeration = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw in a 100×100 design space.
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    final ink = Paint()..color = AppColors.ink;
    final lime = Paint()..color = AppColors.lime;
    RRect rr(double l, double t, double r, double b, double rad) =>
        RRect.fromLTRBR(l, t, r, b, Radius.circular(rad));

    // Base bar and wheels.
    canvas.drawRRect(rr(22, 84, 78, 88, 2), ink);
    canvas.drawCircle(const Offset(25, 92), 4, ink);
    canvas.drawCircle(const Offset(75, 92), 4, ink);
    // Gas column.
    canvas.drawRRect(rr(47.5, 66, 52.5, 85, 1.5), ink);

    // Seat: black base with a lime cushion on top.
    canvas.drawRRect(rr(24, 58, 78, 67, 4.5), ink);
    canvas.drawRRect(rr(26, 52, 76, 60, 4), lime);

    // Backrest pivots around the rear of the seat.
    final degrees = (tiltDeg * _tiltExaggeration).clamp(
      -_maxVisualTilt,
      _maxVisualTilt,
    );
    canvas.save();
    canvas.translate(30, 56);
    canvas.rotate(-degrees * math.pi / 180); // reclined back = lean left
    canvas.drawRRect(rr(-5, -40, 5, 2, 4.5), ink);
    canvas.drawRRect(rr(-1.5, -37, 4, -6, 2.5), lime);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChairPainter old) => old.tiltDeg != tiltDeg;
}
