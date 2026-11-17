import 'dart:math' as math;
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

  /// The family's single variant is a dark design (DESIGN doc section
  /// 1 rule 9, single-set decision 2026-11-15), so the scheme is always
  /// composed at dark brightness — including when the app sits in its
  /// Material light slot under a light system mode.
  ColorScheme toColorScheme() {
    final base = backgroundBase;
    final surfaceSolid = compositeOverBase(surface);
    final variantSolid = compositeOverBase(surfaceVariant);
    final outlineSolid = compositeOverBase(outline);
    final onError = error.computeLuminance() > 0.55
        ? const Color(0xFF2A0E0E)
        : const Color(0xFFFFFFFF);
    return ColorScheme(
      brightness: Brightness.dark,
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
      surfaceContainerLowest: Color.alphaBlend(const Color(0x1A000000), base),
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

  /// The theme's single variant. The family is single-set (DESIGN doc
  /// section 1 rule 9): the former dark variant is canonical and the
  /// light variant set was removed, so there is no brightness split.
  final ZodiacVariant variant;

  const ZodiacThemeDef({
    required this.id,
    required this.sign,
    required this.nameZh,
    required this.nameEn,
    required this.skeleton,
    this.constellation = ZodiacConstellation.empty,
    required this.variant,
  });
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

  /// The deep-space event motif painted as this theme's background
  /// element layer; null for the other series.
  final DeepSpaceMotif? motif;

  /// The constellation painted as this theme's element layer (the
  /// twelve-constellation and golden-saint series); empty for the
  /// deep-space and solar-system series.
  final ZodiacConstellation constellation;

  /// Whether the guardian figure and plate ride in the backdrop.
  /// Only the twelve-constellation series carries guardians.
  final bool showGuardian;

  /// The solar-system body painted, blurred, as this theme's only
  /// background element （太阳系家园 series); null elsewhere.
  final SolarBody? planet;

  /// The sign glyph watermark for constellation-bearing series;
  /// empty for the deep-space and solar-system series.
  final String sign;

  const ZodiacThemeExtension({
    required this.themeId,
    required this.skeleton,
    required this.variant,
    this.motif,
    this.constellation = ZodiacConstellation.empty,
    this.showGuardian = true,
    this.planet,
    this.sign = '',
  });

  factory ZodiacThemeExtension.of(ZodiacThemeDef def) {
    return ZodiacThemeExtension(
      themeId: def.id,
      skeleton: def.skeleton,
      variant: def.variant,
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
    DeepSpaceMotif? motif,
    ZodiacConstellation? constellation,
    bool? showGuardian,
    SolarBody? planet,
    String? sign,
  }) {
    return ZodiacThemeExtension(
      themeId: themeId ?? this.themeId,
      skeleton: skeleton ?? this.skeleton,
      variant: variant ?? this.variant,
      motif: motif ?? this.motif,
      constellation: constellation ?? this.constellation,
      showGuardian: showGuardian ?? this.showGuardian,
      planet: planet ?? this.planet,
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
    // Solar-system series （太阳系家园）: a plain base color and one
    // blurred planet — no light field, no element layer, nothing
    // else. This is the family's plain-background form.
    if (zodiac.planet != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: variant.backgroundBase),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: SolarPlanetPainter(
                body: zodiac.planet!,
                variant: variant,
              ),
            ),
          ),
        ],
      );
    }
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
        // mood, they never compete with the content. Element line
        // art gets a light defocus; the guardian figure a stronger
        // one. The name plate is text, not artwork — it stays
        // legible, already dimmed. Solar-system planets are blurred
        // inside their painter by design.
        if (zodiac.motif != null)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: 1.3,
                sigmaY: 1.3,
                tileMode: ui.TileMode.mirror,
              ),
              child: CustomPaint(
                painter: DeepSpaceMotifPainter(
                  motif: zodiac.motif!,
                  variant: variant,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ),
          )
        else ...[
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
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: 2.2,
                  sigmaY: 2.2,
                  tileMode: ui.TileMode.mirror,
                ),
                child: const ZodiacGuardianBackdropFigure(),
              ),
            ),
          if (showGuardian && zodiac.showGuardian)
            const Positioned.fill(child: ZodiacGuardianPlate()),
        ],
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
          color: variant.textPrimary.withValues(alpha: 0.05),
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

