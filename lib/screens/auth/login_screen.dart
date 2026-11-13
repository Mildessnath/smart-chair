import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_session.dart';
import '../../theme/app_icons.dart';
import '../../widgets/ui/buttons.dart';
import '../../theme/app_theme.dart';
import 'auth_widgets.dart';

/// Demo sign-in: validates the form but has no account backend.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final error = context.read<UserSession>().login(
      email: _email.text,
      password: _password.text,
    );
    if (error != null) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      step: 1,
      title: 'Selamat datang',
      subtitle: 'Masuk untuk memantau kursi dan postur dudukmu.',
      footer: PrimaryPillButton(
        key: const Key('loginButton'),
        label: 'Masuk',
        expand: true,
        onPressed: _submit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('emailField'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => setState(() => _error = null),
            decoration: const InputDecoration(
              hintText: 'Email',
              prefixIcon: Icon(AppIcons.email),
            ),
          ),
          const SizedBox(height: AppSpace.m),
          TextField(
            key: const Key('passwordField'),
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              hintText: 'Kata sandi',
              prefixIcon: const Icon(AppIcons.lock),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Tampilkan sandi' : 'Sembunyikan sandi',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? AppIcons.eye : AppIcons.eyeOff),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpace.m),
            FormNotice(
              key: const Key('loginError'),
              message: _error!,
              error: true,
              icon: AppIcons.error,
            ),
          ],
          const SizedBox(height: AppSpace.l),
          const FormNotice(
            icon: AppIcons.info,
            message:
                'Mode demo: belum ada server akun. Isi email apa saja '
                '(mis. nama@contoh.com) dan kata sandi minimal 4 karakter.',
          ),
        ],
      ),
    );
  }
}
