import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Base card: 24 px corners, no border, flat grey fill by default.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.padding = const EdgeInsets.all(AppSpace.l - 4),
    this.onTap,
    this.lifted = false,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Adds the very soft shadow, for white cards on a white background.
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardAll,
        boxShadow: lifted ? AppShadows.soft : null,
      ),
      child: Material(
        color: color,
        borderRadius: AppRadius.cardAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
