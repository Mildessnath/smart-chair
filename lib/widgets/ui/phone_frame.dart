import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Keeps the mobile layout phone-width and centered on wide screens.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  static const double maxWidth = 520;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => c.maxWidth <= maxWidth
        ? child
        : ColoredBox(
            color: AppColors.surface,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          ),
  );
}
