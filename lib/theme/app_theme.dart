import 'package:flutter/material.dart';

import '../models/correction_state.dart';
import '../models/device_status.dart';
import '../models/posture_state.dart';

/// Brand palette (Fineed-style).
///
/// Rule: [lime] is only ever a FILL with [ink] content on top. Never use it
/// as a text or icon color on a white/surface background.
abstract final class AppColors {
  static const lime = Color(0xFFD4F03C);
  static const limePressed = Color(0xFFBFD92E);
  static const limeTint = Color(0xFFF1FAC9);
  static const ink = Color(0xFF0D0D0D);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F6F7);
  static const line = Color(0xFFECEEF0);
  static const textSecondary = Color(0xFF7A808A);
  static const amber = Color(0xFFF5B93A);
  static const coral = Color(0xFFF2674F);
  static const onInk = Color(0xFFFFFFFF);

  /// Heatmap scale (0 = low, 1 = high): lime → amber → coral.
  static Color heat(double t) {
    final v = t.clamp(0.0, 1.0);
    return v < 0.5
        ? Color.lerp(lime, amber, v * 2)!
        : Color.lerp(amber, coral, (v - 0.5) * 2)!;
  }

  // ---------------------------------------------------------------- legacy
  // Aliases so the stage-1 screens keep compiling while they are rebuilt in
  // later stages. Mapped to text-safe colors. Do not use in new code; this
  // block is deleted once every screen is migrated.
  static const text = ink;
  static const textMuted = textSecondary;
  static const textFaint = Color(0xFFA3A8B0);
  static const border = line;
  static const surfaceAlt = surface;
  static const sidebar = background;
  static const cyan = ink;
  static const teal = ink;
  static const blue = ink;
  static const green = ink;
  static const orange = Color(0xFFB7791F); // amber, darkened for text
  static const red = Color(0xFFD14B34); // coral, darkened for text
  static const slate = textSecondary;
  static const violet = textSecondary;

  static Color posture(PostureState p) => switch (p) {
    PostureState.upright => ink,
    PostureState.unknown => textSecondary,
    PostureState.crossedLegs => orange,
    _ => orange,
  };

  static Color connection(DeviceConnection c) => switch (c) {
    DeviceConnection.offline => red,
    _ => ink,
  };

  static Color correction(CorrectionStatus s) => switch (s) {
    CorrectionStatus.withinLimit => ink,
    CorrectionStatus.pending => orange,
    CorrectionStatus.correcting => orange,
    CorrectionStatus.paused => textSecondary,
    CorrectionStatus.unavailable => textSecondary,
    CorrectionStatus.fault => red,
  };

  static Color loadIntensity(double t) => heat(t);
}

/// A fill color with the content color that is readable on it.
class StatusTone {
  const StatusTone(this.fill, this.onFill);
  final Color fill;
  final Color onFill;

  static const good = StatusTone(AppColors.lime, AppColors.ink);
  static const warning = StatusTone(AppColors.amber, AppColors.ink);
  static const alert = StatusTone(AppColors.coral, AppColors.ink);
  static const neutral = StatusTone(AppColors.surface, AppColors.ink);
  static const dark = StatusTone(AppColors.ink, AppColors.onInk);

  static StatusTone posture(PostureState p) => switch (p) {
    PostureState.upright => good,
    PostureState.unknown => neutral,
    PostureState.crossedLegs => warning,
    PostureState.leaningBackward || PostureState.leaningForward => alert,
    _ => warning,
  };

  static StatusTone connection(DeviceConnection c) => switch (c) {
    DeviceConnection.online => good,
    DeviceConnection.demo => neutral,
    DeviceConnection.offline => alert,
  };
}

/// 8-point spacing scale.
abstract final class AppSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 40;

  /// Horizontal screen margin.
  static const double screen = 20;
}

abstract final class AppRadius {
  static const double card = 24;
  static const double input = 24;
  static const double small = 16;
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
}

