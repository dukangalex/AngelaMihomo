import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'color.dart';
import 'zodiac_guardians.dart';

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

  const ZodiacPaint._(this.isAtmospherePaint) : solidColor = null, stops = null;

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

  /// Composes this variant's color scheme at its own [brightness]:
  /// the light variant serves the Material light slot, the dark
  /// variant the dark slot, so the presentation follows the app's
  /// theme mode (system / light / dark). T298 restored the dual set;
  /// the T151 single-set decision (2026-11-15) is reversed.
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
      // Composited over the background base, never the raw translucent
      // token: panels painted with `surface` must stay solid enough
      // that the text on them keeps its contrast over the backdrop's
      // bright artwork (T175).
      surface: surfaceSolid,
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

/// One star of a theme's asterism (doc section 7.3): normalized
/// coordinates in the backdrop's constellation field (x right, y down,
/// 0–1) plus a brightness tier (1 dim, 2 mid, 3 bright).
class ZodiacStar {
  final double x;
  final double y;
  final int magnitude;

  const ZodiacStar(this.x, this.y, this.magnitude);
}

/// A connecting line between two stars of an asterism, by index.
class ZodiacEdge {
  final int a;
  final int b;

  const ZodiacEdge(this.a, this.b);
}

/// A theme's constellation element: the simplified main-star asterism
/// that makes the sign recognizable in the light field (doc 7.3).
class ZodiacConstellation {
  final List<ZodiacStar> stars;
  final List<ZodiacEdge> edges;

  const ZodiacConstellation({required this.stars, required this.edges});

  static const empty = ZodiacConstellation(stars: [], edges: []);
}

class ZodiacThemeDef {
  final String id;
  final String sign;
  final String nameZh;
  final String nameEn;
  final ZodiacSkeleton skeleton;
  final ZodiacConstellation constellation;

  /// The theme's light variant (Material light slot).
  final ZodiacVariant light;

  /// The theme's dark variant (Material dark slot) — the canonical
  /// set the family shipped as its only set between T151 and T298.
  final ZodiacVariant dark;

  const ZodiacThemeDef({
    required this.id,
    required this.sign,
    required this.nameZh,
    required this.nameEn,
    required this.skeleton,
    this.constellation = ZodiacConstellation.empty,
    required this.light,
    required this.dark,
  });

  /// The variant for a resolved [brightness].
  ZodiacVariant variantFor(Brightness brightness) =>
      brightness == Brightness.light ? light : dark;
}

/// All twelve themes in zodiac order (doc section 5.1).
List<ZodiacThemeDef> get zodiacThemes => zodiacThemeDefs;

/// Series labels under the 星辰大海 umbrella (T182): the theme
/// chooser groups its rows by series with these headers.
const zodiacSeriesNameZh = '星辰大海之十二星座';
const zodiacSeriesNameEn = 'Starry Sea · The Twelve Constellations';

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

  /// The constellation painted as this theme's element layer.
  final ZodiacConstellation constellation;

  /// Whether the guardian figure and plate ride in the backdrop.
  final bool showGuardian;

  /// The sign glyph watermark.
  final String sign;

  const ZodiacThemeExtension({
    required this.themeId,
    required this.skeleton,
    required this.variant,
    this.constellation = ZodiacConstellation.empty,
    this.showGuardian = true,
    this.sign = '',
  });

  factory ZodiacThemeExtension.of(ZodiacThemeDef def, Brightness brightness) {
    return ZodiacThemeExtension(
      themeId: def.id,
      skeleton: def.skeleton,
      variant: def.variantFor(brightness),
      constellation: def.constellation,
      sign: def.sign,
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
    ZodiacConstellation? constellation,
    bool? showGuardian,
    String? sign,
  }) {
    return ZodiacThemeExtension(
      themeId: themeId ?? this.themeId,
      skeleton: skeleton ?? this.skeleton,
      variant: variant ?? this.variant,
      constellation: constellation ?? this.constellation,
      showGuardian: showGuardian ?? this.showGuardian,
      sign: sign ?? this.sign,
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

/// The app-wide switch theme (T154, user decision 2026-11-15: a
/// switch that is on must read as lit at a glance). This is the single
/// styling source for every Material switch in the app; pages never
/// restyle their own switches.
///
/// DESIGN doc section 3.4 rule 5 puts every strong "selected / on"
/// state in the variant's `selected` gradient — primary running to
/// secondary. A Material switch track paints one flat color, so the
/// switch carries the gradient by its two endpoints instead: the
/// track takes the gradient's start (the selected paint's first
/// color — the primary for most themes; the paper skeletons give
/// selected a pale reversal face instead, DESIGN 4.4) and the thumb
/// its end (the last stop for gradient themes, the secondary for
/// solid ones). The
/// off state keeps the neutral scheme tones it has always had, and
/// the disabled state resolves to null so the framework's muted
/// disabled rendering applies — a disabled switch never wears the
/// lit colors. With no zodiac variant in scope the previous
/// scheme-only colors are used, the same fallback [zodiacDelayColor]
/// keeps.
SwitchThemeData zodiacSwitchTheme(
  ColorScheme colorScheme,
  ZodiacVariant? variant,
) {
  final isLight = colorScheme.brightness == Brightness.light;
  return SwitchThemeData(
    thumbIcon: const WidgetStatePropertyAll(Icon(null)),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return null;
      if (states.contains(WidgetState.selected)) {
        return variant == null
            ? colorScheme.onPrimary
            : _zodiacSwitchOnThumb(variant);
      }
      return isLight ? Colors.white : colorScheme.onSurfaceVariant;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return null;
      if (states.contains(WidgetState.selected)) {
        return variant == null
            ? colorScheme.primary
            : _zodiacSwitchOnTrack(variant);
      }
      return isLight
          ? colorScheme.surfaceContainerHighest
          : colorScheme.surfaceContainerHighest.lighten(6);
    }),
  );
}

