import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/posture_state.dart';
import '../providers/dashboard_controller.dart';
import '../theme/app_theme.dart';
import '../utils/history_stats.dart';
import '../utils/posture_classifier.dart';
import '../widgets/adaptive_row.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/posture_status.dart';
import '../widgets/state_views.dart';
import 'section_page.dart';

class PostureScreen extends StatelessWidget {
  const PostureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    final history = ctrl.history;
    final breakdown = postureBreakdown(history);
    final total = breakdown.values.fold(Duration.zero, (a, b) => a + b);

    return SectionPage(
      children: [
        AdaptiveRow(
          height: 400,
          children: [
            DashboardCard(
              title: 'Current Posture',
              subtitle: 'Classified from load-cell center of pressure',
              child: PostureStatusView(
                telemetry: ctrl.latest,
                heldFor: currentPostureDuration(history),
              ),
            ),
            DashboardCard(
              title: 'Time per Posture',
              subtitle:
                  'Last ${ctrl.historyWindow.inMinutes} minutes of samples',
              child: total == Duration.zero
                  ? const EmptyState(title: 'Not enough samples yet')
                  : ListView(
                      children: [
                        for (final p in PostureState.values)
                          _BreakdownBar(
                            posture: p,
                            value: breakdown[p]!,
                            total: total,
                          ),
                      ],
                    ),
            ),
          ],
        ),
        const DashboardCard(
          title: 'Classification Method (simulation)',
          subtitle: 'Explicit heuristic — not a validated algorithm',
          fill: false,
          child: _MethodText(),
        ),
      ],
    );
  }
}

class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({
    required this.posture,
    required this.value,
    required this.total,
  });
  final PostureState posture;
  final Duration value;
  final Duration total;

  @override
  Widget build(BuildContext context) {
    final f = value.inMilliseconds / total.inMilliseconds;
    final color = AppColors.posture(posture);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(postureIcon(posture), size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  posture.label,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Text(
                '${value.inSeconds}s · ${(f * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: f,
              minHeight: 7,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodText extends StatelessWidget {
  const _MethodText();

  @override
  Widget build(BuildContext context) {
    const c = PostureClassifier();
    const style = TextStyle(
      fontSize: 13,
      color: AppColors.textMuted,
      height: 1.5,
    );
    return Text(
      '1. If any load cell is faulty → Unknown. If total load < 10 kg → Unknown '
      '(seat empty).\n'
      '2. Compute center of pressure (x lateral, y fore/aft, normalized −1…+1).\n'
      '3. Subtract the upright fore/aft baseline (y ${c.foreBaseline}) because '
      'people normally load the rear of the seat more.\n'
      '4. If |x| and |y| are both below ${c.threshold} → Upright. Otherwise the '
      'axis with the larger shift decides Forward/Backward or Left/Right.\n\n'
      'Thresholds were chosen to match the simulator load profiles. They must be '
      'calibrated and validated on real users before the result is trusted.',
      style: style,
    );
  }
}
