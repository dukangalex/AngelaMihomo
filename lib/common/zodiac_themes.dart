import 'package:material_ui/material_ui.dart';

part 'zodiac_themes_data.dart';

/// The twelve-constellation theme family (DESIGN-十二星座主题家族.md).
///
/// One token system (21 tokens, doc section 2) shared by all twelve
/// themes; each theme ships a light and a dark variant that follow the
/// system brightness only. Sagittarius is the default and the fallback
/// for any missing or unknown selection.
const zodiacDefaultThemeId = 'sagittarius';

enum ZodiacSkeleton { immersive, layered, eastern, vibrant, paper, console }

enum ZodiacGlowPos { topRight, centerLeft }

class ZodiacGlow {
  final Color color;
  final ZodiacGlowPos pos;

  const ZodiacGlow(this.color, this.pos);
}

/// A paint surface in the token tables: a solid color, a linear gradient,
/// nothing ([none]), or the immersive atmosphere (the background gradient
/// plus the variant's radial glow spots).
class ZodiacPaint {
  final Color? solidColor;
  final List<Color>? stops;
  final bool isAtmospherePaint;

  const ZodiacPaint._(this.isAtmospherePaint)
    : solidColor = null,
      stops = null;

  const ZodiacPaint.solid(Color color)
    : solidColor = color,
      stops = null,
      isAtmospherePaint = false;

  const ZodiacPaint.gradient(List<Color> colors)
    : solidColor = null,
      stops = colors,
      isAtmospherePaint = false;

  static const none = ZodiacPaint._(false);

  /// Immersive variants only: paint the background gradient and glows.
  static const atmosphere = ZodiacPaint._(true);

  bool get isNone => solidColor == null && stops == null && !isAtmospherePaint;

  bool get isAtmosphere => isAtmospherePaint;

  bool get isGradient => stops != null;

  Color get firstColor => stops?.first ?? solidColor!;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: stops!,
  );

  LinearGradient get selectedGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: stops!,
  );
}

class ZodiacVariant {
  final ZodiacPaint background;
  final Color surface;
  final Color surfaceVariant;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
  final Color success;
  final Color warning;
  final Color error;
  final Color navBar;
  final ZodiacPaint selected;
  final ZodiacPaint hero;
  final Color? glow;
  final List<ZodiacGlow> glows;

  const ZodiacVariant({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.success,
    required this.warning,
    required this.error,
    required this.navBar,
    required this.selected,
    required this.hero,
    required this.glow,
    required this.glows,
  });

  /// Delay tiers share their source colors with the status colors (doc
  /// section 2, same-source rule).
  Color get delayGood => success;

  Color get delayMid => warning;

  Color get delayBad => error;

  /// Disabled elements render in textSecondary at 45% (family-wide rule).
  Color get disabled => textSecondary.withValues(alpha: 0.45);

  /// The solid tone the page sits on: the background gradient's last stop
  /// (its deepest tone) or the solid background itself.
  Color get backgroundBase =>
      background.isGradient ? background.stops!.last : background.firstColor;

  Color compositeOverBase(Color color) =>
      Color.alphaBlend(color, backgroundBase);

  ColorScheme toColorScheme(Brightness brightness) {
    final base = backgroundBase;
    final surfaceSolid = compositeOverBase(surface);
    final variantSolid = compositeOverBase(surfaceVariant);
    final outlineSolid = compositeOverBase(outline);
    final onError = error.computeLuminance() > 0.55
        ? const Color(0xFF2A0E0E)
        : const Color(0xFFFFFFFF);
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: selected.isNone ? surfaceVariant : selected.firstColor,
      onPrimaryContainer: textPrimary,
      secondary: secondary,
      onSecondary: onPrimary,
      secondaryContainer: variantSolid,
      onSecondaryContainer: textPrimary,
      tertiary: accent,
      onTertiary: base,
      tertiaryContainer: variantSolid,
      onTertiaryContainer: textPrimary,
      error: error,
      onError: onError,
      errorContainer: Color.alphaBlend(
        error.withValues(alpha: 0.14),
        surfaceSolid,
      ),
      onErrorContainer: error,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceDim: Color.alphaBlend(const Color(0x14000000), base),
      surfaceBright: surfaceSolid,
      surfaceContainerLowest: brightness == Brightness.light
          ? Color.alphaBlend(const Color(0x0A000000), surfaceSolid)
          : Color.alphaBlend(const Color(0x1A000000), base),
      surfaceContainerLow: variantSolid,
      surfaceContainer: variantSolid,
      surfaceContainerHigh: Color.alphaBlend(
        textPrimary.withValues(alpha: 0.04),
        variantSolid,
      ),
      surfaceContainerHighest: Color.alphaBlend(
        textPrimary.withValues(alpha: 0.08),
        variantSolid,
      ),
      outline: outlineSolid,
      outlineVariant: Color.alphaBlend(
        outline.withValues(alpha: outline.a * 0.6),
        base,
      ),
      inverseSurface: textPrimary,
      onInverseSurface: base,
      inversePrimary: secondary,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      surfaceTint: Colors.transparent,
    );
  }
}

