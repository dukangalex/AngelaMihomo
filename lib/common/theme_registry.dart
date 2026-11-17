import 'deepspace_themes.dart';
import 'goldsaint_themes.dart';
import 'zodiac_themes.dart';

/// The three series under the 星辰大海 umbrella, in chooser order.
/// (The solar-system series was withdrawn by the user on 2026-11-17.)
enum ThemeSeries { zodiac, deepSpace, goldSaint }

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

  const AppThemeSelection({
    required this.id,
    required this.series,
    required this.skeleton,
    required this.variant,
    required this.motif,
    required this.constellation,
    required this.showGuardian,
    required this.sign,
  });

  bool get isDeepSpace => series == ThemeSeries.deepSpace;

  ZodiacThemeExtension toExtension() {
    return ZodiacThemeExtension(
      themeId: id,
      skeleton: skeleton,
      variant: variant,
      motif: motif,
      constellation: constellation,
      showGuardian: showGuardian,
      sign: sign,
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
  final gold = goldSaintThemeById(id);
  if (gold != null) {
    final mirror = resolveZodiacTheme(gold.zodiacId);
    return AppThemeSelection(
      id: gold.id,
      series: ThemeSeries.goldSaint,
      skeleton: mirror.skeleton,
      variant: gold.variant,
      motif: null,
      constellation: mirror.constellation,
      showGuardian: false,
      sign: mirror.sign,
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
/// constellation and golden-saint series, a four-point star for
/// deep-space events.
String themeGlyphFor(String? id) {
  final sel = resolveAppTheme(id);
  return switch (sel.series) {
    ThemeSeries.deepSpace => '✦',
    _ => sel.sign,
  };
}

/// The family name over all three series.
const starrySeaNameZh = '星辰大海';
const starrySeaNameEn = 'Starry Sea';
