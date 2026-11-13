import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';

/// Rounded grey group of form-style rows (reference: "Edit Account").
class RowGroup extends StatelessWidget {
  const RowGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.cardAll,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: AppSpace.m + 40 + AppSpace.m),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One row: icon, title (+ optional subtitle), value and chevron / trailing.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;

  /// Replaces the value/chevron (e.g. a Switch).
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final titleStyle = destructive
        ? t.titleSmall!.copyWith(color: AppColors.red)
        : t.titleSmall;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.m,
          vertical: AppSpace.m - 4,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: AppSpace.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle),
                  if (subtitle != null) Text(subtitle!, style: t.bodySmall),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else ...[
              if (value != null)
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium!.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              if (onTap != null) ...[
                const SizedBox(width: AppSpace.xs),
                const Icon(
                  AppIcons.chevron,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
