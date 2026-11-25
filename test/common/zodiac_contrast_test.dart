import 'dart:math' as math;

import 'package:angelamihomo/common/zodiac_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T175 readability floor, raised by T177 (DESIGN doc, 2026-11-16): every theme's
/// secondary text must keep at least 5.5:1 contrast against the card
/// tone in the worst case — the surfaceVariant composited over the
/// background's lightest stop. Mirrors the guard in the token
/// generator (t117-gen-zodiac-data.py) so a future token edit cannot
/// silently regress readability.
double _luminance(Color c) {
  double f(double v) {
    final s = v / 255.0;
    return s <= 0.04045
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * f(c.r * 255) + 0.7152 * f(c.g * 255) + 0.0722 * f(c.b * 255);
}

double _contrast(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  final hi = math.max(l1, l2);
  final lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('zodiac textSecondary contrast floor (T177)', () {
    for (final def in zodiacThemeDefs) {
      for (final (name, variant) in [
        ('light', def.light),
        ('dark', def.dark),
      ]) {
        test(
          '${def.id} ($name) stays at or above 5.5:1 on its worst-case card',
          () {
            final stops = variant.background.isGradient
                ? variant.background.stops!
                : [variant.background.firstColor];
            final lightest = stops.reduce(
              (a, b) => _luminance(a) >= _luminance(b) ? a : b,
            );
            final worstCard = Color.alphaBlend(
              variant.surfaceVariant,
              lightest,
            );
            expect(
              _contrast(variant.textSecondary, worstCard),
              greaterThanOrEqualTo(5.5),
              reason:
                  '${def.id} ($name) textSecondary ${variant.textSecondary} '
                  'vs worst card $worstCard',
            );
          },
        );
      }
    }
  });
}
