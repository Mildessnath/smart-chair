import 'package:flutter/material.dart';

import '../models/correction_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'state_views.dart';
import 'status_badge.dart';

/// Actual vs target seat angle with status and a ±range gauge.
class CorrectionPanel extends StatelessWidget {
  const CorrectionPanel({
    super.key,
    required this.correction,
    required this.maxTiltDeg,
    this.gaugeRangeDeg = 8,
  });

  final CorrectionState? correction;
  final double maxTiltDeg;
  final double gaugeRangeDeg;

  @override
  Widget build(BuildContext context) {
    final c = correction;
    if (c == null) {
      return const EmptyState(
        icon: Icons.tune,
        title: 'No correction data',
        message: 'Actual and target angles appear once telemetry arrives.',
      );
    }
    final statusColor = AppColors.correction(c.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusBadge(label: c.status.label, color: statusColor),
            c.source == DataSource.simulated
                ? const SimulatedTag()
                : const StatusBadge(
                    label: 'SENSOR',
                    color: AppColors.green,
                    icon: Icons.sensors,
                  ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _AngleValue(
                label: 'Actual',
                value: c.actualAngleDeg,
                color:
                    c.actualAngleDeg != null &&
                        c.actualAngleDeg!.abs() > maxTiltDeg
                    ? AppColors.orange
                    : AppColors.cyan,
              ),
            ),
            Expanded(
              child: _AngleValue(
                label: 'Target',
                value: c.targetAngleDeg,
                color: AppColors.teal,
              ),
            ),
            Expanded(
              child: _AngleValue(
                label: 'Error',
                value: c.errorDeg,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 46,
          child: CustomPaint(
            painter: _GaugePainter(
              actual: c.actualAngleDeg,
              target: c.targetAngleDeg,
              limit: maxTiltDeg,
              range: gaugeRangeDeg,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '${formatSignedDeg(-gaugeRangeDeg, digits: 0)} fwd',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textFaint,
                ),
              ),
            ),
            Flexible(
              child: Text(
                'allowed ±${formatDeg(maxTiltDeg)}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.green),
              ),
            ),
            Flexible(
              child: Text(
                'back ${formatSignedDeg(gaugeRangeDeg, digits: 0)}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textFaint,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AngleValue extends StatelessWidget {
  const _AngleValue({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value == null ? 'n/a' : formatSignedDeg(value),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    ],
  );
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.actual,
    required this.target,
    required this.limit,
    required this.range,
  });

  final double? actual;
  final double? target;
  final double limit;
  final double range;

  double _x(double deg, Size s) =>
      ((deg.clamp(-range, range) + range) / (2 * range)) * s.width;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, midY - 5, size.width, 10),
      const Radius.circular(5),
    );
    canvas.drawRRect(track, Paint()..color = AppColors.surfaceAlt);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(_x(-limit, size), midY - 5, _x(limit, size), midY + 5),
        const Radius.circular(5),
      ),
      Paint()..color = AppColors.green.withValues(alpha: 0.35),
    );
    if (target != null) {
      final x = _x(target!, size);
      canvas.drawLine(
        Offset(x, midY - 14),
        Offset(x, midY + 14),
        Paint()
          ..color = AppColors.teal
          ..strokeWidth = 2,
      );
    }
    if (actual != null) {
      final x = _x(actual!, size);
      final color = actual!.abs() > limit ? AppColors.orange : AppColors.cyan;
      final path = Path()
        ..moveTo(x, midY - 7)
        ..lineTo(x - 7, midY - 19)
        ..lineTo(x + 7, midY - 19)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawCircle(Offset(x, midY), 6, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.actual != actual ||
      old.target != target ||
      old.limit != limit ||
      old.range != range;
}
