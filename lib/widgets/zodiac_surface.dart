import 'dart:ui';

import 'package:bett_box/common/zodiac_theme.dart';
import 'package:material_ui/material_ui.dart';

/// Which surface role a [ZodiacSurface] plays; the radius comes
/// from the active skeleton's material parameters.
enum ZodiacTone { panel, card, group, dialog, navBar }

/// The family's single surface widget (T115). It replaces the
/// chain.22 glass system wholesale: fill, border, radius and shadow
/// all derive from the active constellation tokens, so no two
/// visual systems ever share a screen.
///
/// Frameless skeletons (Eastern whitespace / plain paper) render
/// the child undecorated — surfaces there are typographic, divided
/// by hairlines owned by the parents. Dialogs stay opaque in every
/// skeleton.
class ZodiacSurface extends StatelessWidget {
  final ZodiacTone tone;
  final double? radius;

  /// Full border-radius override (e.g. top-only for bottom sheets);
  /// wins over [radius] and the skeleton default.
  final BorderRadius? borderRadius;

  /// Shadow override for hosts with their own tuned elevation
  /// (the bottom navigation bar).
  final List<BoxShadow>? boxShadow;
  final bool selected;
  final Widget child;

  const ZodiacSurface({
    super.key,
    this.tone = ZodiacTone.card,
    this.radius,
    this.borderRadius,
    this.boxShadow,
    this.selected = false,
    required this.child,
  });

  double _radiusFor(ZodiacSkeletonSpec spec) {
    if (radius != null) return radius!;
    return switch (tone) {
      ZodiacTone.panel => spec.panelRadius,
      ZodiacTone.card => spec.smallRadius,
      ZodiacTone.group => spec.groupRadius,
      ZodiacTone.dialog => spec.frameless ? 20 : spec.panelRadius,
      ZodiacTone.navBar => 30,
    };
  }

  Color _fillFor(ZodiacPalette palette) {
    return switch (tone) {
      ZodiacTone.dialog => palette.dialogSurface,
      ZodiacTone.navBar => palette.navBar,
      _ => palette.surface,
    };
  }

  List<BoxShadow> _shadowsFor(ZodiacThemeExtension z) {
    if (boxShadow != null) return boxShadow!;
    final spec = z.spec;
    final palette = z.palette;
    if (tone == ZodiacTone.dialog) {
      return const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ];
    }
    final shadows = <BoxShadow>[];
    if (spec.hardShadow) {
      shadows.add(
        BoxShadow(
          color: palette.outline,
          blurRadius: 0,
          offset: Offset(0, tone == ZodiacTone.panel ? 6 : 5),
        ),
      );
    } else if (spec.softShadow) {
      shadows.add(
        BoxShadow(
          color: const Color(0x120F172A),
          blurRadius: tone == ZodiacTone.panel ? 26 : 20,
          offset: Offset(0, tone == ZodiacTone.panel ? 12 : 8),
        ),
      );
    }
    if (z.neon) {
      shadows.add(
        BoxShadow(
          color: palette.primary.withValues(alpha: 0.18),
          blurRadius: 14,
        ),
      );
    }
    if (selected && palette.glow != null) {
      shadows.add(
        BoxShadow(color: palette.glow!, blurRadius: 24, spreadRadius: -4),
      );
    }
    return shadows;
  }

  @override
  Widget build(BuildContext context) {
    final z = context.zodiac;
    final spec = z.spec;
    final palette = z.palette;
    if (spec.frameless && tone != ZodiacTone.dialog) {
      return child;
    }
    final br = borderRadius ?? BorderRadius.circular(_radiusFor(spec));
    final borderWidth = spec.borderWidth == 0 ? 1.0 : spec.borderWidth;
    final decoration = BoxDecoration(
      color: _fillFor(palette),
      borderRadius: br,
      border: Border.all(
        color: selected ? palette.primary : palette.outline,
        width: selected
            ? borderWidth.clamp(1.5, double.infinity).toDouble()
            : borderWidth,
      ),
      boxShadow: _shadowsFor(z),
    );
    Widget body = child;
    // Translucent skeletons frost the large surfaces (panels and
    // dialogs); smaller surfaces sit over the static backdrop
    // gradient, where the same tint reads identically without the
    // per-frame blur cost.
    if (spec.translucent &&
        (tone == ZodiacTone.panel || tone == ZodiacTone.dialog)) {
      body = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: body,
      );
    }
    return DecoratedBox(
      decoration: decoration,
      child: ClipRRect(borderRadius: br, child: body),
    );
  }
}

/// The page backdrop of the family: the variant's background
/// gradient plus its radial atmosphere glows, painted once behind
/// the content by a single custom painter.
class ZodiacBackdrop extends StatelessWidget {
  const ZodiacBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.zodiac.palette;
    return CustomPaint(
      painter: _ZodiacBackdropPainter(palette),
      size: Size.infinite,
    );
  }
}

class _ZodiacBackdropPainter extends CustomPainter {
  final ZodiacPalette palette;

  const _ZodiacBackdropPainter(this.palette);

  void _halo(Canvas canvas, Offset center, double radius, Color color) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()..shader = palette.bgGradient.createShader(rect);
    canvas.drawRect(rect, bgPaint);
    if (palette.haloPrimary != null) {
      _halo(canvas, Offset(size.width - 90, -40), 190, palette.haloPrimary!);
    }
    if (palette.haloSecondary != null) {
      _halo(canvas, const Offset(50, 470), 170, palette.haloSecondary!);
    }
  }

  @override
  bool shouldRepaint(_ZodiacBackdropPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
