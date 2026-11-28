import 'dart:math' as math;

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/views/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T334 batch 4: the star-ring geometry contract — Aries sits at
/// the top, the signs advance clockwise in zodiac order, every
/// dot rides the one ring radius, and the centre asterism maps
/// the backdrop's normalized star field verbatim.
void main() {
  const size = Size(360, 360);
  final radius = zodiacRingRadius(size);

  test('aries at the top, signs advance clockwise by 30 degrees', () {
    expect(zodiacRingAngle(0), closeTo(-math.pi / 2, 1e-9));
    for (var i = 1; i < 12; i++) {
      expect(zodiacRingAngle(i) - zodiacRingAngle(i - 1), closeTo(math.pi / 6, 1e-9));
    }
    final top = zodiacRingDotCenter(size, 0);
    expect(top.dx, closeTo(180, 0.001));
    expect(top.dy, closeTo(180 - radius, 0.001));
    // Index 3 (Cancer) is the rightmost point: clockwise in
    // screen coordinates.
    final right = zodiacRingDotCenter(size, 3);
    expect(right.dx, closeTo(180 + radius, 0.001));
    expect(right.dy, closeTo(180, 0.001));
  });

  test('all twelve dots ride the ring', () {
    expect(zodiacThemes.length, 12);
    for (var i = 0; i < 12; i++) {
      final dot = zodiacRingDotCenter(size, i);
      expect((dot - const Offset(180, 180)).distance, closeTo(radius, 0.001));
    }
  });

  test('constellation points map the normalized field', () {
    expect(
      constellationPoint(const Size(200, 100), const ZodiacStar(0.5, 0.25, 2)),
      const Offset(100, 25),
    );
    expect(
      constellationPoint(const Size(200, 100), const ZodiacStar(0, 1, 1)),
      const Offset(0, 100),
    );
  });

  test('ring painter repaints only when its colors change', () {
    const a = ZodiacRingPainter(ringColor: Colors.white, innerRingColor: Colors.grey);
    const b = ZodiacRingPainter(ringColor: Colors.white, innerRingColor: Colors.grey);
    const c = ZodiacRingPainter(ringColor: Colors.teal, innerRingColor: Colors.grey);
    expect(a.shouldRepaint(b), isFalse);
    expect(a.shouldRepaint(c), isTrue);
  });
}
