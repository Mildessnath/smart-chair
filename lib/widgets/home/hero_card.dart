import 'package:flutter/material.dart';

import '../../models/chair_telemetry.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../ui/status_pill.dart';
import 'chair_illustration.dart';
import 'hero_content.dart';

/// Single main element of Beranda: posture status on a lime/amber/coral card.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.telemetry,
    required this.paused,
    required this.active,
    this.stale = false,
  });

  final ChairTelemetry? telemetry;
  final bool paused;

  /// Chair activated by the user; until then the hero only invites to do so.
  final bool active;

  /// Latest sample is older than the staleness threshold.
  final bool stale;

  static const double radius = 28;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final content = HeroContent.from(telemetry, paused: paused, active: active);
    final ink = AppColors.ink;

    return AnimatedContainer(
      key: const Key('heroCard'),
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(AppSpace.l),
      decoration: BoxDecoration(
        color: content.tone.fill,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Postur saat ini',
            style: t.labelMedium!.copyWith(color: ink.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: AppSpace.s),
          Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.s,
            children: [
              if (content.chipLabel != null)
                StatusPill(
                  key: const Key('heroChip'),
                  label: content.chipLabel!,
                  tone: StatusTone.dark,
                  icon: content.chipIcon,
                ),
              if (stale)
                const StatusPill(
                  label: 'Data tertunda',
                  icon: AppIcons.warning,
                ),
            ],
          ),
          const SizedBox(height: AppSpace.l),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _Headline(content: content)),
              const SizedBox(width: AppSpace.m),
              ChairIllustration(tiltDeg: telemetry?.tiltAngleDeg),
            ],
          ),
          const SizedBox(height: AppSpace.m),
          Text(
            content.advice,
            key: const Key('heroAdvice'),
            style: t.bodyMedium!.copyWith(color: ink),
          ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.content});
  final HeroContent content;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final countdown = content.countdown;
    if (countdown == null) {
      return Text(
        content.title,
        key: const Key('heroTitle'),
        style: t.displaySmall,
      );
    }
    // DWELL: the countdown is the headline, posture moves underneath.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Scales down instead of overflowing on narrow screens / big fonts.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$countdown',
                key: const Key('dwellCountdown'),
                style: t.displayLarge!.copyWith(fontSize: 64, height: 1),
              ),
              const SizedBox(width: AppSpace.s),
              Text('detik', style: t.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s),
        Text(content.title, key: const Key('heroTitle'), style: t.titleMedium),
      ],
    );
  }
}
