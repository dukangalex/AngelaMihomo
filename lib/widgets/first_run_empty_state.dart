// Lucian UX/UI Prompt #440 · MIT License
//
// First-run empty state, ported from the #440 interaction spec
// (angela-uxui): an illustration bobs gently in the air (3.2s
// ease-in-out float, its ground shadow breathing with it), sparkles
// twinkle around it in staggered 2.4s cycles, and a pill call to
// action waits below the headline. The artwork is drawn in this
// app's own constellation idiom — a star chart with a document
// rising over it — not the source element's folder graphic.
//
// The source element's drop-in celebration plays when the first
// item is created in place; here the call to action opens the add
// flow instead, so the float / twinkle / press-spring parts of the
// spec are the ones that land.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'lucian_tokens.dart';

class FirstRunEmptyState extends StatefulWidget {
  final String title;
  final String? description;
  final String ctaLabel;
  final VoidCallback onCta;

  const FirstRunEmptyState({
    super.key,
    required this.title,
    required this.ctaLabel,
    required this.onCta,
    this.description,
  });

  @override
  State<FirstRunEmptyState> createState() => _FirstRunEmptyStateState();
}

class _FirstRunEmptyStateState extends State<FirstRunEmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _twinkle;
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (lucianReducedMotion(context)) {
        _float.value = 0.5;
      } else {
        _float.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _float.dispose();
    _twinkle.dispose();
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_float, _twinkle]),
              builder: (context, _) {
                final lift = Curves.easeInOut.transform(_float.value);
                return Transform.translate(
                  offset: Offset(0, -6 * lift),
                  child: CustomPaint(
                    size: const Size(176, 132),
                    painter: _ConstellationPainter(
                      accent: colorScheme.primary,
                      accentSoft: colorScheme.primary.withValues(alpha: 0.38),
                      surface: colorScheme.surface,
                      line: colorScheme.outlineVariant,
                      mint: lucianMint(context),
                      warn: lucianWarn(context),
                      shadowAlpha: 0.08 - 0.03 * lift,
                      shadowScale: 1 - 0.14 * lift,
                      twinkle: _twinkle.value,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            if (widget.description != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.description!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            GestureDetector(
              onTapDown: (_) => _press.animateTo(
                0.94,
                duration: const Duration(milliseconds: 100),
                curve: lucianEase,
              ),
              onTapUp: (_) {
                _press.animateTo(
                  1,
                  duration: const Duration(milliseconds: 450),
                  curve: const Cubic(0.34, 1.7, 0.5, 1),
                );
                widget.onCta();
              },
              onTapCancel: () => _press.animateTo(
                1,
                duration: const Duration(milliseconds: 450),
                curve: const Cubic(0.34, 1.7, 0.5, 1),
              ),
              child: AnimatedBuilder(
                animation: _press,
                builder: (context, child) =>
                    Transform.scale(scale: _press.value, child: child),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.5),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                        spreadRadius: -12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 15, color: colorScheme.onPrimary),
                      const SizedBox(width: 7),
                      Text(
                        widget.ctaLabel,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

/// Constellation chart + document artwork in the app's own idiom:
/// linked stars over a soft folder base, a document card with a
/// mint header bar, and three twinkling four-point sparkles.
class _ConstellationPainter extends CustomPainter {
  final Color accent;
  final Color accentSoft;
  final Color surface;
  final Color line;
  final Color mint;
  final Color warn;
  final double shadowAlpha;
  final double shadowScale;
  final double twinkle;

  const _ConstellationPainter({
    required this.accent,
    required this.accentSoft,
    required this.surface,
    required this.line,
    required this.mint,
    required this.warn,
    required this.shadowAlpha,
    required this.shadowScale,
    required this.twinkle,
  });

  void _sparkle(Canvas canvas, Offset center, double r, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  double _twinkleScale(int index) {
    final phase = (twinkle + index / 3) % 1.0;
    return 0.6 + 0.4 * math.sin(phase * math.pi);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 160;
    final sy = size.height / 120;
    canvas.save();
    canvas.scale(sx, sy);
    // Ground shadow (breathes against the float).
    canvas.save();
    canvas.translate(80, 116);
    canvas.scale(shadowScale, 1);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 100, height: 10),
      Paint()..color = Colors.black.withValues(alpha: shadowAlpha),
    );
    canvas.restore();
    // Folder base: soft back plate + accent front plate.
    final back = RRect.fromRectAndRadius(
      const Rect.fromLTWH(28, 26, 104, 82),
      const Radius.circular(8),
    );
    canvas.drawRRect(back, Paint()..color = accentSoft);
    final front = Path()
      ..moveTo(22, 56)
      ..quadraticBezierTo(22, 48, 30, 48)
      ..lineTo(130, 48)
      ..quadraticBezierTo(138, 48, 138, 57)
      ..lineTo(133.6, 100)
      ..quadraticBezierTo(133, 108, 125, 108)
      ..lineTo(34, 108)
      ..quadraticBezierTo(27, 108, 26.4, 100)
      ..close();
    canvas.drawPath(front, Paint()..color = accent);
    canvas.drawPath(
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(22, 48, 116, 12),
          const Radius.circular(6),
        ),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
    // Document card with mint header + text lines.
    final doc = RRect.fromRectAndRadius(
      const Rect.fromLTWH(50, 24, 60, 58),
      const Radius.circular(6),
    );
    canvas.drawRRect(doc, Paint()..color = surface);
    canvas.drawRRect(
      doc,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(57, 31, 20, 5),
        const Radius.circular(2.5),
      ),
      Paint()..color = mint,
    );
    for (final (y, w) in [(42.0, 44.0), (50.0, 36.0)]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(57, y, w, 3.5),
          const Radius.circular(1.75),
        ),
        Paint()..color = line,
      );
    }
    // Constellation: linked stars across the top.
    const stars = [
      Offset(36, 18),
      Offset(66, 8),
      Offset(96, 16),
      Offset(122, 6),
    ];
    final linkPaint = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final link = Path()..moveTo(stars.first.dx, stars.first.dy);
    for (final star in stars.skip(1)) {
      link.lineTo(star.dx, star.dy);
    }
    canvas.drawPath(link, linkPaint);
    for (final star in stars) {
      canvas.drawCircle(star, 2.2, Paint()..color = accent);
    }
    // Twinkling sparkles, staggered a third of a cycle apart.
    final sparkles = [
      (const Offset(138, 22), 5.0, warn, 0),
      (const Offset(20, 40), 4.0, mint, 1),
      (const Offset(128, 70), 3.0, accent, 2),
    ];
    for (final (center, r, color, index) in sparkles) {
      final scale = _twinkleScale(index);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale, scale);
      _sparkle(
        canvas,
        Offset.zero,
        r,
        color.withValues(alpha: 0.35 + 0.65 * scale),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) =>
      oldDelegate.twinkle != twinkle ||
      oldDelegate.shadowAlpha != shadowAlpha ||
      oldDelegate.accent != accent;
}
