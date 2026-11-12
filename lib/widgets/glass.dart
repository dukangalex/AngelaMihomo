import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show BackdropFilterLayer;
import 'package:material_ui/material_ui.dart';

/// Liquid glass material system (T83/T64/T82).
///
/// Structure over parameters: the face stays clear (no full-face blur,
/// which is what read as frosted / milky / foggy on real devices), and
/// refraction lives only in a narrow edge bevel band rendered by
/// [shaders/glass_refraction.frag]. Hierarchy is one scale for the whole
/// app, taken from the home page: the primary layer is more solid,
/// brighter and refracts harder; the secondary layer is clearer and
/// recedes; bar and dialog sit at their own tiers.
///
/// Tint follows the current theme color (T82): hue comes from
/// [ColorScheme.primary], with saturation / lightness clamped so tier
/// deltas never collapse. Under the default azure theme this reproduces
/// the Orville reference form (white + blue-cyan, soft tech glow).
enum GlassTier { primary, secondary, bar, dialog }

/// Where a surface sits in the hierarchy. The home page is the ruler.
class GlassTokens {
  /// Bevel band width scale, relative to the 8px crystal baseline.
  final double bandScale;

  /// Max backdrop displacement in the bevel band (px).
  final double strength;

  /// Face tint alpha (kept near zero; the face must stay clear).
  final double faceTintAlpha;

  /// Rim bright-line strength.
  final double rimAlpha;

  /// Diagonal sheen film strength.
  final double sheen;

  /// Crystal lift applied to the sampled backdrop.
  final double contrast;
  final double saturate;
  final double bright;

  /// Static (non-backdrop) rendering: how far the surface color is dyed
  /// toward the tint, and at what alpha it is painted.
  final double staticDye;
  final double staticFillAlpha;
  final double staticRimAlpha;

  const GlassTokens({
    required this.bandScale,
    required this.strength,
    required this.faceTintAlpha,
    required this.rimAlpha,
    required this.sheen,
    required this.contrast,
    required this.saturate,
    required this.bright,
    required this.staticDye,
    required this.staticFillAlpha,
    required this.staticRimAlpha,
  });

  static const double baseBand = 8.0;

  factory GlassTokens.of(GlassTier tier, Brightness brightness) {
    final light = brightness == Brightness.light;
    return switch (tier) {
      GlassTier.primary => GlassTokens(
        bandScale: 1.0,
        strength: 13,
        faceTintAlpha: light ? 0.05 : 0.07,
        rimAlpha: light ? 0.95 : 0.85,
        sheen: 0.85,
        contrast: 1.14,
        saturate: 1.12,
        bright: 0.015,
        staticDye: light ? 0.45 : 0.50,
        staticFillAlpha: light ? 0.88 : 0.86,
        staticRimAlpha: light ? 0.85 : 0.65,
      ),
      GlassTier.secondary => GlassTokens(
        bandScale: 0.8,
        strength: 9,
        faceTintAlpha: light ? 0.03 : 0.045,
        rimAlpha: light ? 0.62 : 0.50,
        sheen: 0.35,
        contrast: 1.08,
        saturate: 1.06,
        bright: 0.008,
        staticDye: 0.18,
        staticFillAlpha: light ? 0.56 : 0.50,
        staticRimAlpha: light ? 0.50 : 0.40,
      ),
      GlassTier.bar => GlassTokens(
        bandScale: 0.9,
        strength: 11,
        faceTintAlpha: light ? 0.04 : 0.06,
        rimAlpha: light ? 0.90 : 0.80,
        sheen: 0.60,
        contrast: 1.12,
        saturate: 1.10,
        bright: 0.012,
        staticDye: 0.30,
        staticFillAlpha: 0.92,
        staticRimAlpha: light ? 0.70 : 0.60,
      ),
      GlassTier.dialog => GlassTokens(
        bandScale: 0.95,
        strength: 12,
        faceTintAlpha: light ? 0.045 : 0.06,
        rimAlpha: light ? 0.92 : 0.82,
        sheen: 0.70,
        contrast: 1.12,
        saturate: 1.10,
        bright: 0.012,
        staticDye: 0.30,
        staticFillAlpha: light ? 0.90 : 0.88,
        staticRimAlpha: light ? 0.65 : 0.55,
      ),
    };
  }
}

