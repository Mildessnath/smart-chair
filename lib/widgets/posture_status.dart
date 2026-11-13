import 'package:flutter/material.dart';

import '../models/chair_telemetry.dart';
import '../models/correction_state.dart';
import '../models/posture_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/posture_classifier.dart';
import 'state_views.dart';

IconData postureIcon(PostureState p) => switch (p) {
  PostureState.upright => Icons.accessibility_new,
  PostureState.leaningForward => Icons.north,
  PostureState.leaningBackward => Icons.south,
  PostureState.leaningLeft => Icons.west,
  PostureState.leaningRight => Icons.east,
  PostureState.crossedLegs => Icons.swap_calls,
  PostureState.unknown => Icons.help_outline,
};

/// Current posture with all possible states and a validation disclaimer.
class PostureStatusView extends StatelessWidget {
  const PostureStatusView({
    super.key,
    required this.telemetry,
    required this.heldFor,
    this.compact = false,
  });

  final ChairTelemetry? telemetry;
  final Duration heldFor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = telemetry;
    if (t == null) {
      return const EmptyState(
        icon: Icons.accessibility_new,
        title: 'Posture unknown',
        message: 'No telemetry received yet.',
      );
    }
    final p = t.posture;
    final color = AppColors.posture(p);
    final reason = t.source == DataSource.simulated
        ? const PostureClassifier().classify(t.loadCells).reason
        : null;
    final cop = t.centerOfPressure;

    // Scrollable so the chip list can wrap on narrow cards without overflow.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 56 : 68,
                height: compact ? 56 : 68,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  postureIcon(p),
                  color: color,
                  size: compact ? 28 : 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.label,
                      style: TextStyle(
                        fontSize: compact ? 22 : 26,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      p == PostureState.unknown
                          ? (reason ?? 'Cannot classify')
                          : 'Held for ${formatDuration(heldFor)}'
                                '${reason == null ? '' : ' · $reason'}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in PostureState.values)
                _StateChip(state: s, active: s == p),
            ],
          ),
          if (!compact && cop != null) ...[
            const SizedBox(height: 14),
            Text(
              'CoP  x ${cop.x.toStringAsFixed(2)}  ·  y ${cop.y.toStringAsFixed(2)}'
              '  (normalized, −1…+1)',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Heuristic classification on simulated data — algorithm not yet '
            'validated.',
            style: TextStyle(fontSize: 11, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state, required this.active});
  final PostureState state;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.posture(state) : AppColors.textFaint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? color.withValues(alpha: 0.6) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(postureIcon(state), size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            state.label,
            style: TextStyle(
              fontSize: 11.5,
              color: active ? color : AppColors.textMuted,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