class ZodiacThemeDef {
  final String id;
  final String sign;
  final String nameZh;
  final String nameEn;
  final ZodiacSkeleton skeleton;
  final ZodiacVariant light;
  final ZodiacVariant dark;

  const ZodiacThemeDef({
    required this.id,
    required this.sign,
    required this.nameZh,
    required this.nameEn,
    required this.skeleton,
    required this.light,
    required this.dark,
  });

  ZodiacVariant variant(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// All twelve themes in zodiac order (doc section 5.1).
List<ZodiacThemeDef> get zodiacThemes => zodiacThemeDefs;

ZodiacThemeDef get zodiacDefaultTheme =>
    zodiacThemeDefs.firstWhere((theme) => theme.id == zodiacDefaultThemeId);

/// Resolves a stored selection; unknown or missing ids fall back to the
/// default theme silently (doc section 5.2).
ZodiacThemeDef resolveZodiacTheme(String? id) {
  for (final theme in zodiacThemeDefs) {
    if (theme.id == id) return theme;
  }
  return zodiacDefaultTheme;
}

/// Carries the active variant's full token set plus its skeleton into the
/// widget tree, for surfaces the Material color scheme cannot express
/// (selected gradients, glow, navigation bar tone, delay colors).
class ZodiacThemeExtension extends ThemeExtension<ZodiacThemeExtension> {
  final String themeId;
  final ZodiacSkeleton skeleton;
  final ZodiacVariant variant;

  const ZodiacThemeExtension({
    required this.themeId,
    required this.skeleton,
    required this.variant,
  });

  factory ZodiacThemeExtension.of(ZodiacThemeDef def, Brightness brightness) {
    return ZodiacThemeExtension(
      themeId: def.id,
      skeleton: def.skeleton,
      variant: def.variant(brightness),
    );
  }

  /// Navigation selection color: the immersive family marks the current
  /// tab with its accent-arrow secondary (doc 3.5.6); other families keep
  /// the primary.
  Color get navSelected => skeleton == ZodiacSkeleton.immersive
      ? variant.secondary
      : variant.primary;

  @override
  ZodiacThemeExtension copyWith({
    String? themeId,
    ZodiacSkeleton? skeleton,
    ZodiacVariant? variant,
  }) {
    return ZodiacThemeExtension(
      themeId: themeId ?? this.themeId,
      skeleton: skeleton ?? this.skeleton,
      variant: variant ?? this.variant,
    );
  }

  @override
  ZodiacThemeExtension lerp(ZodiacThemeExtension? other, double t) {
    if (other == null || t >= 1) return other ?? this;
    return t < 0.5 ? this : other;
  }
}

extension ZodiacContext on BuildContext {
  ZodiacThemeExtension? get zodiac =>
      Theme.of(this).extension<ZodiacThemeExtension>();
}

/// Delay tier color from the active variant's tokens (doc section 2:
/// the tiers share the status colors). Falls back to the legacy fixed
/// colors when no zodiac theme is in scope.
Color? zodiacDelayColor(ZodiacVariant? variant, int? delay) {
  if (delay == null) return null;
  if (variant == null) {
    if (delay < 0) return Colors.red;
    if (delay < 600) return Colors.green;
    return const Color(0xFFC57F0A);
  }
  if (delay < 0) return variant.delayBad;
  if (delay < 600) return variant.delayGood;
  return variant.delayMid;
}

/// Paints the active variant's page background: the token gradient (or
/// solid) plus, for the immersive family, its fixed radial glow spots
/// (doc 3.4: positions never move with content).
class ZodiacBackdrop extends StatelessWidget {
  const ZodiacBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final zodiac = context.zodiac;
    if (zodiac == null) return const SizedBox.expand();
    final variant = zodiac.variant;
    final background = variant.background;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: background.isGradient ? null : variant.backgroundBase,
            gradient: background.isGradient ? background.gradient : null,
          ),
        ),
        for (final spot in variant.glows)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: spot.pos == ZodiacGlowPos.topRight
                      ? const Alignment(0.85, -0.85)
                      : const Alignment(-0.9, 0.1),
                  radius: 0.9,
                  colors: [spot.color, spot.color.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