/// The accent a switch row's supporting text takes while its switch
/// is on (T218, the user's call): the same color the lit thumb
/// paints, so the small text follows the switch's own highlight,
/// theme by theme. Without a zodiac variant the thumb falls back to
/// onPrimary, which is not a readable text color — the primary
/// stands in for text in that case.
Color zodiacSwitchLitColor(ColorScheme colorScheme, ZodiacVariant? variant) {
  if (variant == null) return colorScheme.primary;
  return _zodiacSwitchOnThumb(variant);
}

/// The standing tone for small supporting text (T218, as corrected
/// by the user): always lit, never as loud as a switch. The theme's
/// lit color is halved toward onSurface — bright enough to read
/// over the guardian backdrop, soft enough to stay small print, and
/// it follows the active theme like every other lit surface.
Color zodiacSubtitleColor(ColorScheme colorScheme, ZodiacVariant? variant) {
  return Color.lerp(
    colorScheme.onSurface,
    zodiacSwitchLitColor(colorScheme, variant),
    0.5,
  )!;
}

/// The lit track: the selected gradient's start. A selected paint of
/// none/atmosphere carries no flat tone, so the primary stands in.
Color _zodiacSwitchOnTrack(ZodiacVariant variant) {
  final selected = variant.selected;
  if (selected.isNone || selected.isAtmosphere) return variant.primary;
  return selected.firstColor;
}

/// The lit thumb: the selected gradient's end — its last stop for
/// gradient themes, the family's counterpart secondary for solid
/// ones (the two agree wherever a gradient exists today).
Color _zodiacSwitchOnThumb(ZodiacVariant variant) {
  final selected = variant.selected;
  if (selected.isGradient) return selected.stops!.last;
  return variant.secondary;
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

/// Paints the active variant's page background as a three-layer light
/// field (doc section 7.1): the token gradient (or solid), the fixed
/// radial glow spots (doc 3.4: positions never move with content), and
/// the theme's constellation element layer — its asterism and a faint
/// sign-glyph watermark — so every theme, not only the immersive
/// family, sits in its own light field with its own sign in it.
/// The solid series (T224) replaces the element layer with its
/// full-canvas artwork image, painted unblurred over the same
/// background and glow layers.
///
/// The backdrop also composes the theme's guardian (T159) as its two
/// top layers — the figure above the light field, the name plate
/// above the figure — so "wherever the zodiac backdrop is painted,
/// the guardian is there" is a property of this component itself:
/// the app root, every pushed page and every desktop route all carry
/// it without threading anything through. Both layers stay below all
/// page content: sheets, dialogs and cards cover them naturally.
/// [showGuardian] exists for surfaces that paint this backdrop at a
/// small size or in a transient context where a figure would be
/// noise (mini previews, chooser tiles); every current call site is
/// a full page background and leaves it on.
class ZodiacBackdrop extends StatelessWidget {
  /// Whether the guardian figure and name plate ride in this
  /// backdrop (T159). Defaults to on; turn it off only for small or
  /// transient backdrop surfaces, never for page backgrounds.
  final bool showGuardian;

  const ZodiacBackdrop({super.key, this.showGuardian = true});

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
        // Every painted artwork layer in the backdrop is softly
        // blurred (T187, family-wide rule): backgrounds set the
        // mood, they never compete with the content. All artwork
        // sits at a light defocus (sigma 1.2–1.3; the guardian's
        // strength was recalibrated by T193). The name plates are
        // text, not artwork — they stay legible, already dimmed.
        // T298: the twelve constellations are the only series left,
        // so the backdrop paints the one element layer — the sign's
        // constellation and watermark, the guardian figure and its
        // plate — from the active slot's variant, which follows the
        // app's theme mode (system / light / dark).
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: 1.3,
              sigmaY: 1.3,
              tileMode: ui.TileMode.mirror,
            ),
            child: CustomPaint(
              painter: _ConstellationPainter(
                constellation: zodiac.constellation,
                sign: zodiac.sign,
                variant: variant,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
        ),
        // T159: the guardian figure and its name plate are the
        // backdrop's own top layers — part of the background, below
        // whatever page content is stacked over this backdrop.
        // Only the twelve-constellation series carries them; the
        // extension's own flag says so.
        if (showGuardian && zodiac.showGuardian)
          Positioned.fill(
            child: ImageFiltered(
              // T187's stronger defocus (2.2) plus the figure's
              // own dimming read as too faint on the user's real
              // device (2026-11-17, T193): eased to 1.2 — still
              // softened, never sharp, but with body.
              imageFilter: ui.ImageFilter.blur(
                sigmaX: 1.2,
                sigmaY: 1.2,
                tileMode: ui.TileMode.mirror,
              ),
              child: const ZodiacGuardianBackdropFigure(),
            ),
          ),
        if (showGuardian && zodiac.showGuardian)
          const Positioned.fill(child: ZodiacGuardianPlate()),
      ],
    );
  }
}