abstract final class AppShadows {
  /// Barely-there lift for cards on white. Use sparingly.
  static const soft = [
    BoxShadow(color: Color(0x0A0D0D0D), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

const String appFontFamily = 'PlusJakartaSans';

TextTheme _textTheme() {
  const ink = AppColors.ink;
  TextStyle h(double size, FontWeight w, double tracking) => TextStyle(
    fontFamily: appFontFamily,
    fontSize: size,
    fontWeight: w,
    letterSpacing: tracking,
    height: 1.2,
    color: ink,
  );
  TextStyle b(
    double size, {
    Color color = ink,
    FontWeight w = FontWeight.w500,
  }) => TextStyle(
    fontFamily: appFontFamily,
    fontSize: size,
    fontWeight: w,
    height: 1.45,
    color: color,
  );
  return TextTheme(
    displayLarge: h(48, FontWeight.w800, -1.4),
    displayMedium: h(40, FontWeight.w800, -1.2),
    displaySmall: h(32, FontWeight.w800, -0.8),
    headlineLarge: h(30, FontWeight.w800, -0.7),
    headlineMedium: h(28, FontWeight.w800, -0.6),
    headlineSmall: h(24, FontWeight.w800, -0.5),
    titleLarge: h(20, FontWeight.w700, -0.3),
    titleMedium: h(16, FontWeight.w700, -0.2),
    titleSmall: h(14, FontWeight.w700, -0.1),
    bodyLarge: b(16),
    bodyMedium: b(14),
    bodySmall: b(12, color: AppColors.textSecondary),
    labelLarge: b(14, w: FontWeight.w600),
    labelMedium: b(12, w: FontWeight.w600),
    labelSmall: b(11, w: FontWeight.w600, color: AppColors.textSecondary),
  );
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.ink,
    onPrimary: AppColors.onInk,
    secondary: AppColors.lime,
    onSecondary: AppColors.ink,
    tertiary: AppColors.amber,
    onTertiary: AppColors.ink,
    error: AppColors.coral,
    onError: AppColors.ink,
    surface: AppColors.background,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surface,
    surfaceContainerHighest: AppColors.surface,
    outline: AppColors.line,
    outlineVariant: AppColors.line,
  );
  final text = _textTheme();
  const pill = StadiumBorder();
  final buttonText = text.labelLarge!.copyWith(fontSize: 15);

  WidgetStateProperty<Color?> pressed(Color normal, Color down) =>
      WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.pressed) ? down : normal,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: appFontFamily,
    textTheme: text,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    dividerColor: AppColors.line,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    iconTheme: const IconThemeData(color: AppColors.ink, size: 24),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: text.titleMedium,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
    ),
    // Primary: black pill, white label.
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.disabled) ? AppColors.line : AppColors.ink,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? AppColors.textSecondary
              : AppColors.onInk,
        ),
        overlayColor: WidgetStatePropertyAll(
          AppColors.onInk.withValues(alpha: 0.08),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(64, 56)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpace.l),
        ),
        shape: const WidgetStatePropertyAll(pill),
        textStyle: WidgetStatePropertyAll(buttonText),
        elevation: const WidgetStatePropertyAll(0),
      ),
    ),
    // Secondary: lime pill, black label.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? AppColors.line
              : s.contains(WidgetState.pressed)
              ? AppColors.limePressed
              : AppColors.lime,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? AppColors.textSecondary
              : AppColors.ink,
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        minimumSize: const WidgetStatePropertyAll(Size(64, 56)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpace.l),
        ),
        shape: const WidgetStatePropertyAll(pill),
        textStyle: WidgetStatePropertyAll(buttonText),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(AppColors.ink),
        backgroundColor: pressed(Colors.transparent, AppColors.surface),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.line, width: 1.5),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpace.l - 4),
        ),
        shape: const WidgetStatePropertyAll(pill),
        textStyle: WidgetStatePropertyAll(buttonText),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(AppColors.ink),
        shape: const WidgetStatePropertyAll(pill),
        textStyle: WidgetStatePropertyAll(text.labelLarge),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(AppColors.ink),
        backgroundColor: pressed(Colors.transparent, AppColors.surface),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.l - 4,
        vertical: AppSpace.m + 2,
      ),
      hintStyle: text.bodyMedium!.copyWith(color: AppColors.textSecondary),
      labelStyle: text.bodyMedium!.copyWith(color: AppColors.textSecondary),
      prefixIconColor: AppColors.textSecondary,
      suffixIconColor: AppColors.textSecondary,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.input)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.input)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.input)),
        borderSide: BorderSide(color: AppColors.ink, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.input)),
        borderSide: BorderSide(color: AppColors.coral, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.lime,
      disabledColor: AppColors.line,
      checkmarkColor: AppColors.ink,
      labelStyle: text.labelLarge,
      secondaryLabelStyle: text.labelLarge,
      side: BorderSide.none,
      shape: pill,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      showCheckmark: false,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.onInk
              : AppColors.textSecondary,
        ),
        side: const WidgetStatePropertyAll(BorderSide.none),
        shape: const WidgetStatePropertyAll(pill),
        textStyle: WidgetStatePropertyAll(text.labelLarge),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.ink
            : AppColors.background,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? AppColors.lime : AppColors.line,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.lime,
      inactiveTrackColor: AppColors.line,
      thumbColor: AppColors.ink,
      overlayColor: Color(0x140D0D0D),
      trackHeight: 8,
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
      valueIndicatorColor: AppColors.ink,
      showValueIndicator: ShowValueIndicator.onDrag,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.ink,
      linearTrackColor: AppColors.line,
      circularTrackColor: AppColors.line,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.lime,
      indicatorShape: pill,
      elevation: 0,
      height: 72,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.textSecondary,
          size: 24,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelMedium!.copyWith(
          color: s.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.textSecondary,
        ),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      iconColor: AppColors.ink,
      titleTextStyle: text.titleSmall,
      subtitleTextStyle: text.bodySmall,
      minVerticalPadding: AppSpace.s + 4,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: text.bodyMedium!.copyWith(color: AppColors.onInk),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.small)),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: const BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      textStyle: text.labelMedium!.copyWith(color: AppColors.onInk),
    ),
  );
}