/// Theme-following glass colors (T82). Only the hue follows the theme;
/// tier structure, glow and spacing never change with color.
class GlassTint {
  /// Near-clear face tint color.
  final Color face;

  /// Rim light / glow color.
  final Color rim;

  const GlassTint({required this.face, required this.rim});

  factory GlassTint.resolve(ColorScheme scheme) {
    final hsl = HSLColor.fromColor(scheme.primary);
    // Clamp inside the accepted band with headroom for the RGB
    // round-trip, so a re-derived HSL never drifts past the limits.
    final saturation = hsl.saturation.clamp(0.47, 0.88);
    final light = scheme.brightness == Brightness.light;
    final rim = hsl
        .withSaturation(saturation)
        .withLightness((light ? 0.60 : 0.68).clamp(0.55, 0.75))
        .toColor();
    final face = hsl
        .withSaturation(saturation * 0.85)
        .withLightness(light ? 0.72 : 0.32)
        .toColor();
    return GlassTint(face: face, rim: rim);
  }
}

/// Marks a subtree whose glass surfaces render live (real backdrop
/// refraction). Surfaces outside a live scope render the static variant,
/// which keeps long lists cheap and static scenes at zero redraw cost.
class GlassScope extends InheritedWidget {
  final bool live;

  const GlassScope({super.key, required this.live, required super.child});

  static bool liveOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GlassScope>()?.live ??
        false;
  }

  @override
  bool updateShouldNotify(GlassScope oldWidget) => live != oldWidget.live;
}

class GlassShaders {
  static Future<ui.FragmentProgram>? _program;

  static Future<ui.FragmentProgram> load() {
    return _program ??= ui.FragmentProgram.fromAsset(
      'shaders/glass_refraction.frag',
    );
  }
}

/// One glass surface. Renders the shader bevel refraction when live and
/// the shader is available; otherwise (and while it loads) renders the
/// static painter with the same tier tokens, so a surface never flashes
/// black or falls back to a frosted blur.
class GlassSurface extends StatefulWidget {
  final GlassTier tier;
  final double radius;
  final ShapeBorder? clipShape;
  final bool? live;
  final Widget? child;

  /// Optional drop shadow for floating surfaces (popups, dialogs),
  /// painted outside the clip.
  final List<BoxShadow>? boxShadow;

  const GlassSurface({
    super.key,
    required this.tier,
    this.radius = 20,
    this.clipShape,
    this.live,
    this.child,
    this.boxShadow,
  });

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<GlassSurface> {
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    unawaited(
      GlassShaders.load()
          .then((program) {
            if (!mounted) return;
            setState(() => _shader = program.fragmentShader());
          })
          .catchError((_) {
            // Shader unavailable (non-Impeller, headless tests): the
            // static painter below is the permanent fallback.
          }),
    );
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  ShapeBorder get _shape =>
      widget.clipShape ??
      RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(widget.radius),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = GlassTint.resolve(scheme);
    final tokens = GlassTokens.of(widget.tier, scheme.brightness);
    final live = widget.live ?? GlassScope.liveOf(context);
    final clipped = ClipPath(
      clipper: _ShapeClipper(_shape),
      child: Stack(
        children: [
          Positioned.fill(
            child: _GlassBackdrop(
              shader: live ? _shader : null,
              radius: widget.radius,
              shape: _shape,
              tokens: tokens,
              tint: tint,
              baseColor: scheme.surface,
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
    final shadow = widget.boxShadow;
    if (shadow == null || shadow.isEmpty) return clipped;
    return DecoratedBox(
      decoration: ShapeDecoration(shape: _shape, shadows: shadow),
      child: clipped,
    );
  }
}

class _ShapeClipper extends CustomClipper<Path> {
  final ShapeBorder shape;

  const _ShapeClipper(this.shape);

  @override
  Path getClip(Size size) => shape.getOuterPath(Offset.zero & size);

  @override
  bool shouldReclip(_ShapeClipper oldClipper) => shape != oldClipper.shape;
}

/// Static glass: dyed translucent fill, an uneven rim stroke (brightest
/// at the top) and the same diagonal sheen film, without sampling the
/// backdrop. Used for list surfaces and as the shader fallback.
class _StaticGlassPainter extends CustomPainter {
  final ShapeBorder shape;
  final GlassTokens tokens;
  final GlassTint tint;
  final Color baseColor;

  const _StaticGlassPainter({
    required this.shape,
    required this.tokens,
    required this.tint,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect);
    final fill = Color.lerp(
      baseColor,
      tint.face,
      tokens.staticDye,
    )!.withValues(alpha: tokens.staticFillAlpha);
    canvas.drawPath(path, Paint()..color = fill);

    canvas.save();
    canvas.clipPath(path);
    // Diagonal sheen film.
    final sheenRect = rect.inflate(1);
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: tokens.sheen * 0.10),
          Colors.transparent,
        ],
        stops: const [0.25, 0.46, 0.67],
      ).createShader(sheenRect);
    canvas.drawRect(sheenRect, sheenPaint);
    // Top light wash.
    final topPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: tokens.sheen * 0.07),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45],
      ).createShader(rect);
    canvas.drawRect(rect, topPaint);
    canvas.restore();

