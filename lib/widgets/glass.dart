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
/// T64 full unification (2026-11-08 ruling: every level — home, sub-pages,
/// grandchild pages, dialogs, sheets — one glass material, no plain
/// surfaces mixed in): [GlassScope] is now mounted at the app root by
/// CommonScaffold, so every page's section cards resolve glass tokens;
/// pages that already mount their own scope keep their live/static
/// choice because the nearest scope wins. On top of that, round-4
/// tuning pursues real glass over the chain.14 milky frost that the
/// user rejected: the fill's own alpha drops further (Ultrathin
/// territory — the backdrop supplies the body), the blur sigma rises
/// so what shows through is a soft luminous field rather than a
/// readable copy of the content (which is also what keeps scrolling
/// text from ghosting through cards — bowel 第 5 条）, and the rim
/// plus specular peak rise so the edge reads as a refraction line.
///
/// Round 5 (T64, user real-device verdict on the round-4 build:
/// functional pass, glass 「差强人意」 — not passed): on the light
/// theme the page cards read as flat pale cards, because the app
/// background was a near-white flat fill — glass with nothing behind
/// it has nothing to refract. Two fixes, one in the backdrop and one
/// in the glass itself. (1) Every CommonScaffold page now sits on a
/// designed colour field ([GlassField]): a static gradient with soft
/// colour blooms, so every surface has something to refract; dialogs
/// and the context menu already read as glass in round 4 precisely
/// because content sat behind them. (2) The glass itself gains edge
/// definition: the rim and specular peaks rise again, the backdrop
/// saturation goes to 2.0 so refracted colour actually tints the
/// surface, static surfaces (list cards) finally paint the specular
/// sheen and a gradient rim stroke instead of a bare fill, and their
/// static fill thins (0.78–0.86) so the field tints through — the
/// field is all soft gradients, so no readable content can ghost
/// through. Fill alphas stay in the Ultrathin band; nothing goes
/// back toward the milky frost.
///
/// Round 6 (T64, user real-device correction of the round-5 build:
/// 「我要的是有主次差异」 — hierarchy, with the home page as the
/// yardstick for every page): rounds ≤ 5 read "one material
/// everywhere" as "the same glass weight everywhere", which is the
/// misunderstanding this round removes. What is unified is the
/// hierarchy system ([GlassTier]), not the weight: the primary tier
/// (a page's main card / current status / main action — the home
/// page's outbound-mode card, the nav bar's selected pill) is
/// denser, brighter and refracts harder; the secondary tier (info
/// cards, section cards, list rows) is thinner, dimmer and recedes;
/// the bar and dialog tiers sit between, weighted by their role.
/// Every visible page resolves the same four tiers, so the primary/
/// secondary contrast the home page sets is the contrast everywhere.
///
/// Round 6 addendum — the Orville language layer (user ruling,
/// 2026-11-09): liquid glass stays the material; the colour/curve
/// language leans to The Orville's UI — bright, airy, white with
/// blue-cyan, rounded curves, a soft technological glow. Absorbed
/// here at the token layer: the colour field and static body hues
/// shift from the blue/teal/VIOLET family to white + blue-cyan
/// (violet blooms replaced by azure), the rim light gains an azure
/// lean, and primary-tier cards take a larger, softer radius
/// (30 vs 24). The dark theme speaks the same language: deep
/// space blue-black with blue-cyan glow. Layout density (the airy
/// spacing) is NOT absorbed here — it is a per-page layout pass,
/// listed in the T64 round-6 receipt for a later round.
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

/// Hierarchy tier of a glass surface (round 6, T64).
///
/// The home page is the yardstick: its main card reads denser and
/// brighter than its info cards, and every other page must reproduce
/// that same contrast. [primary] is a page's main card, current
/// status or main action; [secondary] is everything that supports it
/// (info cards, section cards, secondary rows) and deliberately
/// recedes; [bar] is the bottom navigation bar (a persistent chrome
/// surface between the two, its selected pill leaning primary);
/// [dialog] is dialogs, popup menus and bottom sheets, which float
/// over real content and keep the most blur and a near-primary rim.
enum GlassTier { primary, secondary, bar, dialog }

