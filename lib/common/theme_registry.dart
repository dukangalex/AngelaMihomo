import 'deepspace_themes.dart';
import 'solid_themes.dart';
import 'zodiac_themes.dart';

/// The three series under the 星辰大海 umbrella, in chooser order.
/// (The golden-saint and solar-system series were withdrawn by the
/// user on 2026-11-17.)
enum ThemeSeries { zodiac, deepSpace, solid }

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
  final ZodiacVariant variant;
  final DeepSpaceMotif? motif;
  final ZodiacConstellation constellation;
  final bool showGuardian;
  final String sign;

  /// The full-canvas artwork of the solid series, painted by the
  /// backdrop as a full-bleed cover layer; null for the other series.
  final String? solidAssetPath;

  const AppThemeSelection({
    required this.id,
    required this.series,
    required this.skeleton,
    required this.variant,
    required this.motif,
    required this.constellation,
    required this.showGuardian,
    required this.sign,
    this.solidAssetPath,
  });

  bool get isDeepSpace => series == ThemeSeries.deepSpace;

  bool get isSolid => series == ThemeSeries.solid;

  ZodiacThemeExtension toExtension() {
    return ZodiacThemeExtension(
      themeId: id,
      skeleton: skeleton,
      variant: variant,
      motif: motif,
      constellation: constellation,
      showGuardian: showGuardian,
      sign: sign,
      solidAssetPath: solidAssetPath,
    );
  }
}

AppThemeSelection resolveAppTheme(String? id) {
  final deepSpace = deepSpaceThemeById(id);
  if (deepSpace != null) {
    return AppThemeSelection(
      id: deepSpace.id,
      series: ThemeSeries.deepSpace,
      skeleton: deepSpace.skeleton,
      variant: deepSpace.variant,
      motif: deepSpace.motif,
      constellation: ZodiacConstellation.empty,
      showGuardian: false,
      sign: '',
    );
  }
  final solid = solidThemeById(id);
  if (solid != null) {
    return AppThemeSelection(
      id: solid.id,
      series: ThemeSeries.solid,
      skeleton: solid.skeleton,
      variant: solid.variant,
      motif: null,
      constellation: ZodiacConstellation.empty,
      showGuardian: false,
      // The animal's Chinese name doubles as the theme's small
      // glyph (themeGlyphFor). It feeds no name plate: the solid
      // series carries none, the guardian plate is gated by
      // showGuardian and the guardian map, and the backdrop's
      // solid branch never paints the constellation watermark.
      sign: solid.nameZh,
      solidAssetPath: solid.assetPath,
    );
  }
  final zodiac = resolveZodiacTheme(id);
  return AppThemeSelection(
    id: zodiac.id,
    series: ThemeSeries.zodiac,
    skeleton: zodiac.skeleton,
    variant: zodiac.variant,
    motif: null,
    constellation: zodiac.constellation,
    showGuardian: true,
    sign: zodiac.sign,
  );
}

/// The small decorative glyph for a theme: the sign for the
/// constellation series, a four-point star for deep-space events,
/// the animal's Chinese name for the solid series.
String themeGlyphFor(String? id) {
  final sel = resolveAppTheme(id);
  return switch (sel.series) {
    ThemeSeries.deepSpace => '✦',
    ThemeSeries.solid => sel.sign,
    _ => sel.sign,
  };
}

/// The family name over all series.
const starrySeaNameZh = '星辰大海';
const starrySeaNameEn = 'Starry Sea';