/// The Human Deep Space Exploration series' background motifs
/// (T181): one per historic event, drawn by [DeepSpaceMotifPainter]
/// as theme-toned line work in the backdrop's element layer — the
/// same role the asterism plays for constellation themes.
enum DeepSpaceMotif {
  /// A planet with a craft in an elliptical orbit (Vostok 1).
  orbit,

  /// The same orbit composition with a capsule glyph (Shenzhou 5).
  capsuleOrbit,

  /// Descent arc onto a large moon disc (Apollo 11).
  moonLanding,

  /// A trajectory sweeping away from a small planet (Voyager 1).
  escapeTrajectory,

  /// Scattered-light bands with one pale dot (Pale Blue Dot).
  paleBlueDot,

  /// A ringed planet with its orbiter (Cassini).
  ringedPlanet,

  /// Descent onto a curved lunar surface with a rover (Chang'e 3).
  lunarDescent,

  /// A hyperbolic pass by a planet (New Horizons).
  flyby,

  /// The moon's far side with a relay satellite link (Chang'e 4).
  farSide,

  /// A craft in orbit around Mars (Tianwen 1).
  marsOrbit,

  /// A hexagonal segmented mirror array (James Webb).
  mirrorArray,

  /// A kinetic impactor striking a small asteroid (DART).
  impact,

  /// A shuttle climbing its ascent arc (Columbia, STS-1).
  shuttleAscent,

  /// A space telescope in orbit above the Earth arc (Hubble).
  telescopeOrbit,

  /// A truss-and-panels station over the Earth arc (ISS).
  spaceStation,
}

/// Paints a [DeepSpaceMotif] in the active variant's tones: primary
/// line work, secondary accents, textPrimary star points — the same
/// palette discipline as the constellation painter, so an event
/// background changes character with its theme and never borrows
/// another event's colors.
class DeepSpaceMotifPainter extends CustomPainter {
  final DeepSpaceMotif motif;
  final ZodiacVariant variant;
  final bool isDark;

  const DeepSpaceMotifPainter({
    required this.motif,
    required this.variant,
    required this.isDark,
  });

  double get _lineAlpha => isDark ? 0.5 : 0.38;

  Paint _stroke(Color color, double alpha, double width) => Paint()
    ..color = color.withValues(alpha: alpha)
    ..strokeWidth = width
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  Paint _fill(Color color, double alpha) =>
      Paint()..color = color.withValues(alpha: alpha);

