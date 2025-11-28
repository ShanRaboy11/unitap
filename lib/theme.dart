import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind; // for scroll behavior devices
import 'package:flutter/material.dart';
// WidgetState / WidgetStateProperty are re-exported by material.dart in recent versions

/// Utility to convert OKLCH color values to a Flutter [Color].
/// Based on Björn Ottosson's OKLab <-> sRGB conversion formulas.
Color oklch(double l, double c, double hDegrees) {
  final h = hDegrees * math.pi / 180.0;
  final a = c * math.cos(h);
  final b = c * math.sin(h);

  // OKLab to LMS
  final l_ = l + 0.3963377774 * a + 0.2158037573 * b;
  final m_ = l - 0.1055613458 * a - 0.0638541728 * b;
  final s_ = l - 0.0894841775 * a - 1.2914855480 * b;

  final l3 = l_ * l_ * l_;
  final m3 = m_ * m_ * m_;
  final s3 = s_ * s_ * s_;

  double channel(double x) {
    if (x <= 0.0031308) return 12.92 * x;
    return 1.055 * math.pow(x, 1 / 2.4) - 0.055;
  }

  double clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  final rLin = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3;
  final gLin = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3;
  final bLin = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3;

  final r = (clamp01(channel(rLin)) * 255).round();
  final g = (clamp01(channel(gLin)) * 255).round();
  final bVal = (clamp01(channel(bLin)) * 255).round();

  return Color.fromARGB(255, r, g, bVal);
}

