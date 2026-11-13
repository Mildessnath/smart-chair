import 'package:flutter/material.dart';

/// Lays children out in a row with fixed [height] on wide screens and stacks
/// them vertically (keeping the height) on narrow screens.
class AdaptiveRow extends StatelessWidget {
  const AdaptiveRow({
    super.key,
    required this.children,
    required this.height,
    this.flex,
    this.breakpoint = 920,
    this.spacing = 20,
  });

  final List<Widget> children;
  final List<int>? flex;
  final double height;
  final double breakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < breakpoint) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                SizedBox(height: height, child: children[i]),
              ],
            ],
          );
        }
        return SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                Expanded(flex: flex?[i] ?? 1, child: children[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}
