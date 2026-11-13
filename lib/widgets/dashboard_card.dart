import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Standard card used by every dashboard panel.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.onOpen,
    this.padding = const EdgeInsets.all(20),
    this.fill = true,
  });

  /// true: the card has a bounded height and the child fills the remainder.
  /// false: the card sizes itself to its child (use inside scroll views).
  final bool fill;

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  /// When set, shows an "open" button that navigates to the detail page.
  final VoidCallback? onOpen;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // Material (not a colored Container) so ink effects of children show.
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
                if (onOpen != null)
                  IconButton(
                    tooltip: 'Open $title',
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_full, size: 16),
                    color: AppColors.textMuted,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (fill) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}
