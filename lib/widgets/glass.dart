import 'dart:async';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

/// Liquid-glass effects for AngelaMihomo (T38).
///
/// Design language: background show-through + gaussian blur + translucent
/// layered fill + bright rim border + top specular highlight.
///
/// Round 2 tuning (user direction: crystal-clear, 「晶莹剔透」): blur and
/// fill were cut hard so the backdrop reads through clearly instead of a
/// milky frost, the body tint leans cooler, and the rim/specular highlights
/// were brightened and sharpened to fake a crystal refraction edge.
///
/// Round 3 tuning (user direction, after liquidglassdesign.com research):
/// the glass itself is now neutral — the fill is desaturated to a gray at
/// theme lightness, brand teal survives only on data elements and the
/// selection emphasis, and the backdrop filter boosts saturation so the
/// colours of whatever passes underneath supply the tint (content-adaptive
/// tinting). The bottom navigation bar additionally pilots a fragment
/// shader that bends backdrop sampling around the capsule rim (static UV
/// displacement, not physical refraction); see [GlassRefraction].
///
/// Full rollout (T38): the same system now covers dialogs, popup menus and
/// bottom sheets as modal glass (live blur, [GlassKind.dialog]), and the
/// card pages (proxies, profiles, connections, tools) via static scopes —
/// see [GlassScope.live].
///
/// Performance discipline: real-time backdrop blur is only used on fixed or
/// finite surfaces (bottom navigation bar, dashboard cards, modals). Long
/// scrolling lists must not opt in. When [GlassEffects.blurEnabled] is
/// false, glass surfaces degrade to a static translucent fill with no
/// [BackdropFilter].
abstract final class GlassEffects {
  /// Master switch for real-time backdrop blur. Flip to false to degrade all
  /// glass surfaces to static translucency (low-end / power-saving path).
  static bool blurEnabled = true;

  /// Kill switch for the navigation-bar refraction pilot. When false (or
  /// when the shader fails to load), the bar keeps the round-3 neutral
  /// glass without edge displacement.
  static bool refractionEnabled = true;
}

enum GlassKind { navigationBar, card, dialog }

/// Resolved liquid-glass design tokens for one surface.
class GlassTokens {
  const GlassTokens({
    required this.sigma,
    required this.fill,
    required this.staticFill,
    required this.rim,
    required this.highlightPeak,
    required this.saturation,
    this.realtime = true,
  });

  /// Backdrop blur radius (sigmaX = sigmaY).
  final double sigma;

  /// Translucent fill used while backdrop blur is active.
  final Color fill;

  /// More opaque fill used when blur is degraded off.
  final Color staticFill;

  /// Bright rim border color (the glass edge highlight).
  final Color rim;

  /// Peak alpha of the white specular gradient at the top edge.
  final double highlightPeak;

  /// Backdrop saturation multiplier (1.0 = unchanged). The glass fill is
  /// neutral, so saturation is what lets the backdrop tint the surface.
  final double saturation;

  /// Whether this surface may use a real-time [BackdropFilter]. Static
  /// surfaces (cards inside long scrolling lists) resolve with
  /// `realtime: false`: they keep the neutral fill, bright rim and larger
  /// radius of the glass language but paint [staticFill] and never blur.
  final bool realtime;

  bool get blur => GlassEffects.blurEnabled && realtime;

  Color get effectiveFill => blur ? fill : staticFill;

  /// Pulls [color] toward its own luminance gray, keeping lightness and
  /// alpha. [amount] 1.0 is fully neutral.
  static Color neutralize(Color color, [double amount = 0.85]) {
    final lum = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
    final gray = Color.from(alpha: color.a, red: lum, green: lum, blue: lum);
    return Color.lerp(color, gray, amount)!;
  }

