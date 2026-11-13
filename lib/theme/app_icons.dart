import 'package:flutter/widgets.dart';

/// The app's only icon family: Phosphor, Light weight (thin outline), MIT.
/// Font file: assets/fonts/Phosphor-Light.ttf (license: PHOSPHOR-LICENSE.txt).
///
/// Bundled directly instead of via `phosphor_flutter`, whose current release
/// does not compile on this Flutter (it extends the now-final `IconData`).
/// Add icons here instead of using `Icons.*` or another set in widgets.
abstract final class AppIcons {
  static const String _family = 'PhosphorLight';

  static const IconData _house = IconData(0xe2c2, fontFamily: _family);

  // Navigation
  static const IconData home = _house;
  static const IconData history = IconData(0xe1a0, fontFamily: _family);
  static const IconData notifications = IconData(0xe0ce, fontFamily: _family);
  static const IconData settings = IconData(0xe272, fontFamily: _family);
  static const IconData menu = IconData(0xe2f0, fontFamily: _family);
  static const IconData back = IconData(0xe058, fontFamily: _family);
  static const IconData next = IconData(0xe06c, fontFamily: _family);
  static const IconData chevron = IconData(0xe13a, fontFamily: _family);
  static const IconData close = IconData(0xe4f6, fontFamily: _family);

  // Device & data
  static const IconData chair = IconData(0xea46, fontFamily: _family);
  static const IconData posture = IconData(0xe72e, fontFamily: _family);
  static const IconData online = IconData(0xe4ea, fontFamily: _family);
  static const IconData offline = IconData(0xe4f2, fontFamily: _family);
  static const IconData demo = IconData(0xe79e, fontFamily: _family);
  static const IconData sensor = IconData(0xe610, fontFamily: _family);
  static const IconData heartbeat = IconData(0xe2ac, fontFamily: _family);
  static const IconData pressure = IconData(0xe464, fontFamily: _family);
  static const IconData gauge = IconData(0xe628, fontFamily: _family);
  static const IconData timer = IconData(0xe492, fontFamily: _family);
  static const IconData chart = IconData(0xe154, fontFamily: _family);
  static const IconData sliders = IconData(0xe432, fontFamily: _family);
  static const IconData reload = IconData(0xe094, fontFamily: _family);

  // Account & forms
  static const IconData user = IconData(0xe4c2, fontFamily: _family);
  static const IconData signOut = IconData(0xe42a, fontFamily: _family);
  static const IconData weight = IconData(0xe750, fontFamily: _family);
  static const IconData email = IconData(0xe214, fontFamily: _family);
  static const IconData lock = IconData(0xe2fa, fontFamily: _family);
  static const IconData eye = IconData(0xe220, fontFamily: _family);
  static const IconData eyeOff = IconData(0xe224, fontFamily: _family);
  static const IconData power = IconData(0xe3da, fontFamily: _family);
  static const IconData check = IconData(0xe182, fontFamily: _family);

  // Actions & states
  static const IconData pause = IconData(0xe39e, fontFamily: _family);
  static const IconData play = IconData(0xe3d0, fontFamily: _family);
  static const IconData info = IconData(0xe2ce, fontFamily: _family);
  static const IconData success = IconData(0xe184, fontFamily: _family);
  static const IconData warning = IconData(0xe4e0, fontFamily: _family);
  static const IconData error = IconData(0xe4e2, fontFamily: _family);
  static const IconData up = IconData(0xe08e, fontFamily: _family);
  static const IconData down = IconData(0xe03e, fontFamily: _family);
  static const IconData left = back;
  static const IconData right = next;
}