  void _dash(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      var draw = true;
      while (d < metric.length) {
        final len = draw ? 7.0 : 6.0;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(d, math.min(d + len, metric.length)),
            paint,
          );
        }
        d += len;
        draw = !draw;
      }
    }
  }

  /// A sparse deterministic star field across the upper sky, shared
  /// by every motif (positions from a fixed irrational walk, so the
  /// field is identical on every frame and every device).
  void _starField(Canvas canvas, Size size) {
    for (var i = 0; i < 30; i++) {
      final x = (i * 0.61803 + 0.07) % 1.0;
      final y = ((i * 0.75488 + 0.05) % 1.0) * 0.52;
      final center = Offset(size.width * x, size.height * y);
      final big = i % 7 == 0;
      if (big) {
        canvas.drawCircle(
          center,
          6,
          Paint()
            ..color = variant.secondary.withValues(alpha: 0.16)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      canvas.drawCircle(
        center,
        big ? 2.0 : 1.2,
        _fill(variant.textPrimary, big ? 0.65 : 0.4),
      );
    }
  }

  void _planet(Canvas canvas, Offset center, double r, {double fill = 0.05}) {
    canvas.drawCircle(center, r, _fill(variant.primary, fill));
    canvas.drawCircle(center, r, _stroke(variant.primary, _lineAlpha, 1.2));
  }

  void _craftDot(Canvas canvas, Offset at, {double r = 3}) {
    canvas.drawCircle(
      at,
      r * 2.6,
      Paint()
        ..color = variant.secondary.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(at, r, _fill(variant.secondary, 0.95));
  }

  /// An ellipse (orbit) around [center], drawn through a canvas
  /// transform so rotation comes free.
  void _orbit(
    Canvas canvas,
    Offset center,
    double rx,
    double ry,
    double rotation,
    Paint paint, {
    bool dashed = false,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final path = Path()
      ..addOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      );
    if (dashed) {
      _dash(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  Offset _orbitPoint(
    Offset center,
    double rx,
    double ry,
    double rotation,
    double t,
  ) {
    final x = rx * math.cos(t);
    final y = ry * math.sin(t);
    final c = math.cos(rotation);
    final s = math.sin(rotation);
    return Offset(center.dx + x * c - y * s, center.dy + x * s + y * c);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _starField(canvas, size);
    final w = size.width;
    final h = size.height;
    switch (motif) {
      case DeepSpaceMotif.orbit:
      case DeepSpaceMotif.capsuleOrbit:
        final center = Offset(w * 0.70, h * 0.24);
        final rx = w * 0.30;
        final ry = h * 0.105;
        const rotation = -0.35;
        _orbit(
          canvas,
          center,
          rx,
          ry,
          rotation,
          _stroke(variant.primary, _lineAlpha * 0.8, 1.1),
        );
        _planet(canvas, center, w * 0.082);
        final at = _orbitPoint(center, rx, ry, rotation, 2.4);
        if (motif == DeepSpaceMotif.capsuleOrbit) {
          // A capsule: hull plus a solar wing line.
          canvas.save();
          canvas.translate(at.dx, at.dy);
          canvas.rotate(rotation + 0.5);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: 13, height: 8),
              const Radius.circular(4),
            ),
            _fill(variant.secondary, 0.95),
          );
          canvas.drawLine(
            const Offset(-11, 0),
            const Offset(11, 0),
            _stroke(variant.secondary, 0.8, 1.6),
          );
          canvas.restore();
        } else {
          _craftDot(canvas, at);
        }
      case DeepSpaceMotif.moonLanding:
        final moon = Offset(w * 0.86, h * 0.12);
        final mr = w * 0.15;
        _planet(canvas, moon, mr, fill: 0.07);
        for (final crater in [
          (0.3, 0.35, 0.16),
          (-0.25, 0.1, 0.11),
          (0.05, -0.4, 0.09),
        ]) {
          canvas.drawCircle(
            Offset(moon.dx + mr * crater.$1, moon.dy + mr * crater.$2),
            mr * crater.$3,
            _stroke(variant.primary, 0.22, 1),
          );
        }
        final descent = Path()
          ..moveTo(w * 0.08, h * 0.05)
          ..cubicTo(
            w * 0.34,
            h * 0.01,
            w * 0.52,
            h * 0.08,
            w * 0.72,
            h * 0.155,
          );
        _dash(canvas, descent, _stroke(variant.secondary, 0.75, 1.3));
        final land = Offset(w * 0.72, h * 0.155);
        canvas.drawRect(
          Rect.fromCenter(center: land, width: 7, height: 5),
          _fill(variant.secondary, 0.95),
        );
        canvas.drawLine(
          Offset(land.dx - 5, land.dy + 5),
          Offset(land.dx - 1, land.dy + 2),
          _stroke(variant.secondary, 0.9, 1.2),
        );
        canvas.drawLine(
          Offset(land.dx + 5, land.dy + 5),
          Offset(land.dx + 1, land.dy + 2),
          _stroke(variant.secondary, 0.9, 1.2),
        );
      case DeepSpaceMotif.escapeTrajectory:
        final planet = Offset(w * 0.16, h * 0.40);
        _planet(canvas, planet, w * 0.052);
        final path = Path()
          ..moveTo(planet.dx, planet.dy)
          ..cubicTo(w * 0.40, h * 0.33, w * 0.62, h * 0.17, w * 0.99, h * 0.03);
        // The trajectory fades as it leaves: three segments of
        // decreasing alpha along one path.
        for (final metric in path.computeMetrics()) {
          for (var seg = 0; seg < 3; seg++) {
            final from = metric.length * seg / 3;
            final to = metric.length * (seg + 1) / 3;
            canvas.drawPath(
              metric.extractPath(from, to),
              _stroke(variant.primary, _lineAlpha * (1 - seg * 0.28), 1.3),
            );
          }
          final tangent = metric.getTangentForOffset(metric.length * 0.72);
          if (tangent != null) _craftDot(canvas, tangent.position);
        }
      case DeepSpaceMotif.paleBlueDot:
        canvas.save();
        canvas.translate(w * 0.5, h * 0.26);
        canvas.rotate(-0.42);
        final bands = [
          (0.055, variant.secondary, 0.10, -0.10),
          (0.034, variant.primary, 0.09, 0.0),
          (0.075, variant.accent, 0.05, 0.115),
        ];
        for (final band in bands) {
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(0, h * band.$4),
              width: w * 1.6,
              height: h * band.$1,
            ),
            _fill(band.$2, band.$3),
          );
        }
        canvas.restore();
        final dot = Offset(w * 0.635, h * 0.295);
        canvas.drawCircle(
          dot,
          9,
          Paint()
            ..color = variant.primary.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
        );
        canvas.drawCircle(dot, 3.2, _fill(variant.primary, 1));
        canvas.drawCircle(dot, 1.3, _fill(const Color(0xFFFFFFFF), 0.95));
      case DeepSpaceMotif.ringedPlanet:
        final center = Offset(w * 0.50, h * 0.235);
        final r = w * 0.082;
        _orbit(
          canvas,
          center,
          w * 0.205,
          h * 0.042,
          -0.28,
          _stroke(variant.secondary, 0.4, 1.4),
        );
        _planet(canvas, center, r, fill: 0.08);
        // Front ring arc over the planet's lower face.
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-0.28);
        canvas.scale(1, (h * 0.042) / (w * 0.205));
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: w * 0.205),
          0.15,
          math.pi - 0.3,
          false,
          _stroke(variant.secondary, 0.75, 2.2),
        );
        canvas.restore();
        final orbiter = Offset(w * 0.665, h * 0.095);
        _craftDot(canvas, orbiter, r: 2.4);
        _dash(
          canvas,
          Path()
            ..moveTo(orbiter.dx, orbiter.dy)
            ..quadraticBezierTo(w * 0.62, h * 0.15, w * 0.575, h * 0.185),
          _stroke(variant.secondary, 0.5, 1),
        );
      case DeepSpaceMotif.lunarDescent:
        final surfaceCenter = Offset(w * 0.5, h * 1.42);
        final surfaceR = h * 1.0;
        canvas.drawCircle(
          surfaceCenter,
          surfaceR,
          _stroke(variant.primary, _lineAlpha * 0.9, 1.3),
        );
        final descent = Path()
          ..moveTo(w * 0.10, h * 0.04)
          ..cubicTo(
            w * 0.22,
            h * 0.16,
            w * 0.30,
            h * 0.30,
            w * 0.415,
            h * 0.425,
          );
        _dash(canvas, descent, _stroke(variant.secondary, 0.75, 1.3));
        final land = Offset(w * 0.415, h * 0.425);
        canvas.drawRect(
          Rect.fromCenter(center: land, width: 8, height: 5),
          _fill(variant.secondary, 0.95),
        );
        // The rover, a short way along the surface: two wheel dots
        // and a mast.
        final rover = Offset(w * 0.575, h * 0.402);
        canvas.drawCircle(
          Offset(rover.dx - 4, rover.dy + 3),
          1.8,
          _fill(variant.accent, 0.9),
        );
        canvas.drawCircle(
          Offset(rover.dx + 4, rover.dy + 3),
          1.8,
          _fill(variant.accent, 0.9),
        );
        canvas.drawLine(
          Offset(rover.dx, rover.dy + 2),
          Offset(rover.dx, rover.dy - 6),
          _stroke(variant.accent, 0.9, 1.4),
        );
      case DeepSpaceMotif.flyby:
        final planet = Offset(w * 0.30, h * 0.19);
        final r = w * 0.098;
        _planet(canvas, planet, r, fill: 0.07);
        // Pluto's lighter heart plain: two soft overlapping lobes.
        canvas.drawCircle(
          Offset(planet.dx + r * 0.18, planet.dy + r * 0.22),
          r * 0.42,
          _fill(variant.secondary, 0.13),
        );
        canvas.drawCircle(
          Offset(planet.dx - r * 0.22, planet.dy + r * 0.3),
          r * 0.3,
          _fill(variant.secondary, 0.10),
        );
        final path = Path()
          ..moveTo(-w * 0.02, h * 0.015)
          ..quadraticBezierTo(w * 0.34, h * 0.46, w * 0.72, h * 0.335)
          ..quadraticBezierTo(w * 0.88, h * 0.29, w * 1.02, h * 0.315);
        canvas.drawPath(path, _stroke(variant.primary, _lineAlpha, 1.3));
        for (final metric in path.computeMetrics()) {
          final tangent = metric.getTangentForOffset(metric.length * 0.47);
          if (tangent != null) _craftDot(canvas, tangent.position);
        }
      case DeepSpaceMotif.farSide:
        final moon = Offset(w * 0.44, h * 0.235);
        final r = w * 0.112;
        _planet(canvas, moon, r, fill: 0.06);
        // The far side turned away: shade the moon's right portion.
        canvas.save();
        canvas.clipPath(
          Path()..addOval(Rect.fromCircle(center: moon, radius: r)),
        );
        canvas.drawRect(
          Rect.fromLTWH(moon.dx + r * 0.05, moon.dy - r, r, r * 2),
          _fill(const Color(0xFF000000), 0.22),
        );
        canvas.restore();
        final relay = Offset(w * 0.85, h * 0.085);
        _orbit(
          canvas,
          relay,
          w * 0.058,
          h * 0.02,
          0.5,
          _stroke(variant.secondary, 0.55, 1),
        );
        _craftDot(canvas, relay, r: 2.4);
        _dash(
          canvas,
          Path()
            ..moveTo(moon.dx + r * 0.75, moon.dy - r * 0.55)
            ..quadraticBezierTo(w * 0.68, h * 0.05, relay.dx - 4, relay.dy + 3),
          _stroke(variant.secondary, 0.6, 1.1),
        );
        _craftDot(
          canvas,
          Offset(moon.dx + r * 0.42, moon.dy + r * 0.62),
          r: 2.2,
        );
      case DeepSpaceMotif.marsOrbit:
        final center = Offset(w * 0.68, h * 0.245);
        final r = w * 0.098;
        final rx = w * 0.265;
        final ry = h * 0.098;
        const rotation = -0.3;
        _orbit(
          canvas,
          center,
          rx,
          ry,
          rotation,
          _stroke(variant.primary, _lineAlpha * 0.8, 1.1),
        );
        _planet(canvas, center, r, fill: 0.08);
        // Polar cap and a dark albedo patch.
        canvas.save();
        canvas.clipPath(
          Path()..addOval(Rect.fromCircle(center: center, radius: r)),
        );
        canvas.drawCircle(
          Offset(center.dx, center.dy - r * 0.92),
          r * 0.34,
          _fill(const Color(0xFFFFFFFF), 0.28),
        );
        canvas.drawCircle(
          Offset(center.dx - r * 0.3, center.dy + r * 0.25),
          r * 0.45,
          _fill(const Color(0xFF000000), 0.16),
        );
        canvas.restore();
        _craftDot(canvas, _orbitPoint(center, rx, ry, rotation, 0.45));
      case DeepSpaceMotif.mirrorArray:
        final center = Offset(w * 0.31, h * 0.215);
        final hr = w * 0.036;
        void hex(Offset c, double radius, {bool filled = false}) {
          final path = Path();
          for (var i = 0; i < 6; i++) {
            final a = math.pi / 3 * i + math.pi / 6;
            final p = Offset(
              c.dx + radius * math.cos(a),
              c.dy + radius * math.sin(a),
            );
            i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
          }
          path.close();
          if (filled) canvas.drawPath(path, _fill(variant.primary, 0.12));
          canvas.drawPath(path, _stroke(variant.primary, 0.65, 1.2));
        }

        final dx = hr * 1.78;
        final dy = hr * 1.56;
        hex(center, hr, filled: true);
        for (final o in [
          Offset(dx, 0),
          Offset(-dx, 0),
          Offset(dx / 2, dy),
          Offset(-dx / 2, dy),
          Offset(dx / 2, -dy),
          Offset(-dx / 2, -dy),
        ]) {
          hex(center + o, hr);
        }
        // Collected starlight leaving the array.
        for (var i = 0; i < 3; i++) {
          final from = Offset(center.dx + dx + hr, center.dy - dy + i * dy);
          canvas.drawLine(
            from,
            Offset(w * 0.97, from.dy - h * 0.055),
            _stroke(variant.secondary, 0.16, 1.1),
          );
        }
      case DeepSpaceMotif.impact:
        final big = Offset(w * 0.60, h * 0.215);
        _planet(canvas, big, w * 0.062, fill: 0.06);
        final small = Offset(w * 0.745, h * 0.295);
        _planet(canvas, small, w * 0.031, fill: 0.06);
        final hit = Offset(w * 0.718, h * 0.272);
        _dash(
          canvas,
          Path()
            ..moveTo(w * 0.07, h * 0.03)
            ..quadraticBezierTo(w * 0.38, h * 0.10, hit.dx, hit.dy),
          _stroke(variant.primary, 0.7, 1.2),
        );
        _craftDot(canvas, hit, r: 2.6);
        // The burst: rays of uneven length from the impact point.
        for (var i = 0; i < 9; i++) {
          final a = -0.9 + i * 0.42;
          final len = w * (0.02 + (i % 3) * 0.011);
          canvas.drawLine(
            hit,
            Offset(hit.dx + len * math.cos(a), hit.dy + len * math.sin(a)),
            _stroke(i.isEven ? variant.secondary : variant.accent, 0.8, 1.3),
          );
        }
      case DeepSpaceMotif.shuttleAscent:
        // The ascent: a dashed exhaust trail curving up from the
        // lower left, the shuttle glyph riding its head.
        final trail = Path()
          ..moveTo(w * 0.06, h * 0.54)
          ..cubicTo(
            w * 0.20,
            h * 0.40,
            w * 0.34,
            h * 0.28,
            w * 0.56,
            h * 0.175,
          );
        _dash(canvas, trail, _stroke(variant.textPrimary, 0.35, 3.2));
        _dash(canvas, trail, _stroke(variant.secondary, 0.55, 1.4));
        final nose = Offset(w * 0.615, h * 0.15);
        canvas.save();
        canvas.translate(nose.dx, nose.dy);
        canvas.rotate(-0.62);
        // Fuselage, delta wing and tail fin as one line glyph.
        final shuttle = Path()
          ..moveTo(0, -17)
          ..quadraticBezierTo(4.5, -8, 4, 2)
          ..lineTo(13, 12)
          ..lineTo(4.5, 12)
          ..lineTo(4, 7)
          ..lineTo(-4, 7)
          ..lineTo(-4.5, 12)
          ..lineTo(-13, 12)
          ..lineTo(-4, 2)
          ..quadraticBezierTo(-4.5, -8, 0, -17)
          ..close();
        canvas.drawPath(shuttle, _fill(variant.primary, 0.16));
        canvas.drawPath(shuttle, _stroke(variant.primary, 0.85, 1.3));
        canvas.drawCircle(
          const Offset(0, -9),
          1.8,
          _fill(variant.secondary, 0.95),
        );
        canvas.restore();
      case DeepSpaceMotif.telescopeOrbit:
      case DeepSpaceMotif.spaceStation:
        // The shared stage: Earth's limb as a great arc low in the
        // frame, the craft in orbit above it.
        final earthCenter = Offset(w * 0.5, h * 1.52);
        final earthR = h * 1.06;
        canvas.drawCircle(
          earthCenter,
          earthR,
          _stroke(variant.primary, _lineAlpha * 0.85, 1.3),
        );
        canvas.drawCircle(earthCenter, earthR, _fill(variant.primary, 0.04));
        if (motif == DeepSpaceMotif.telescopeOrbit) {
          final orbit = Path()
            ..moveTo(w * 0.04, h * 0.335)
            ..quadraticBezierTo(w * 0.5, h * 0.20, w * 0.96, h * 0.335);
          _dash(canvas, orbit, _stroke(variant.primary, 0.4, 1.1));
          final hubble = Offset(w * 0.40, h * 0.235);
          canvas.save();
          canvas.translate(hubble.dx, hubble.dy);
          canvas.rotate(-0.42);
          // The tube, its aperture and the two panel wings.
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: 36, height: 12),
              const Radius.circular(6),
            ),
            _stroke(variant.primary, 0.85, 1.4),
          );
          canvas.drawCircle(
            const Offset(18, 0),
            4.5,
            _stroke(variant.secondary, 0.9, 1.3),
          );
          for (final side in [-1.0, 1.0]) {
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset(side * 8, -13),
                width: 15,
                height: 9,
              ),
              _fill(variant.secondary, 0.55),
            );
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset(side * 8, 13),
                width: 15,
                height: 9,
              ),
              _fill(variant.secondary, 0.55),
            );
          }
          canvas.restore();
        } else {
          final station = Offset(w * 0.5, h * 0.175);
          // The truss.
          canvas.drawLine(
            Offset(station.dx - w * 0.17, station.dy),
            Offset(station.dx + w * 0.17, station.dy),
            _stroke(variant.primary, 0.85, 1.6),
          );
          // Four panel pairs along the truss.
          for (final fx in [-0.145, -0.055, 0.055, 0.145]) {
            final px = station.dx + w * fx;
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset(px, station.dy - 10),
                width: 20,
                height: 11,
              ),
              _fill(variant.secondary, 0.6),
            );
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset(px, station.dy + 10),
                width: 20,
                height: 11,
              ),
              _fill(variant.secondary, 0.6),
            );
          }
          // The pressurized modules under the truss center.
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(station.dx, station.dy + 9),
                width: 30,
                height: 9,
              ),
              const Radius.circular(4.5),
            ),
            _fill(variant.primary, 0.85),
          );
          _craftDot(
            canvas,
            Offset(station.dx + w * 0.20, station.dy + 16),
            r: 2.2,
          );
        }
    }
  }

  @override
  bool shouldRepaint(DeepSpaceMotifPainter oldDelegate) =>
      oldDelegate.motif != motif ||
      oldDelegate.variant != variant ||
      oldDelegate.isDark != isDark;
}

