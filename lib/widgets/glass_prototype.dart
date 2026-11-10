import 'dart:ui';

import 'package:bett_box/widgets/glass.dart';
import 'package:material_ui/material_ui.dart';

/// T83 prototype — shader edge-refraction glass (parallel to, NOT a
/// replacement of, the current [GlassSurface] implementation).
///
/// Rationale (T64 rounds 5/6/7 all failed the user's real-device
/// verdict «液态玻璃感还是不够透亮、晶莹»): the current glass blurs
/// the whole face, which is frosted glass by construction. The
/// research verdict behind this prototype: real liquid glass keeps
/// the face clear and refracts only at the bevel. This file pairs a
/// fragment shader (shaders/glass_edge_refraction.frag) that samples
/// the backdrop nearly as-is on the face and bends sampling only in
/// the rim band, with the same light overlays the current surface
/// paints (specular sheen, top inner shadow, gradient rim, rim line)
/// so the ONLY structural difference under comparison is the face
/// treatment.
///
/// Scope discipline: this prototype is wired to exactly one surface —
/// the home page's main status card (the outbound-mode card, both
/// dashboard layouts) — via CommonCard's `shaderGlass` opt-in. Every
/// other surface keeps the current glass, which is also the fallback:
/// if the shader cannot load or the filter cannot be built
/// (non-Impeller backend), the surface renders exactly as the
/// current [GlassSurface] does. Never a black pane, never a crash.
abstract final class GlassPrototype {
  /// Master switch for the prototype surfaces. Local validation
  /// builds only — the full rollout decision is the user's, after
  /// the side-by-side comparison.
  static bool enabled = true;
}

/// Loader + filter factory for the edge-refraction shader.
///
/// Mirrors [GlassRefraction] (the navigation-bar pilot): best-effort
/// load, permanent degrade on failure. The parameters below are the
/// prototype's tuning and are reported with the comparison shots.
abstract final class GlassEdgeRefraction {
  static const String asset = 'shaders/glass_edge_refraction.frag';

  /// Maximum sampling displacement at the rim, logical pixels.
  static const double strength = 11;

  /// Face blur radius, logical pixels — a whisper, only enough to
  /// take the raw edge off backdrop content behind the pane. The
  /// face must stay readable-clear; this is NOT the current glass's
  /// full-face gaussian.
  static const double faceBlur = 1.1;

  /// Bevel band width for a pane of the given corner [radius]:
  /// the sloped rim of a pane scales with its rounding.
  static double bandFor(double radius) =>
      (radius * 0.85).clamp(16.0, 30.0).toDouble();

  /// Face tint alpha (the tint colour itself is the tier's dyed
  /// fill colour — azure for the primary tier). Extremely light: the
  /// pane's body comes from the backdrop, not from a fill.
  static double tintAlphaFor(Brightness brightness) =>
      brightness == Brightness.light ? 0.10 : 0.14;

  static FragmentShader? _shader;
  static Future<bool>? _loading;

  /// Set once filter creation has failed on a non-Impeller backend;
  /// the prototype then stays off instead of throwing on every build.
  static bool _unsupported = false;

  static bool get isReady => _shader != null;

  /// Starts (or returns) the load. Never throws: resolves to whether
  /// the shader is usable.
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

  /// Builds the refraction filter for a surface of [size] and corner
  /// [radius], dyed by [tint]; null when the prototype is unavailable
  /// or switched off (callers fall back to [GlassSurface]).
  static ImageFilter? filterFor({
    required Size size,
    required double radius,
    required Color tint,
  }) {
    final shader = _shader;
    if (shader == null || _unsupported || !GlassPrototype.enabled) {
      return null;
    }
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, radius)
      ..setFloat(3, bandFor(radius))
      ..setFloat(4, strength)
      ..setFloat(5, faceBlur)
      ..setFloat(6, tint.r)
      ..setFloat(7, tint.g)
      ..setFloat(8, tint.b)
      ..setFloat(9, tint.a);
    try {
      return ImageFilter.shader(shader);
    } catch (_) {
      // Non-Impeller backend (Skia): degrade to plain glass
      // permanently instead of throwing per build.
      _unsupported = true;
      return null;
    }
  }
}