  static GlassTokens resolve(
    ColorScheme colorScheme,
    GlassKind kind, {
    Color? base,
    bool realtime = true,
  }) {
    final isLight = colorScheme.brightness == Brightness.light;
    final rawBody =
        base ??
        (isLight
            ? Color.lerp(
                colorScheme.surface,
                colorScheme.surfaceContainerLowest,
                0.5,
              )!
            : colorScheme.surfaceContainerHigh);
    // Round 3: the glass body is neutral in both themes and regardless of
    // the caller-supplied base (the nav bar passes its card-matching body
    // colour, which used to carry the theme tint into the glass).
    final body = neutralize(rawBody);
    return switch (kind) {
      GlassKind.navigationBar => GlassTokens(
        sigma: 11,
        fill: body.withValues(alpha: isLight ? 0.28 : 0.26),
        staticFill: body.withValues(alpha: 0.94),
        rim: Colors.white.withValues(alpha: isLight ? 0.85 : 0.38),
        highlightPeak: isLight ? 0.42 : 0.24,
        saturation: 1.8,
        realtime: realtime,
      ),
      GlassKind.card => GlassTokens(
        sigma: 9,
        fill: body.withValues(alpha: isLight ? 0.27 : 0.25),
        staticFill: body.withValues(alpha: isLight ? 0.9 : 0.88),
        rim: Colors.white.withValues(alpha: isLight ? 0.8 : 0.34),
        highlightPeak: isLight ? 0.34 : 0.18,
        saturation: 1.8,
        realtime: realtime,
      ),
      // Dialogs and modal sheets float over a dimmed barrier, so the fill
      // sits at the dense end of the band for legibility; the barrier
      // itself supplies most of the separation from the page behind.
      GlassKind.dialog => GlassTokens(
        sigma: 11,
        fill: body.withValues(alpha: isLight ? 0.29 : 0.27),
        staticFill: body.withValues(alpha: isLight ? 0.92 : 0.9),
        rim: Colors.white.withValues(alpha: isLight ? 0.8 : 0.34),
        highlightPeak: isLight ? 0.34 : 0.18,
        saturation: 1.8,
        realtime: realtime,
      ),
    };
  }
}

/// Saturation stage of the backdrop filter chain: a 4x5 colour matrix in
/// the standard luminance-weighted form (the same math as the CSS
/// `saturate()` filter / SVG feColorMatrix).
ImageFilter saturationFilter(double saturation) {
  const r = 0.2126;
  const g = 0.7152;
  const b = 0.0722;
  final s = saturation;
  final inv = 1 - s;
  // NOTE: this must be a ColorFilter (4x5 color matrix, 20 entries).
  // ImageFilter.matrix is a different API — a 4x4 spatial transform with
  // 16 entries — and throws ArgumentError for a 20-entry color matrix,
  // which silently blanks every glass surface in release builds.
  return ColorFilter.matrix(<double>[
    s + inv * r,
    inv * g,
    inv * b,
    0,
    0,
    inv * r,
    s + inv * g,
    inv * b,
    0,
    0,
    inv * r,
    inv * g,
    s + inv * b,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);
}

/// Loader for the navigation-bar refraction shader (round-3 pilot).
///
/// The shader bends backdrop sampling around the capsule rim — a static UV
/// displacement that reads as edge refraction. Loading is best-effort: any
/// failure leaves [shader] null and the bar renders without displacement.
abstract final class GlassRefraction {
  static const String asset = 'shaders/nav_refraction.frag';

  /// Rim band width in logical pixels where displacement is applied.
  static const double band = 16;

  /// Maximum sampling displacement in logical pixels, at the rim itself.
  static const double strength = 7;

  static FragmentShader? _shader;
  static Future<bool>? _loading;

  /// Set once filter creation has failed on a non-Impeller backend
  /// (ImageFilter.shader is Impeller-only); the pilot then stays off
  /// instead of throwing on every build.
  static bool _unsupported = false;

  static FragmentShader? get shader => _shader;

  static bool get isReady => _shader != null;

  /// Starts (or returns) the load. Never throws: resolves to whether the
  /// shader is usable.
  static Future<bool> ensureLoaded() {
    if (_shader != null) return Future.value(true);
    return _loading ??= () async {
      try {
        final program = await FragmentProgram.fromAsset(asset);
        _shader = program.fragmentShader();
        return true;
      } catch (_) {
        // Unsupported platform / compile failure: stay on plain glass.
        return false;
      }
    }();
  }

  /// Builds the refraction stage for a bar of [size] and capsule [radius],
  /// or null when the pilot is unavailable or switched off.
  static ImageFilter? filterFor(Size size, double radius) {
    final shader = _shader;
    if (shader == null || _unsupported || !GlassEffects.refractionEnabled) {
      return null;
    }
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, radius)
      ..setFloat(3, band)
      ..setFloat(4, strength);
    try {
      return ImageFilter.shader(shader);
    } catch (_) {
      // Non-Impeller backend (e.g. Skia in host tests or fallback mode):
      // degrade to plain glass permanently instead of throwing per build.
      _unsupported = true;
      return null;
    }
  }
}

