import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_controller.dart';
import '../widgets/state_views.dart';

/// Scrollable page body with consistent padding, max width and stale banner.
class SectionPage extends StatelessWidget {
  const SectionPage({super.key, required this.children, this.showStale = true});

  final List<Widget> children;
  final bool showStale;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();
    return LayoutBuilder(
      builder: (context, c) {
        final pad = c.maxWidth < 600 ? 16.0 : 24.0;
        final items = [
          if (showStale && ctrl.isStale)
            StaleDataBanner(
              age: ctrl.dataAge!,
              lastUpdate: ctrl.latest!.timestamp,
            ),
          ...children,
        ];
        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 20),
                    items[i],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Responsive grid of equal-width tiles (4 / 2 / 1 columns).
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final cols = c.maxWidth >= 1100 ? 4 : (c.maxWidth >= 560 ? 2 : 1);
      const gap = 16.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final t in children) SizedBox(width: w, child: t)],
      );
    },
  );
}