/// Resolved liquid-glass design tokens for one surface.
class GlassTokens {
  const GlassTokens({
    required this.tier,
    required this.sigma,
    required this.fill,
    required this.staticFill,
    required this.rim,
    required this.highlightPeak,
    required this.saturation,
    required this.contour,
    this.realtime = true,
  });

  /// Hierarchy tier these tokens were resolved for (round 6).
  final GlassTier tier;

  /// Backdrop blur radius (sigmaX = sigmaY).
  final double sigma;

  /// Translucent fill used while backdrop blur is active.
  final Color fill;

  /// More opaque fill used when blur is degraded off.
  final Color staticFill;

  /// Bright rim border color (the glass edge highlight). Round 5
  /// addendum: the glint is dyed by the palette (lerped toward the
  /// scheme primary) instead of plain white — the reference fitting
  /// takes the edge light's colour from the background, not from a
  /// white overlay.
  final Color rim;

  /// Dark contour line painted just inside the rim, plus the inner
  /// shadow band under the top edge (round 5 addendum, approximated
  /// from the reference fitting: a 0.75pt dark contour outside the
  /// bevel and an inner shadow inside it carry the pane's depth;
  /// this architecture clips at the shape edge, so the contour lands
  /// immediately inside the bright rim instead of outside it).
  final Color contour;

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
    GlassTier? tier,
  }) {
    // Round 6: kinds land on their natural tier (nav bar → bar,
    // dialog family → dialog, cards → secondary); a surface claims
    // the primary tier explicitly (CommonCard.glassTier).
    final effectiveTier =
        tier ??
        switch (kind) {
          GlassKind.navigationBar => GlassTier.bar,
          GlassKind.card => GlassTier.secondary,
          GlassKind.dialog => GlassTier.dialog,
        };
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
    // Round 5, static body: blur-off surfaces cannot borrow colour from
    // the backdrop, so a neutral-grey fill at high alpha reads as a
    // flat slab (the dark profiles list was the proof). The static
    // body therefore leans toward the field's own hues — pale steel
    // blue in light, deep field blue in dark — and thins, letting the
    // field show through and tint each card where it sits.
    final staticBody = Color.lerp(
      body,
      // Orville addendum: the light static hue brightens toward
      // azure-white; the dark hue is already deep field blue.
      isLight ? const Color(0xFFDFEDF9) : const Color(0xFF16233F),
      isLight ? 0.45 : 0.55,
    )!;
    // Glint dye: the rim colour leans toward the scheme primary so
    // the edge light reads as brightened background, not white paint.
    // Orville addendum: a further lean toward sky azure, so the edge
    // light sits in the blue-cyan family on both themes.
    final rimBase = Color.lerp(
      Color.lerp(Colors.white, colorScheme.primary, 0.18)!,
      const Color(0xFF7DD3FC),
      0.15,
    )!;
    // Dark contour: faint in light (the bright field separates the
    // pane already), stronger in dark where panes need the outline.
    // Round 6: the contour joins the hierarchy — primary panes carry
    // the strongest outline, secondary panes the faintest.
    final contour = Colors.black.withValues(
      alpha: switch (effectiveTier) {
        GlassTier.primary => isLight ? 0.16 : 0.50,
        GlassTier.secondary => isLight ? 0.07 : 0.30,
        GlassTier.bar => isLight ? 0.12 : 0.45,
        GlassTier.dialog => isLight ? 0.12 : 0.45,
      },
    );
    return switch (effectiveTier) {
      // Round 6 tier table (fill / staticFill alphas are light/dark).
      // The gaps between tiers ARE the feature — the round-5 build
      // failed the user's eye because card and dialog sat within
      // 0.03 of each other. Primary steps clearly up from the
      // round-5 card values (fill 0.15–0.17 → 0.30, saturation
      // 1.6 → 1.9, rim and specular at their highest), secondary
      // steps clearly down (fill → 0.10/0.12, saturation → 1.35,
      // dimmest rim and contour) so it recedes behind the primary;
      // bar and dialog keep round-5-class weight, dialog at the
      // dense end because it floats over a dimmed barrier and real
      // content (and keeps the most blur, sigma 13 — the round-5
      // reference fitting: heavy blur is what frosted plastic does,
      // so no tier goes back to the round-4 14–16 band).
      GlassTier.primary => GlassTokens(
        tier: effectiveTier,
        sigma: 12,
        fill: body.withValues(alpha: isLight ? 0.30 : 0.30),
        staticFill: staticBody.withValues(alpha: isLight ? 0.88 : 0.86),
        rim: rimBase.withValues(alpha: isLight ? 1.0 : 0.72),
        highlightPeak: isLight ? 0.68 : 0.50,
        saturation: 1.9,
        contour: contour,
        realtime: realtime,
      ),
      GlassTier.secondary => GlassTokens(
        tier: effectiveTier,
        sigma: 8,
        fill: body.withValues(alpha: isLight ? 0.10 : 0.12),
        staticFill: staticBody.withValues(alpha: isLight ? 0.62 : 0.56),
        rim: rimBase.withValues(alpha: isLight ? 0.80 : 0.42),
        highlightPeak: isLight ? 0.36 : 0.22,
        saturation: 1.35,
        contour: contour,
        realtime: realtime,
      ),
      GlassTier.bar => GlassTokens(
        tier: effectiveTier,
        sigma: 11,
        fill: body.withValues(alpha: isLight ? 0.20 : 0.22),
        staticFill: staticBody.withValues(alpha: 0.80),
        rim: rimBase.withValues(alpha: isLight ? 1.0 : 0.62),
        highlightPeak: isLight ? 0.60 : 0.42,
        saturation: 1.7,
        contour: contour,
        realtime: realtime,
      ),
      GlassTier.dialog => GlassTokens(
        tier: effectiveTier,
        sigma: 13,
        fill: body.withValues(alpha: isLight ? 0.22 : 0.23),
        staticFill: staticBody.withValues(alpha: isLight ? 0.84 : 0.82),
        rim: rimBase.withValues(alpha: isLight ? 0.98 : 0.60),
        highlightPeak: isLight ? 0.55 : 0.36,
        saturation: 1.6,
        contour: contour,
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

/// Clips [child] to [shape], blurs the backdrop behind it (live
/// surfaces only) and lays the specular sheen and rim light over it.
/// When blur is degraded off the child is expected to paint
/// [GlassTokens.effectiveFill]; the light layers still apply
/// (round 5).
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
    // Round 5: the decorative glass layers (specular sheen, top rim
    // light, gradient rim stroke) are painted in BOTH modes — only
    // the BackdropFilter is live-only. In rounds ≤ 4 a static surface
    // returned its child untouched, so list cards carried the glass
    // fill and hairline but none of the light play, which is half of
    // why they read as flat pale cards on the real device. The
    // overlays are static gradients — no backdrop sampling, no
    // per-frame cost beyond the card's own repaint.
    final content = Stack(
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
        // Inner shadow: a soft dark band just under the top edge —
        // the pane's thickness shadow inside the bevel (reference
        // fitting). Static gradient, clipped to the shape.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 18,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    tokens.contour.withValues(alpha: tokens.contour.a * 0.55),
                    tokens.contour.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Gradient rim stroke: a full-perimeter edge light, brightest
        // at the top and dissolving toward the bottom — the refraction
        // edge of the pane, with the dark contour line beneath it.
        // Painted (not a BorderSide) so the stroke itself can carry
        // the gradient.
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GlassRimPainter(
                shape: shape,
                rim: tokens.rim,
                contour: tokens.contour,
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
    );
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: tokens.blur
          ? BackdropFilter(filter: _backdropFilter(), child: content)
          : content,
    );
  }
}

/// Strokes [shape]'s outline twice: first the dark [contour] line
/// (wider, so a hairline of it survives inside the bright stroke),
/// then the rim-light gradient — full rim brightness at the top
/// edge, dissolving down the sides. The outer halves of both strokes
/// are clipped away by [GlassSurface]'s ClipPath, leaving clean
/// inner edge lines.
class _GlassRimPainter extends CustomPainter {
  const _GlassRimPainter({
    required this.shape,
    required this.rim,
    required this.contour,
  });

  final ShapeBorder shape;
  final Color rim;
  final Color contour;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect);
    final contourPaint = Paint()
      ..color = contour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawPath(path, contourPaint);
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0, 0.35, 1],
      colors: [
        rim,
        rim.withValues(alpha: rim.a * 0.5),
        rim.withValues(alpha: rim.a * 0.26),
      ],
    ).createShader(rect);
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GlassRimPainter oldDelegate) {
    return shape != oldDelegate.shape ||
        rim != oldDelegate.rim ||
        contour != oldDelegate.contour;
  }
}