    // Uneven rim: brightest at the top, fading downward.
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          tint.rim.withValues(alpha: tokens.staticRimAlpha),
          tint.rim.withValues(alpha: tokens.staticRimAlpha * 0.4),
        ],
      ).createShader(rect);
    canvas.drawPath(path, rimPaint);
  }

  @override
  bool shouldRepaint(_StaticGlassPainter oldDelegate) {
    return oldDelegate.tokens != tokens ||
        oldDelegate.tint.face != tint.face ||
        oldDelegate.tint.rim != tint.rim ||
        oldDelegate.baseColor != baseColor;
  }
}

/// The application color field behind glass surfaces: a brightened
/// blue-white base (deep blue-black in dark), a sky halo at the top and
/// a horizontal bright band, so glass always has light to refract.
/// Halo colors are the landed field tokens (light azure / dark blue).
class GlassField extends StatelessWidget {
  const GlassField({super.key});

  static const Color haloLight = Color(0x2E60A5FA);
  static const Color haloDark = Color(0x2F3B82F6);

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GlassFieldPainter(isLight: isLight),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GlassFieldPainter extends CustomPainter {
  final bool isLight;

  const _GlassFieldPainter({required this.isLight});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isLight
            ? const [Color(0xFFEDF3FA), Color(0xFFF4F8FC), Color(0xFFFAFCFE)]
            : const [Color(0xFF04070F), Color(0xFF071120), Color(0xFF0A1729)],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    void blob(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    // Top-center sky halo.
    blob(
      Offset(size.width * 0.5, -size.height * 0.12),
      size.width * 1.15,
      isLight ? const Color(0x4760A5FA) : const Color(0x403B82F6),
    );
    // Side glows in the landed token colors.
    blob(
      Offset(size.width * 0.10, size.height * 0.30),
      size.width * 0.55,
      isLight ? GlassField.haloLight : GlassField.haloDark,
    );
    blob(
      Offset(size.width * 0.92, size.height * 0.10),
      size.width * 0.5,
      isLight ? const Color(0x2E38BDF8) : const Color(0x1F38BDF8),
    );

    // Horizontal bright band under the halo.
    final bandRect = Rect.fromLTRB(
      0,
      size.height * 0.06,
      size.width,
      size.height * 0.38,
    );
    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          (isLight ? const Color(0xFFCDE9FF) : const Color(0xFF7DD3FC))
              .withValues(alpha: isLight ? 0.38 : 0.16),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(bandRect);
    canvas.drawRect(bandRect, bandPaint);
  }

  @override
  bool shouldRepaint(_GlassFieldPainter oldDelegate) =>
      isLight != oldDelegate.isLight;
}

/// The painted glass layer of a [GlassSurface].
///
/// A leaf render object rather than a LayoutBuilder: intrinsically
/// sized parents (popup menus, some dialog routes) ask children for
/// intrinsic dimensions, which a LayoutBuilder cannot answer. Here the
/// exact size is known at paint time, which is also when the shader
/// uniforms are configured, so resizing surfaces (expanding sheets)
/// never lag a frame.
class _GlassBackdrop extends LeafRenderObjectWidget {
  final ui.FragmentShader? shader;
  final double radius;
  final ShapeBorder shape;
  final GlassTokens tokens;
  final GlassTint tint;
  final Color baseColor;

