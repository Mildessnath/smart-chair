import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/ui/phone_frame.dart';

/// Shared page frame for sign-in/onboarding steps.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  /// 1-based step shown in the progress dots (of [steps]).
  final int step;
  final String title;
  final String subtitle;
  final Widget child;

  /// Pinned bottom actions.
  final Widget footer;

  static const int steps = 3;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return PhoneFrame(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.screen + 4,
                    AppSpace.l,
                    AppSpace.screen + 4,
                    AppSpace.l,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StepDots(current: step, total: steps),
                      const SizedBox(height: AppSpace.xl),
                      Text(title, style: t.headlineMedium),
                      const SizedBox(height: AppSpace.s),
                      Text(
                        subtitle,
                        style: t.bodyMedium!.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xl),
                      child,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen + 4,
                  AppSpace.s,
                  AppSpace.screen + 4,
                  AppSpace.l,
                ),
                child: footer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Langkah $current dari $total',
    child: Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: i == current ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current
                  ? AppColors.lime
                  : (i < current ? AppColors.ink : AppColors.line),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppSpace.xs + 2),
        ],
      ],
    ),
  );
}

/// Inline notice (info or error) used by forms.
class FormNotice extends StatelessWidget {
  const FormNotice({
    super.key,
    required this.message,
    this.error = false,
    this.warning = false,
    this.icon,
  });

  final String message;
  final bool error;

  /// Amber tint for something that needs attention but is not an error.
  final bool warning;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpace.m),
      decoration: BoxDecoration(
        color: error
            ? AppColors.coral.withValues(alpha: 0.18)
            : (warning
                  ? AppColors.amber.withValues(alpha: 0.25)
                  : AppColors.limeTint),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: AppSpace.s),
          ],
          Expanded(
            child: Text(
              message,
              style: t.bodySmall!.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
