import 'dart:math' as math;

import 'package:angelamihomo/views/dashboard/widgets/orbit_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T334 batch 2: the orbit painter's geometry contract — the exit
/// dot starts at the top of the outer ring, the chain dot rides
/// the middle ring away from it, and a phase step is the only
/// thing that moves them (state changes repaint, idle frames do
/// not exist because the painter is driven by the gated
/// controller).
void main() {
  const size = Size(300, 300);

  test('exit dot starts at the top of the outer ring', () {
    final offset = orbitDotOffset(
      size,
      orbitRingFractions[0],
      orbitExitAngle(0),
    );
    expect(offset.dx, closeTo(150, 0.001));
    expect(offset.dy, closeTo(150 - 150 * orbitRingFractions[0], 0.001));
  });

  test('dots advance with the phase and stay on their rings', () {
    for (final phase in [0.0, 0.25, 0.5, 0.87]) {
      final exit = orbitDotOffset(
        size,
        orbitRingFractions[0],
        orbitExitAngle(phase),
      );
      final chain = orbitDotOffset(
        size,
        orbitRingFractions[1],
        orbitChainAngle(phase),
      );
      expect(
        (exit - const Offset(150, 150)).distance,
        closeTo(150 * orbitRingFractions[0], 0.001),
      );
      expect(
        (chain - const Offset(150, 150)).distance,
        closeTo(150 * orbitRingFractions[1], 0.001),
      );
      // The two hops never share a point at any phase.
      expect((exit - chain).distance, greaterThan(20));
    }
    // A quarter phase is a quarter turn.
    final quarter = orbitDotOffset(
      size,
      orbitRingFractions[0],
      orbitExitAngle(0.25),
    );
    expect(quarter.dx, closeTo(150 + 150 * orbitRingFractions[0], 0.001));
    expect(quarter.dy, closeTo(150, 0.001));
    expect(orbitExitAngle(1) - orbitExitAngle(0), closeTo(2 * math.pi, 1e-9));
  });

  test('painter repaints on state or phase change only', () {
    OrbitPainter make({double phase = 0, bool active = true}) => OrbitPainter(
      phase: phase,
      active: active,
      hasChain: false,
      glowLine: Colors.white,
      primary: Colors.purple,
      secondary: Colors.teal,
    );
    expect(make().shouldRepaint(make()), isFalse);
    expect(make().shouldRepaint(make(phase: 0.5)), isTrue);
    expect(make().shouldRepaint(make(active: false)), isTrue);
  });
}