/// Marks a subtree as a glass surface region. Widgets that support the glass
/// treatment (currently [CommonCard]) opt in only inside this scope, which
/// keeps the effect scoped to the surfaces that enable it (the dashboard).
///
/// A scope is *live* by default: surfaces inside it may blur the backdrop in
/// real time. Pages whose cards live inside long scrolling lists (proxies,
/// profiles, connections, tools) must use `live: false` — their cards keep
/// the glass fill, rim and radius but paint the static fill and never build
/// a [BackdropFilter] (performance discipline, T38).
class GlassScope extends InheritedWidget {
  const GlassScope({super.key, this.live = true, required super.child});

  /// Whether surfaces in this scope may use real-time backdrop blur.
  final bool live;

  static bool isActive(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GlassScope>() != null;
  }

  static bool isLive(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GlassScope>()?.live ??
        true;
  }

  @override
  bool updateShouldNotify(GlassScope oldWidget) => live != oldWidget.live;
}

/// Clips [child] to [shape], blurs the backdrop behind it and lays a top
/// specular highlight over it. When blur is degraded off, returns [child]
/// untouched (the child is expected to paint [GlassTokens.effectiveFill]).
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.shape,
    required this.tokens,
    required this.child,
    this.refractionSize,
    this.refractionRadius = 0,
  });

  final ShapeBorder shape;
  final GlassTokens tokens;
  final Widget child;

  /// When non-null and the refraction pilot is ready, the backdrop chain
  /// gains the rim-displacement stage for a capsule of this size (logical
  /// pixels) and [refractionRadius]. Only the bottom navigation bar opts in.
  final Size? refractionSize;
  final double refractionRadius;

  ImageFilter _backdropFilter() {
    var filter = ImageFilter.compose(
      outer: saturationFilter(tokens.saturation),
      inner: ImageFilter.blur(
        sigmaX: tokens.sigma,
        sigmaY: tokens.sigma,
        tileMode: TileMode.clamp,
      ),
    );
    final size = refractionSize;
    if (size != null) {
      final refraction = GlassRefraction.filterFor(size, refractionRadius);
      if (refraction != null) {
        filter = ImageFilter.compose(outer: refraction, inner: filter);
      }
    }
    return filter;
  }

  @override
  Widget build(BuildContext context) {
    if (!tokens.blur) return child;
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter(
        filter: _backdropFilter(),
        child: Stack(
          children: [
            child,
            // Specular sheen: a bright, thin mirror band hugging the top
            // that dissolves quickly (crystal, not frost).
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.14, 0.38],
                      colors: [
                        Colors.white.withValues(alpha: tokens.highlightPeak),
                        Colors.white.withValues(
                          alpha: tokens.highlightPeak * 0.3,
                        ),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Rim light: a crisp bright line along the very top edge,
            // clipped to the shape so it follows the rounded corners —
            // the refraction edge of the crystal.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1.2,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      stops: const [0, 0.5, 1],
                      colors: [
                        tokens.rim.withValues(alpha: tokens.rim.a * 0.55),
                        tokens.rim,
                        tokens.rim.withValues(alpha: tokens.rim.a * 0.55),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
