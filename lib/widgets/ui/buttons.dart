import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';

/// Primary action: black pill, white label.
class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Fill the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = icon == null
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Secondary action: lime pill, black label.
class SecondaryPillButton extends StatelessWidget {
  const SecondaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = icon == null
        ? ElevatedButton(onPressed: onPressed, child: Text(label))
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
          );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Black circle with a white arrow (onboarding "next", list "go").
class CircleArrowButton extends StatelessWidget {
  const CircleArrowButton({
    super.key,
    required this.onPressed,
    this.icon = AppIcons.next,
    this.size = 56,
    this.tooltip = 'Next',
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? AppColors.ink : AppColors.line,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              size: size * 0.4,
              color: enabled ? AppColors.onInk : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Round grey icon button (back, menu, close) used in top bars.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 44,
    this.filled = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;

  /// Grey surface fill; false = transparent on colored backgrounds.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? AppColors.surface : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: 22, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
