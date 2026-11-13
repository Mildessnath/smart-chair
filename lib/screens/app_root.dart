import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_session.dart';
import 'app_shell.dart';
import 'auth/activation_screen.dart';
import 'auth/login_screen.dart';
import 'auth/splash_screen.dart';
import 'auth/weight_screen.dart';

/// Splash → Masuk → Berat badan → Aktifkan kursi → app.
class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    this.splashDuration = const Duration(milliseconds: 1400),
  });

  final Duration splashDuration;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  Timer? _timer;
  late bool _splash = widget.splashDuration > Duration.zero;

  @override
  void initState() {
    super.initState();
    if (_splash) {
      _timer = Timer(widget.splashDuration, () {
        if (mounted) setState(() => _splash = false);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSession>();
    final String key;
    final Widget screen;
    if (_splash) {
      (key, screen) = ('splash', const SplashScreen());
    } else if (!session.isLoggedIn) {
      (key, screen) = ('login', const LoginScreen());
    } else if (session.bodyWeightKg == null) {
      (key, screen) = ('weight', const WeightScreen());
    } else if (!session.chairPromptSeen) {
      (key, screen) = ('activation', const ActivationScreen());
    } else {
      (key, screen) = ('app', const AppShell());
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey(key), child: screen),
    );
  }
}
