import 'package:material_ui/material_ui.dart';

/// The 羲和星轨 (Xihe Star-Rail) design tokens, T334 batch 1.
///
/// Source of truth: files/ui-redesign/DESIGN-LANGUAGE.md in the goal
/// workspace (the frozen design language for the UI redesign that
/// sheds the upstream FlClash/Bettbox layout language). This file is
/// the skeleton layer of the theme system: one shared set of values
/// for every constellation theme, registered next to the zodiac
/// extension in the app theme. The twelve constellation themes keep
/// their own per-theme variant data (zodiac_themes_data.dart, frozen)
/// — their guardians and accent colors ride on top of this skeleton;
/// nothing here overrides a variant's own colors at paint time.
///
/// Batch 1 wires: the token constants themselves, the type scale
/// (applied to the app TextTheme in application.dart), the card
/// radius (aligned with commonCardRadius), and the skeleton palette
/// as a ThemeExtension so later batches (orbit home, star-chart
/// theme picker, trajectory timeline) read one canonical source.
abstract final class StarRailColors {
  // Dark skeleton (the design's main state).
  static const deepVoid = Color(0xFF171130);
  static const surfacePurple = Color(0xFF221A45);
  static const surfaceContainer = Color(0xFF211B3A);
  static const starlightWhite = Color(0xFFFFFFFF);
  static const primary = Color(0xFF8B7CFF);
  static const secondary = Color(0xFF5EEAD4);
  static const textPrimary = Color(0xFFF4F2FF);
  static const textSecondary = Color(0xFFA79FD1);
  static const warning = Color(0xFFFFB03A);
  static const error = Color(0xFFFF8A70);
  static const success = Color(0xFF4ADE80);

  // Light skeleton.
  static const lightPrimaryBase = Color(0xFF96C3F5);
  static const lightBackground = Color(0xFFEAF3FE);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightLine = Color(0xFF3B2E7A);
  static const lightTextPrimary = Color(0xFF221C4A);
  static const lightTextSecondary = Color(0xFF6B639F);
}

/// Corner radii. The card radius is the family token T328 already
/// established (commonCardRadius in widgets/card.dart, 24); the test
/// suite pins the two equal so the design table and the shipped
/// cards can never drift apart.
abstract final class StarRailRadius {
  static const card = 24.0;
  static const button = 24.0;
  static const sheetRow = 24.0;

  /// Fully rounded (delay pills, status pills, the guardian plate).
  static const pill = 999.0;
}

/// Spacing scale (DESIGN-LANGUAGE.md token table).
abstract final class StarRailSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const pageMargin = 20.0;
  static const gutter = 16.0;
}

/// The type scale. Styles carry size/weight/line-height only — color
/// and family come from the ambient theme so every constellation
/// keeps its own ink. [readout] is the live-numbers style: tabular
/// figures so speeds and traffic counts never jitter as digits
/// change width (the family's standing equal-width rule, T313).
abstract final class StarRailType {
  static const headlineXl = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
  );
  static const headlineLg = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
  );
  static const headlineMd = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );
  static const bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );
  static const bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );
  static const labelSm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6, // 0.05em at 12px
  );
  static const readout = TextStyle(
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Applies the token type scale onto [base], touching only the six
/// slots the design table defines; every other slot keeps the base
/// theme's values (and the T177 small-text bumps applied by the
/// caller stay in force for the slots the table does not cover).
TextTheme applyStarRailTypeScale(TextTheme base) {
  return base.copyWith(
    headlineLarge: base.headlineLarge?.merge(StarRailType.headlineXl) ??
        StarRailType.headlineXl,
    headlineSmall: base.headlineSmall?.merge(StarRailType.headlineLg) ??
        StarRailType.headlineLg,
    titleLarge: base.titleLarge?.merge(StarRailType.headlineMd) ??
        StarRailType.headlineMd,
    bodyLarge: base.bodyLarge?.merge(StarRailType.bodyLg) ??
        StarRailType.bodyLg,
    bodyMedium: base.bodyMedium?.merge(StarRailType.bodyMd) ??
        StarRailType.bodyMd,
    labelSmall: base.labelSmall?.merge(StarRailType.labelSm) ??
        StarRailType.labelSm,
  );
}

/// The skeleton palette as a theme extension, one instance per
/// brightness, so widgets in later batches read the design tokens
/// from the theme instead of hardcoding hex values.
class StarRailTokens extends ThemeExtension<StarRailTokens> {
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceContainer;
  final Color glowLine;
  final Color primary;
  final Color secondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color warning;
  final Color error;
  final Color success;

  const StarRailTokens({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceContainer,
    required this.glowLine,
    required this.primary,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.warning,
    required this.error,
    required this.success,
  });

  static const dark = StarRailTokens(
    brightness: Brightness.dark,
    background: StarRailColors.deepVoid,
    surface: StarRailColors.surfacePurple,
    surfaceContainer: StarRailColors.surfaceContainer,
    glowLine: StarRailColors.starlightWhite,
    primary: StarRailColors.primary,
    secondary: StarRailColors.secondary,
    textPrimary: StarRailColors.textPrimary,
    textSecondary: StarRailColors.textSecondary,
    warning: StarRailColors.warning,
    error: StarRailColors.error,
    success: StarRailColors.success,
  );

  static const light = StarRailTokens(
    brightness: Brightness.light,
    background: StarRailColors.lightBackground,
    surface: StarRailColors.lightSurface,
    // The light table names no second container tone; the base blue
    // at low strength is the container step under the white surface.
    surfaceContainer: StarRailColors.lightBackground,
    glowLine: StarRailColors.lightLine,
    primary: StarRailColors.lightPrimaryBase,
    secondary: StarRailColors.lightLine,
    textPrimary: StarRailColors.lightTextPrimary,
    textSecondary: StarRailColors.lightTextSecondary,
    warning: StarRailColors.warning,
    error: StarRailColors.error,
    success: StarRailColors.success,
  );

  static StarRailTokens forBrightness(Brightness brightness) =>
      brightness == Brightness.light ? light : dark;

  @override
  StarRailTokens copyWith({
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceContainer,
    Color? glowLine,
    Color? primary,
    Color? secondary,
    Color? textPrimary,
    Color? textSecondary,
    Color? warning,
    Color? error,
    Color? success,
  }) {
    return StarRailTokens(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      glowLine: glowLine ?? this.glowLine,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }

  @override
  StarRailTokens lerp(StarRailTokens? other, double t) {
    if (other == null || t >= 1) return other ?? this;
    return t < 0.5 ? this : other;
  }
}

extension StarRailContext on BuildContext {
  StarRailTokens? get starRail => Theme.of(this).extension<StarRailTokens>();
}