Color hex(String hexCode) {
  final buffer = StringBuffer();
  if (hexCode.length == 6 || hexCode.length == 7) buffer.write('ff');
  buffer.write(hexCode.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// Custom theme extension containing the mapped CSS design tokens.
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color inputBackground;
  final Color switchBackground;
  final Color ring;
  final Color chart1;
  final Color chart2;
  final Color chart3;
  final Color chart4;
  final Color chart5;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final Color sidebar;
  final Color sidebarForeground;
  final Color sidebarPrimary;
  final Color sidebarPrimaryForeground;
  final Color sidebarAccent;
  final Color sidebarAccentForeground;
  final Color sidebarBorder;
  final Color sidebarRing;

  const AppPalette({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.inputBackground,
    required this.switchBackground,
    required this.ring,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.sidebar,
    required this.sidebarForeground,
    required this.sidebarPrimary,
    required this.sidebarPrimaryForeground,
    required this.sidebarAccent,
    required this.sidebarAccentForeground,
    required this.sidebarBorder,
    required this.sidebarRing,
  });

  @override
  AppPalette copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? popover,
    Color? popoverForeground,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? border,
    Color? input,
    Color? inputBackground,
    Color? switchBackground,
    Color? ring,
    Color? chart1,
    Color? chart2,
    Color? chart3,
    Color? chart4,
    Color? chart5,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    Color? sidebar,
    Color? sidebarForeground,
    Color? sidebarPrimary,
    Color? sidebarPrimaryForeground,
    Color? sidebarAccent,
    Color? sidebarAccentForeground,
    Color? sidebarBorder,
    Color? sidebarRing,
  }) => AppPalette(
    background: background ?? this.background,
    foreground: foreground ?? this.foreground,
    card: card ?? this.card,
    cardForeground: cardForeground ?? this.cardForeground,
    popover: popover ?? this.popover,
    popoverForeground: popoverForeground ?? this.popoverForeground,
    primary: primary ?? this.primary,
    primaryForeground: primaryForeground ?? this.primaryForeground,
    secondary: secondary ?? this.secondary,
    secondaryForeground: secondaryForeground ?? this.secondaryForeground,
    muted: muted ?? this.muted,
    mutedForeground: mutedForeground ?? this.mutedForeground,
    accent: accent ?? this.accent,
    accentForeground: accentForeground ?? this.accentForeground,
    destructive: destructive ?? this.destructive,
    destructiveForeground: destructiveForeground ?? this.destructiveForeground,
    border: border ?? this.border,
    input: input ?? this.input,
    inputBackground: inputBackground ?? this.inputBackground,
    switchBackground: switchBackground ?? this.switchBackground,
    ring: ring ?? this.ring,
    chart1: chart1 ?? this.chart1,
    chart2: chart2 ?? this.chart2,
    chart3: chart3 ?? this.chart3,
    chart4: chart4 ?? this.chart4,
    chart5: chart5 ?? this.chart5,
    radiusSm: radiusSm ?? this.radiusSm,
    radiusMd: radiusMd ?? this.radiusMd,
    radiusLg: radiusLg ?? this.radiusLg,
    radiusXl: radiusXl ?? this.radiusXl,
    sidebar: sidebar ?? this.sidebar,
    sidebarForeground: sidebarForeground ?? this.sidebarForeground,
    sidebarPrimary: sidebarPrimary ?? this.sidebarPrimary,
    sidebarPrimaryForeground:
        sidebarPrimaryForeground ?? this.sidebarPrimaryForeground,
    sidebarAccent: sidebarAccent ?? this.sidebarAccent,
    sidebarAccentForeground:
        sidebarAccentForeground ?? this.sidebarAccentForeground,
    sidebarBorder: sidebarBorder ?? this.sidebarBorder,
    sidebarRing: sidebarRing ?? this.sidebarRing,
  );

  @override
  ThemeExtension<AppPalette> lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;
    double lerpDouble(double a, double b) => a + (b - a) * t;
    return AppPalette(
      background: lerpColor(background, other.background),
      foreground: lerpColor(foreground, other.foreground),
      card: lerpColor(card, other.card),
      cardForeground: lerpColor(cardForeground, other.cardForeground),
      popover: lerpColor(popover, other.popover),
      popoverForeground: lerpColor(popoverForeground, other.popoverForeground),
      primary: lerpColor(primary, other.primary),
      primaryForeground: lerpColor(primaryForeground, other.primaryForeground),
      secondary: lerpColor(secondary, other.secondary),
      secondaryForeground: lerpColor(
        secondaryForeground,
        other.secondaryForeground,
      ),
      muted: lerpColor(muted, other.muted),
      mutedForeground: lerpColor(mutedForeground, other.mutedForeground),
      accent: lerpColor(accent, other.accent),
      accentForeground: lerpColor(accentForeground, other.accentForeground),
      destructive: lerpColor(destructive, other.destructive),
      destructiveForeground: lerpColor(
        destructiveForeground,
        other.destructiveForeground,
      ),
      border: lerpColor(border, other.border),
      input: lerpColor(input, other.input),
      inputBackground: lerpColor(inputBackground, other.inputBackground),
      switchBackground: lerpColor(switchBackground, other.switchBackground),
      ring: lerpColor(ring, other.ring),
      chart1: lerpColor(chart1, other.chart1),
      chart2: lerpColor(chart2, other.chart2),
      chart3: lerpColor(chart3, other.chart3),
      chart4: lerpColor(chart4, other.chart4),
      chart5: lerpColor(chart5, other.chart5),
      radiusSm: lerpDouble(radiusSm, other.radiusSm),
      radiusMd: lerpDouble(radiusMd, other.radiusMd),
      radiusLg: lerpDouble(radiusLg, other.radiusLg),
      radiusXl: lerpDouble(radiusXl, other.radiusXl),
      sidebar: lerpColor(sidebar, other.sidebar),
      sidebarForeground: lerpColor(sidebarForeground, other.sidebarForeground),
      sidebarPrimary: lerpColor(sidebarPrimary, other.sidebarPrimary),
      sidebarPrimaryForeground: lerpColor(
        sidebarPrimaryForeground,
        other.sidebarPrimaryForeground,
      ),
      sidebarAccent: lerpColor(sidebarAccent, other.sidebarAccent),
      sidebarAccentForeground: lerpColor(
        sidebarAccentForeground,
        other.sidebarAccentForeground,
      ),
      sidebarBorder: lerpColor(sidebarBorder, other.sidebarBorder),
      sidebarRing: lerpColor(sidebarRing, other.sidebarRing),
    );
  }

  static AppPalette light() {
    final radius = 10.0; // base 0.625rem ≈ 10px
    return AppPalette(
      background: hex('#ffffff'),
      foreground: oklch(0.145, 0, 0),
      card: hex('#ffffff'),
      cardForeground: oklch(0.145, 0, 0),
      popover: oklch(1, 0, 0),
      popoverForeground: oklch(0.145, 0, 0),
      primary: hex('#030213'),
      primaryForeground: oklch(1, 0, 0),
      secondary: oklch(0.95, 0.0058, 264.53),
      secondaryForeground: hex('#030213'),
      muted: hex('#ececf0'),
      mutedForeground: hex('#717182'),
      accent: hex('#e9ebef'),
      accentForeground: hex('#030213'),
      destructive: hex('#d4183d'),
      destructiveForeground: hex('#ffffff'),
      border: const Color.fromRGBO(0, 0, 0, 0.1),
      input: Colors.transparent,
      inputBackground: hex('#f3f3f5'),
      switchBackground: hex('#cbced4'),
      ring: oklch(0.708, 0, 0),
      chart1: oklch(0.646, 0.222, 41.116),
      chart2: oklch(0.6, 0.118, 184.704),
      chart3: oklch(0.398, 0.07, 227.392),
      chart4: oklch(0.828, 0.189, 84.429),
      chart5: oklch(0.769, 0.188, 70.08),
      radiusSm: radius - 4,
      radiusMd: radius - 2,
      radiusLg: radius,
      radiusXl: radius + 4,
      sidebar: oklch(0.985, 0, 0),
      sidebarForeground: oklch(0.145, 0, 0),
      sidebarPrimary: hex('#030213'),
      sidebarPrimaryForeground: oklch(0.985, 0, 0),
      sidebarAccent: oklch(0.97, 0, 0),
      sidebarAccentForeground: oklch(0.205, 0, 0),
      sidebarBorder: oklch(0.922, 0, 0),
      sidebarRing: oklch(0.708, 0, 0),
    );
  }

  static AppPalette dark() {
    final radius = 10.0;
    return AppPalette(
      background: oklch(0.145, 0, 0),
      foreground: oklch(0.985, 0, 0),
      card: oklch(0.145, 0, 0),
      cardForeground: oklch(0.985, 0, 0),
      popover: oklch(0.145, 0, 0),
      popoverForeground: oklch(0.985, 0, 0),
      primary: oklch(0.985, 0, 0),
      primaryForeground: oklch(0.205, 0, 0),
      secondary: oklch(0.269, 0, 0),
      secondaryForeground: oklch(0.985, 0, 0),
      muted: oklch(0.269, 0, 0),
      mutedForeground: oklch(0.708, 0, 0),
      accent: oklch(0.269, 0, 0),
      accentForeground: oklch(0.985, 0, 0),
      destructive: oklch(0.396, 0.141, 25.723),
      destructiveForeground: oklch(0.637, 0.237, 25.331),
      border: oklch(0.269, 0, 0),
      input: oklch(0.269, 0, 0),
      inputBackground: oklch(0.269, 0, 0),
      switchBackground: oklch(0.439, 0, 0), // approximate
      ring: oklch(0.439, 0, 0),
      chart1: oklch(0.488, 0.243, 264.376),
      chart2: oklch(0.696, 0.17, 162.48),
      chart3: oklch(0.769, 0.188, 70.08),
      chart4: oklch(0.627, 0.265, 303.9),
      chart5: oklch(0.645, 0.246, 16.439),
      radiusSm: radius - 4,
      radiusMd: radius - 2,
      radiusLg: radius,
      radiusXl: radius + 4,
      sidebar: oklch(0.205, 0, 0),
      sidebarForeground: oklch(0.985, 0, 0),
      sidebarPrimary: oklch(0.488, 0.243, 264.376),
      sidebarPrimaryForeground: oklch(0.985, 0, 0),
      sidebarAccent: oklch(0.269, 0, 0),
      sidebarAccentForeground: oklch(0.985, 0, 0),
      sidebarBorder: oklch(0.269, 0, 0),
      sidebarRing: oklch(0.439, 0, 0),
    );
  }
}

