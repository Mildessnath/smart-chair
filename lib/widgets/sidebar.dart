import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/navigation_controller.dart';
import '../theme/app_theme.dart';

/// Left navigation. [compact] shows icons only (tablet width).
class Sidebar extends StatelessWidget {
  const Sidebar({super.key, this.compact = false, this.onNavigate});

  final bool compact;

  /// Called after navigating (used to close the drawer on mobile).
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationController>();
    return Container(
      width: compact ? 76 : 240,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Brand(compact: compact),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
                children: [
                  for (final s in DashboardSection.values)
                    _NavItem(
                      section: s,
                      selected: nav.section == s,
                      compact: compact,
                      onTap: () {
                        nav.go(s);
                        onNavigate?.call();
                      },
                    ),
                ],
              ),
            ),
            if (!compact)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Stage 1 · UI with mock data\nFirebase & ESP32 not connected',
                  style: TextStyle(fontSize: 11, color: AppColors.textFaint),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.cyan, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(Icons.chair_alt, color: Color(0xFF04222A), size: 22),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 19 : 20, 22, 16, 18),
      child: compact
          ? Align(alignment: Alignment.centerLeft, child: logo)
          : Row(
              children: [
                logo,
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Chair',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Posture Monitor',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.section,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final DashboardSection section;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.cyan : AppColors.textMuted;
    final item = Material(
      color: selected
          ? AppColors.cyan.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
          alignment: compact ? Alignment.center : Alignment.centerLeft,
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(
                selected ? section.selectedIcon : section.icon,
                color: color,
                size: 20,
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? AppColors.text : AppColors.textMuted,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: compact
          ? Tooltip(message: section.label, child: item)
          : Semantics(selected: selected, button: true, child: item),
    );
  }
}
