import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/home/chair_illustration.dart';

/// Full-lime splash.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.lime,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ChairIllustration(size: 120),
            const SizedBox(height: AppSpace.l),
            Text('Smart Chair', style: t.displaySmall),
            const SizedBox(height: AppSpace.s),
            Text('Duduk sehat, setiap hari', style: t.bodyMedium),
          ],
        ),
      ),
    );
  }
}