  const _GlassBackdrop({
    required this.shader,
    required this.radius,
    required this.shape,
    required this.tokens,
    required this.tint,
    required this.baseColor,
  });

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderGlassBackdrop(
    shader: shader,
    radius: radius,
    shape: shape,
    tokens: tokens,
    tint: tint,
    baseColor: baseColor,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderGlassBackdrop renderObject,
  ) {
    renderObject
      ..shader = shader
      ..radius = radius
      ..shape = shape
      ..tokens = tokens
      ..tint = tint
      ..baseColor = baseColor;
  }
}

class _RenderGlassBackdrop extends RenderBox {
  _RenderGlassBackdrop({
    required ui.FragmentShader? shader,
    required double radius,
    required ShapeBorder shape,
    required GlassTokens tokens,
    required GlassTint tint,
    required Color baseColor,
  }) : _shader = shader,
       _radius = radius,
       _shape = shape,
       _tokens = tokens,
       _tint = tint,
       _baseColor = baseColor;

  ui.FragmentShader? _shader;
  set shader(ui.FragmentShader? value) {
    if (value == _shader) return;
    final wasLive = _shader != null;
    _shader = value;
    if ((value != null) != wasLive) markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  double _radius;
  set radius(double value) {
    if (value == _radius) return;
    _radius = value;
    markNeedsPaint();
  }

  ShapeBorder _shape;
  set shape(ShapeBorder value) {
    if (value == _shape) return;
    _shape = value;
    markNeedsPaint();
  }

  GlassTokens _tokens;
  set tokens(GlassTokens value) {
    if (identical(value, _tokens)) return;
    _tokens = value;
    markNeedsPaint();
  }

  GlassTint _tint;
  set tint(GlassTint value) {
    if (identical(value, _tint)) return;
    _tint = value;
    markNeedsPaint();
  }

  Color _baseColor;
  set baseColor(Color value) {
    if (value == _baseColor) return;
    _baseColor = value;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool get alwaysNeedsCompositing => _shader != null;

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  /// Set once [ui.ImageFilter.shader] proves unsupported (software /
  /// non-Impeller renderers throw at filter creation): the static
  /// painter is the permanent fallback there, never a crash.
  bool _shaderUnsupported = false;

  void _paintStatic(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _StaticGlassPainter(
      shape: _shape,
      tokens: _tokens,
      tint: _tint,
      baseColor: _baseColor,
    ).paint(canvas, size);
    canvas.restore();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final shader = _shader;
    if (shader == null || size.isEmpty || _shaderUnsupported) {
      _paintStatic(context, offset);
      return;
    }
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, _radius)
      ..setFloat(3, _tint.face.r)
      ..setFloat(4, _tint.face.g)
      ..setFloat(5, _tint.face.b)
      ..setFloat(6, _tokens.faceTintAlpha)
      ..setFloat(7, _tint.rim.r)
      ..setFloat(8, _tint.rim.g)
      ..setFloat(9, _tint.rim.b)
      ..setFloat(10, GlassTokens.baseBand * _tokens.bandScale)
      ..setFloat(11, _tokens.strength)
      ..setFloat(12, _tokens.sheen)
      ..setFloat(13, _tokens.rimAlpha)
      ..setFloat(14, _tokens.contrast)
      ..setFloat(15, _tokens.saturate)
      ..setFloat(16, _tokens.bright);
    final ui.ImageFilter filter;
    try {
      filter = ui.ImageFilter.shader(shader);
    } on UnsupportedError {
      _shaderUnsupported = true;
      _paintStatic(context, offset);
      return;
    }
    layer ??= BackdropFilterLayer();
    layer!.filter = filter;
    context.pushLayer(layer!, (context, offset) {}, offset);
  }
}
