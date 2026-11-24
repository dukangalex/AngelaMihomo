// Lucian UX/UI Prompt #336 · MIT License
//
// Bottom sheet with three detents, ported from the #336
// interaction spec (angela-uxui): drag the sheet's header and it
// tracks the finger; on release the fling velocity is projected
// 0.2s ahead and the sheet springs to the nearest of three heights
// — collapsed, half, full — overshooting slightly before settling.
// Dragging past either end rubber-bands at 0.25 resistance, and
// tapping the grab handle steps through the heights.
//
// Detent heights are the spec's fractions of the available height
// (offsets 384 / 250 / 56 in a 500px frame → visible 0.23 / 0.50 /
// 0.89). The settle spring uses the spec's physics constants
// (stiffness 320, damping 25, mass 1). The backdrop dims to 0.4
// black as the sheet rises from half to full; the spec also scales
// the page behind, which a modal route cannot reach — the dim is
// the part that lands.
import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';

import 'lucian_tokens.dart';

/// The spec's three detents as visible-height fractions.
const detentFractions = [0.23, 0.5, 0.89];

/// The detent nearest to a release: project the sheet's top edge
/// by [velocityY] for 0.2s (the spec's fling projection), then pick
/// the closest detent offset. Pure, so the choice is unit-testable.
int nearestDetent({
  required double topY,
  required double velocityY,
  required List<double> detentTops,
}) {
  final projected = topY + velocityY * 0.2;
  var best = 0;
  for (var i = 1; i < detentTops.length; i++) {
    if ((detentTops[i] - projected).abs() <
        (detentTops[best] - projected).abs()) {
      best = i;
    }
  }
  return best;
}

/// Rubber-band resistance past the ends (spec factor 0.25).
double rubberBand(double value, double min, double max) {
  if (value < min) return min - (min - value) * 0.25;
  if (value > max) return max + (value - max) * 0.25;
  return value;
}

Future<T?> showDetentSheet<T>({
  required BuildContext context,
  required Widget header,
  required Widget child,
  int initialDetent = 1,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (context) =>
        DetentSheet(header: header, initialDetent: initialDetent, child: child),
  );
}

class DetentSheet extends StatefulWidget {
  final Widget header;
  final Widget child;
  final int initialDetent;

  const DetentSheet({
    super.key,
    required this.header,
    required this.child,
    this.initialDetent = 1,
  });

  @override
  State<DetentSheet> createState() => _DetentSheetState();
}

class _DetentSheetState extends State<DetentSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spring;
  double? _topY;
  int _detent = 1;
  double _dragVelocity = 0;
  DateTime? _lastDragEnd;

  @override
  void initState() {
    super.initState();
    _detent = widget.initialDetent.clamp(0, detentFractions.length - 1);
    _spring = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (_topY != null) setState(() => _topY = _spring.value);
      });
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  List<double> _detentTops(double maxHeight) => [
    for (final fraction in detentFractions) maxHeight * (1 - fraction),
  ];

  void _snapTo(int detent, double maxHeight, {double velocityY = 0}) {
    final tops = _detentTops(maxHeight);
    _detent = detent.clamp(0, tops.length - 1);
    final target = tops[_detent];
    if (lucianReducedMotion(context) || _topY == null) {
      _spring.stop();
      setState(() => _topY = target);
      return;
    }
    _spring.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 320, damping: 25),
        _topY!,
        target,
        velocityY,
      ),
    );
  }

  void _cycleDetent(double maxHeight) {
    // A handle tap right after a drag is the drag's own click in
    // the spec; ignore taps within 350ms of a drag end.
    final lastEnd = _lastDragEnd;
    if (lastEnd != null &&
        DateTime.now().difference(lastEnd) <
            const Duration(milliseconds: 350)) {
      return;
    }
    _snapTo(_detent == detentFractions.length - 1 ? 0 : _detent + 1, maxHeight);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final tops = _detentTops(maxHeight);
        _topY ??= tops[_detent];
        final topY = _topY!;
        // Backdrop progress: 0 at half, 1 at full (spec --p).
        final p = ((tops[1] - topY) / (tops[1] - tops[2])).clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.4 * p),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: topY,
              bottom: 0,
              child: Material(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragStart: (_) {
                        _spring.stop();
                        _dragVelocity = 0;
                      },
                      onVerticalDragUpdate: (details) {
                        _dragVelocity = details.delta.dy;
                        setState(() {
                          _topY = rubberBand(
                            topY + details.delta.dy,
                            tops.last,
                            tops.first,
                          );
                        });
                      },
                      onVerticalDragEnd: (details) {
                        _lastDragEnd = DateTime.now();
                        final velocity =
                            details.primaryVelocity ?? _dragVelocity;
                        final target = nearestDetent(
                          topY: topY,
                          velocityY: velocity,
                          detentTops: tops,
                        );
                        _snapTo(target, maxHeight, velocityY: velocity);
                      },
                      onTap: () => _cycleDetent(maxHeight),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Container(
                              width: 36,
                              height: 5,
                              decoration: BoxDecoration(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.4,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          widget.header,
                        ],
                      ),
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