/// The prototype glass surface: a clear face with bevel refraction,
/// painted by the fragment shader, with the current surface's light
/// overlays on top. Falls back to [GlassSurface] (with the fill the
/// child no longer paints itself) whenever the shader path is not
/// live — loading, failed, disabled, or the surface is static
/// ([GlassTokens.blur] false).
class PrototypeGlassSurface extends StatefulWidget {
  const PrototypeGlassSurface({
    super.key,
    required this.shape,
    required this.tokens,
    required this.radius,
    required this.child,
  });

  final ShapeBorder shape;
  final GlassTokens tokens;

  /// Corner radius of [shape]; drives the shader's bevel band.
  final double radius;

  /// The card content. Its own background is transparent in
  /// prototype mode — the pane body is the shader's backdrop sample
  /// (or, in fallback, the fill layer this surface paints beneath).
  final Widget child;

  @override
  State<PrototypeGlassSurface> createState() => _PrototypeGlassSurfaceState();
}

class _PrototypeGlassSurfaceState extends State<PrototypeGlassSurface> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    GlassEdgeRefraction.ensureLoaded().then((ok) {
      if (mounted && ok) {
        setState(() => _ready = true);
      }
    });
  }

  /// The current implementation, unchanged: [GlassSurface] plus the
  /// fill layer beneath the child (in prototype mode the child
  /// paints no fill of its own, so the fallback supplies it here).
  Widget _fallback() {
    final tokens = widget.tokens;
    return GlassSurface(
      shape: widget.shape,
      tokens: tokens,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: tokens.effectiveFill),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    if (!_ready || !tokens.blur) {
      return _fallback();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size.isEmpty || !size.isFinite) {
          return _fallback();
        }
        final fill = tokens.fill;
        final tint = Color.from(
          alpha: GlassEdgeRefraction.tintAlphaFor(
            Theme.of(context).brightness,
          ),
          red: fill.r,
          green: fill.g,
          blue: fill.b,
        );
        final filter = GlassEdgeRefraction.filterFor(
          size: size,
          radius: widget.radius,
          tint: tint,
        );
        if (filter == null) {
          return _fallback();
        }
        return ClipPath(
          clipper: ShapeBorderClipper(shape: widget.shape),
          child: Stack(
            children: [
              // The pane body: the backdrop itself, clear on the
              // face, refracted in the bevel band — painted by the
              // shader, nothing else.
              Positioned.fill(
                child: BackdropFilter(
                  filter: filter,
                  child: const SizedBox.expand(),
                ),
              ),
              widget.child,
              // Light overlays — the same set [GlassSurface] paints
              // (specular sheen, top inner shadow, gradient rim,
              // top rim line), so the comparison isolates the face
              // treatment as the only changed variable.
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
                          tokens.contour.withValues(
                            alpha: tokens.contour.a * 0.55,
                          ),
                          tokens.contour.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _PrototypeRimPainter(
                      shape: widget.shape,
                      rim: tokens.rim,
                      contour: tokens.contour,
                    ),
                  ),
                ),
              ),
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
        );
      },
    );
  }
}

/// Gradient rim stroke for the prototype surface — the same painting
/// as the current surface's rim (dark contour beneath, rim light
/// dissolving downward), duplicated here so the prototype stays
/// self-contained and the current implementation untouched.
class _PrototypeRimPainter extends CustomPainter {
  const _PrototypeRimPainter({
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
  bool shouldRepaint(_PrototypeRimPainter oldDelegate) {
    return shape != oldDelegate.shape ||
        rim != oldDelegate.rim ||
        contour != oldDelegate.contour;
  }
}
