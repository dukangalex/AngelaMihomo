import 'package:flutter/material.dart';

import 'zodiac_themes.dart';

/// The theme series under the 星辰大海 umbrella. Only the twelve
/// constellations remain (T298, user 2026-11-24): the deep-space and
/// solid-zodiac series are withdrawn, joining the golden-saint and
/// solar-system series withdrawn on 2026-11-17.
enum ThemeSeries { zodiac }

/// The single authoritative resolution of a stored theme selection
/// (T180). Every consumer (color scheme generation, the theme
/// extension, the backdrop, small glyph users) resolves through
/// here, so a selection can never split into two opinions about
/// which palette is active. Unknown or missing ids — including ids
/// of withdrawn series — fall back to the default constellation
/// theme.
class AppThemeSelection {
  final String id;
  final ThemeSeries series;
  final ZodiacSkeleton skeleton;
  final ZodiacVariant lightVariant;
  final ZodiacVariant darkVariant;
  final ZodiacConstellation constellation;
  final bool showGuardian;
  final String sign;

  const AppThemeSelection({
    required this.id,
    required this.series,
    required this.skeleton,
    required this.lightVariant,
    required this.darkVariant,
    required this.constellation,
    required this.showGuardian,
    required this.sign,
  });

  /// The variant for a resolved [brightness]: the family follows
  /// the app's theme mode (system / light / dark), one set of
  /// themes with a presentation per brightness.
  ZodiacVariant variantFor(Brightness brightness) =>
      brightness == Brightness.light ? lightVariant : darkVariant;

  ZodiacThemeExtension toExtension(Brightness brightness) {
    return ZodiacThemeExtension(
      themeId: id,
      skeleton: skeleton,
      variant: variantFor(brightness),
      constellation: constellation,
      showGuardian: showGuardian,
      sign: sign,
    );
  }
}

AppThemeSelection resolveAppTheme(String? id) {
  final zodiac = resolveZodiacTheme(id);
  return AppThemeSelection(
    id: zodiac.id,
    series: ThemeSeries.zodiac,
    skeleton: zodiac.skeleton,
    lightVariant: zodiac.light,
    darkVariant: zodiac.dark,
    constellation: zodiac.constellation,
    showGuardian: true,
    sign: zodiac.sign,
  );
}

/// The small decorative glyph for a theme: its constellation sign.
String themeGlyphFor(String? id) {
  return resolveAppTheme(id).sign;
}

/// The family name over all series.
const starrySeaNameZh = '星辰大海';
const starrySeaNameEn = 'Starry Sea';