/// The designed colour field every glass page sits on (round 5).
///
/// Glass needs something behind it to refract: over the old flat
/// near-white scaffold colour the light-theme cards had no backdrop
/// content at all and collapsed into flat pale cards, while dialogs
/// floating over real content read as glass immediately. This field
/// is the missing content — a quiet base gradient with soft colour
/// blooms in the project's blue/teal/violet family, identical in
/// spirit across both themes (pale blue-white by day, deep navy-black
/// by night).
///
/// It is strictly static: one CustomPaint inside a RepaintBoundary,
/// painted once and cached as a layer; scrolling content above it
/// never repaints it, and it carries no text or sharp shapes, so
/// nothing readable can ghost through a glass surface (bowel 第 5 条）.
class GlassField extends StatelessWidget {
  const GlassField({super.key, required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GlassFieldPainter(brightness),
        size: Size.infinite,
      ),
    );
  }
}

class _GlassFieldPainter extends CustomPainter {
  const _GlassFieldPainter(this.brightness);

  final Brightness brightness;

  /// One soft colour bloom: centre and radius as fractions of the
  /// field's width/height, colour with its peak alpha baked in.
  static const _lightBlooms = <(double, double, double, Color)>[
    // Sky blue, top right — the dominant daylight bloom.
    (0.88, 0.04, 0.95, Color(0x4D5EA0FF)),
    // Brand teal, mid left.
    (0.0, 0.36, 0.75, Color(0x2B14B8A6)),
    // Azure, lower right (Orville addendum: replaces the round-5
    // violet bloom — the field now speaks white + blue-cyan only).
    (0.98, 0.70, 0.85, Color(0x2E60A5FA)),
    // Cyan, bottom left.
    (0.04, 0.98, 0.80, Color(0x2938BDF8)),
  ];

  static const _darkBlooms = <(double, double, double, Color)>[
    // Deep blue, top right.
    (0.90, 0.03, 1.0, Color(0x522563EB)),
    // Teal, mid left.
    (0.0, 0.38, 0.80, Color(0x330D9488)),
    // Blue, lower right (Orville addendum: replaces violet — deep
    // space blue-black with blue-cyan glow, same language as light).
    (0.98, 0.72, 0.90, Color(0x2F3B82F6)),
    // Cyan, bottom left.
    (0.06, 1.0, 0.85, Color(0x260EA5E9)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final isLight = brightness == Brightness.light;
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isLight
            // Orville addendum: the daylight base brightens a step
            // toward white; the night base is unchanged deep space
            // blue-black.
            ? const [Color(0xFFFCFDFE), Color(0xFFEDF3FA)]
            : const [Color(0xFF04060C), Color(0xFF0A1220)],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);
    for (final (fx, fy, fr, color) in isLight ? _lightBlooms : _darkBlooms) {
      final circle = Rect.fromCircle(
        center: Offset(size.width * fx, size.height * fy),
        radius: size.width * fr,
      );
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(circle);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_GlassFieldPainter oldDelegate) {
    return brightness != oldDelegate.brightness;
  }
}