/// Draws one theme's constellation element layer (doc 7.3/7.4): the
/// asterism in the fixed upper field, stars as token-toned points with
/// a soft halo on the brighter ones, and the sign glyph as a large
/// watermark in the lower right. Everything is painted from the active
/// variant's tokens — lines in primary, star cores in textPrimary,
/// halos in secondary — so the layer changes character with the theme
/// and never borrows another sign's imagery colors.
class _ConstellationPainter extends CustomPainter {
  final ZodiacConstellation constellation;
  final String sign;
  final ZodiacVariant variant;
  final bool isDark;

  const _ConstellationPainter({
    required this.constellation,
    required this.sign,
    required this.variant,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final glyph = TextPainter(
      text: TextSpan(
        text: sign,
        style: TextStyle(
          fontSize: size.width * 0.4,
          fontWeight: FontWeight.w700,
          // T299: the glyph is a watermark, so it follows the same
          // lean as the guardian figure — textPrimary is already the
          // light family on dark variants and the dark family on
          // light ones; the light tokens need extra weight to read
          // at watermark strength against a light field.
          color: variant.textPrimary.withValues(alpha: isDark ? 0.05 : 0.1),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glyph.paint(
      canvas,
      Offset(size.width - glyph.width * 0.74, size.height * 0.58),
    );

    final stars = constellation.stars;
    if (stars.isEmpty) return;
    final field = Rect.fromLTWH(
      size.width * 0.07,
      size.height * 0.05,
      size.width * 0.86,
      size.height * 0.44,
    );
    Offset at(ZodiacStar star) => Offset(
      field.left + star.x * field.width,
      field.top + star.y * field.height,
    );

    final linePath = Path();
    for (final edge in constellation.edges) {
      final a = at(stars[edge.a]);
      final b = at(stars[edge.b]);
      linePath.moveTo(a.dx, a.dy);
      linePath.lineTo(b.dx, b.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = variant.primary.withValues(alpha: isDark ? 0.35 : 0.25)
        ..strokeWidth = 1.1
        ..style = PaintingStyle.stroke,
    );

    for (final star in stars) {
      final center = at(star);
      final radius = switch (star.magnitude) {
        >= 3 => 3.0,
        2 => 2.1,
        _ => 1.4,
      };
      if (star.magnitude >= 2) {
        canvas.drawCircle(
          center,
          radius * 2.8,
          Paint()
            ..color =
                (star.magnitude >= 3 ? variant.secondary : variant.primary)
                    .withValues(alpha: star.magnitude >= 3 ? 0.22 : 0.13)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = variant.textPrimary.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) {
    return oldDelegate.constellation != constellation ||
        oldDelegate.sign != sign ||
        oldDelegate.variant != variant ||
        oldDelegate.isDark != isDark;
  }
}
