import 'deepspace_themes.dart';
import 'zodiac_themes.dart';

/// The single authoritative resolution of a stored theme selection
/// (T180). The 星辰大海 umbrella holds two series — the
/// twelve-constellation series and the Human Deep Space Exploration
/// series — and every consumer (color scheme generation, the theme
/// extension, the backdrop, small glyph users) resolves through
/// here, so a selection can never split into two opinions about
/// which palette is active. Unknown or missing ids fall back to the
/// default constellation theme.
class AppThemeSelection {
  final String id;
  final ZodiacSkeleton skeleton;
  final ZodiacVariant variant;
  final bool isDeepSpace;
  final DeepSpaceMotif? motif;

  const AppThemeSelection({
    required this.id,
    required this.skeleton,
    required this.variant,
    required this.isDeepSpace,
    required this.motif,
  });

  ZodiacThemeExtension toExtension({bool solidBackground = false}) {
    return ZodiacThemeExtension(
      themeId: id,
      skeleton: skeleton,
      variant: variant,
      solidBackground: solidBackground,
      isDeepSpace: isDeepSpace,
      motif: motif,
    );
  }
}

AppThemeSelection resolveAppTheme(String? id) {
  final deepSpace = deepSpaceThemeById(id);
  if (deepSpace != null) {
    return AppThemeSelection(
      id: deepSpace.id,
      skeleton: deepSpace.skeleton,
      variant: deepSpace.variant,
      isDeepSpace: true,
      motif: deepSpace.motif,
    );
  }
  final zodiac = resolveZodiacTheme(id);
  return AppThemeSelection(
    id: zodiac.id,
    skeleton: zodiac.skeleton,
    variant: zodiac.variant,
    isDeepSpace: false,
    motif: null,
  );
}

/// The small decorative glyph for a theme: the sign for
/// constellation themes, a four-point star for deep-space events.
String themeGlyphFor(String? id) {
  if (isDeepSpaceThemeId(id)) return '✦';
  return resolveZodiacTheme(id).sign;
}