/// Build the light [ThemeData] using the palette.
ThemeData buildLightTheme() {
  final p = AppPalette.light();
  final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
  final scheme = base.colorScheme.copyWith(
    primary: p.primary,
    onPrimary: p.primaryForeground,
    secondary: p.secondary,
    onSecondary: p.secondaryForeground,
    error: p.destructive,
    onError: p.destructiveForeground,
    surface: p.card,
    onSurface: p.cardForeground,
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    extensions: [p],
    textTheme: _buildTextTheme(base.textTheme, foreground: p.foreground),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(p.radiusLg),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(p.radiusLg),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(p.radiusLg),
        borderSide: BorderSide(color: p.primary, width: 2),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => p.chart2.withValues(
          alpha: states.contains(WidgetState.hovered) ? 0.9 : 0.7,
        ),
      ),
      trackColor: WidgetStateProperty.all(Colors.transparent),
      radius: Radius.circular(p.radiusLg),
      thickness: WidgetStateProperty.all(8),
    ),
  );
}

/// Build the dark [ThemeData] using the palette.
ThemeData buildDarkTheme() {
  final p = AppPalette.dark();
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  final scheme = base.colorScheme.copyWith(
    primary: p.primary,
    onPrimary: p.primaryForeground,
    secondary: p.secondary,
    onSecondary: p.secondaryForeground,
    error: p.destructive,
    onError: p.destructiveForeground,
    surface: p.card,
    onSurface: p.cardForeground,
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    extensions: [p],
    textTheme: _buildTextTheme(base.textTheme, foreground: p.foreground),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(p.radiusLg),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(p.radiusLg),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(p.radiusLg),
        borderSide: BorderSide(color: p.primary, width: 2),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => p.chart2.withValues(
          alpha: states.contains(WidgetState.hovered) ? 0.9 : 0.8,
        ),
      ),
      trackColor: WidgetStateProperty.all(Colors.transparent),
      radius: Radius.circular(p.radiusLg),
      thickness: WidgetStateProperty.all(8),
    ),
  );
}

TextTheme _buildTextTheme(TextTheme base, {required Color foreground}) {
  // Mapping approximate CSS token sizes.
  return base.copyWith(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w500,
      color: foreground,
    ), // h1
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w500,
      color: foreground,
    ), // h2
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      color: foreground,
    ), // h3
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: foreground,
    ), // h4
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: foreground,
    ), // p
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: foreground,
    ), // label/button
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: foreground,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: foreground.withValues(alpha: 0.8),
    ),
  );
}

/// Custom scroll behavior removing glow and enabling mouse wheel + touch.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // Remove default glow
  }
}
