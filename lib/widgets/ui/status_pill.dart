import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Small filled pill (connection chip, status tag). Content color comes from
/// the [tone], so lime is always paired with ink.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium!
        .copyWith(color: tone.onFill);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(
        color: tone.fill,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: tone.onFill),
            const SizedBox(width: 6),
          ],
          Text(label, style: style),
        ],
      ),
    );
  }
}
