import 'package:flutter/foundation.dart';

/// Demo sign-in state. There is NO account backend: any plausible e-mail and
/// password pass. Replace [login] with real authentication later.
class UserSession extends ChangeNotifier {
  bool _loggedIn = false;
  String? _email;
  double? _weightKg;
  bool _chairPromptSeen = false;

  bool get isLoggedIn => _loggedIn;
  String? get email => _email;
  double? get bodyWeightKg => _weightKg;

  /// The "activate your chair" step after onboarding was shown (activated or
  /// skipped).
  bool get chairPromptSeen => _chairPromptSeen;

  static const int minPasswordLength = 4;

  /// "Alex" from "alex.k@mail.com".
  String get displayName {
    final local = (_email ?? '').split('@').first;
    final word = local.split(RegExp(r'[._\-+]')).first;
    if (word.isEmpty) return 'Pengguna';
    return word[0].toUpperCase() + word.substring(1);
  }

  String get initials => displayName[0].toUpperCase();

  /// Validation message for [email], or null when acceptable.
  static String? validateEmail(String email) {
    final e = email.trim();
    if (e.isEmpty) return 'Email wajib diisi.';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
    return ok ? null : 'Format email tidak valid.';
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Kata sandi wajib diisi.';
    if (password.length < minPasswordLength) {
      return 'Kata sandi minimal $minPasswordLength karakter.';
    }
    return null;
  }

  /// Returns an error message, or null on success.
  String? login({required String email, required String password}) {
    final error = validateEmail(email) ?? validatePassword(password);
    if (error != null) return error;
    _email = email.trim();
    _loggedIn = true;
    notifyListeners();
    return null;
  }

  void setBodyWeight(double kg) {
    _weightKg = kg;
    notifyListeners();
  }

  void completeChairPrompt() {
    if (_chairPromptSeen) return;
    _chairPromptSeen = true;
    notifyListeners();
  }

  void logout() {
    _loggedIn = false;
    _email = null;
    _weightKg = null;
    _chairPromptSeen = false;
    notifyListeners();
  }
}
