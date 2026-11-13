import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// "Ringkasan live ........ Lihat semua" row.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(title, style: t.titleMedium)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
              minimumSize: const Size(0, 32),
            ),
            child: Text(actionLabel!, style: t.labelMedium),
          ),
      ],
    );
  }
}