/// The eight planets of the 太阳系家园 (Solar System Home) series:
/// each theme's background is a plain base color carrying exactly
/// one of these bodies, softly blurred.
enum SolarBody { mercury, venus, earth, mars, jupiter, saturn, uranus, neptune }

/// Paints one solar-system body as a large, defocused disc — the
/// only element on the solar-system series' plain backgrounds. The
/// disc is lit from the upper left in the variant's primary-to-
/// secondary tones and blurred at both its edge and its glow, so it
/// reads as atmosphere, not as a sticker. Saturn gets its ring.
class SolarPlanetPainter extends CustomPainter {
  final SolarBody body;
  final ZodiacVariant variant;

  const SolarPlanetPainter({required this.body, required this.variant});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.76, h * 0.30);
    final r = w * 0.33;

    // Halo: the body's light bleeding into the plain field.
    canvas.drawCircle(
      center,
      r * 1.3,
      Paint()
        ..color = variant.primary.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
    );

    // The disc itself, defocused: a radial light falloff (lit from
    // the upper left, shadow side toward the lower right) with a
    // blurred rim.
    final rect = Rect.fromCircle(center: center, radius: r);
    final discPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.45, -0.45),
        radius: 1.25,
        colors: [variant.primary, variant.secondary],
        stops: const [0.1, 1],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13);
    canvas.drawCircle(center, r, discPaint);

    if (body == SolarBody.saturn) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-0.30);
      canvas.scale(1, 0.30);
      canvas.drawCircle(
        Offset.zero,
        r * 1.45,
        Paint()
          ..color = variant.secondary.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.17
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
      canvas.restore();
    }
    if (body == SolarBody.jupiter) {
      // Blurred horizontal bands, barely there under the defocus.
      canvas.save();
      canvas.clipPath(Path()..addOval(rect));
      for (var i = 0; i < 3; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            center.dx - r,
            center.dy - r * 0.45 + i * r * 0.42,
            r * 2,
            r * 0.17,
          ),
          Paint()
            ..color = variant.secondary.withValues(alpha: 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(SolarPlanetPainter oldDelegate) =>
      oldDelegate.body != body || oldDelegate.variant != variant;
}
