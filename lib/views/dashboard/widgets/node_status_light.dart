import 'dart:async';
import 'dart:math' as math;

import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/views/proxies/common.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Health states of the current node, as shown by the running-mode
/// card's status light (T133, restoring the chain.22 T114 light).
enum NodeLightStatus { available, unavailable, testing, unknown }

/// Maps the shared delay data of the current node to a light state.
/// A missing entry (core stopped, nothing measured yet) is the grey
/// no-data state — never a health verdict.
NodeLightStatus resolveNodeLightStatus({
  required bool isRunning,
  required int? delay,
}) {
  if (!isRunning || delay == null) return NodeLightStatus.unknown;
  if (delay < 0) return NodeLightStatus.unavailable;
  if (delay == 0) return NodeLightStatus.testing;
  return NodeLightStatus.available;
}

/// The group whose current selection is "the current node": GLOBAL in
/// global mode, the profile's main (first visible) group in rule mode,
/// and none in direct mode.
Group? nodeLightAnchorGroup({
  required Mode mode,
  required List<Group> visibleGroups,
}) {
  return switch (mode) {
    Mode.direct => null,
    Mode.global =>
      visibleGroups.getGroup(GroupName.GLOBAL.name) ??
          (visibleGroups.isEmpty ? null : visibleGroups.first),
    Mode.rule => visibleGroups.isEmpty ? null : visibleGroups.first,
  };
}

/// Concentric status light on the running-mode card (T133).
///
/// The inner dot carries the health of the current node — green when
/// its latest measured delay is usable, red when the latest measurement
/// failed, grey when there is no measurement to judge by. The delay
/// comes from the one shared delay data source every test entry point
/// writes to, so the light follows global tests, group tests and node
/// switches on its own. Tapping the light runs the global linked delay
/// test through the very same controller the proxies page uses (and
/// cancels it while running): one engine, two triggers, and a run only
/// ever measures — it never writes a selection.
///
/// Every visual quantity is taken from the active constellation theme:
/// the dot colors are the variant's status tokens, the ring paints the
/// variant's selected gradient, the halo is the variant's glow, and the
/// theme's sign glyph sits beside the label. While a test runs, the
/// ring's gapped arc rotates; the animation stops the moment the run
/// ends, so nothing animates at rest.
class NodeStatusLight extends ConsumerStatefulWidget {
  const NodeStatusLight({super.key});

  @override
  ConsumerState<NodeStatusLight> createState() => _NodeStatusLightState();
}

class _NodeStatusLightState extends ConsumerState<NodeStatusLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _applySpin(bool wantSpin) {
    if (wantSpin && !_spinController.isAnimating) {
      _spinController.repeat();
    } else if (!wantSpin && _spinController.isAnimating) {
      _spinController.stop();
    }
  }

  void _onTap() {
    if (globalDelayTestController.isRunning) {
      cancelGlobalDelayTest();
    } else {
      unawaited(globalDelayTest());
    }
  }

  Color _statusColor(ZodiacVariant? variant, NodeLightStatus status) {
    if (variant != null) {
      return switch (status) {
        NodeLightStatus.available => variant.success,
        NodeLightStatus.unavailable => variant.error,
        NodeLightStatus.testing => variant.warning,
        NodeLightStatus.unknown => variant.disabled,
      };
    }
    final colorScheme = context.colorScheme;
    return switch (status) {
      NodeLightStatus.available => const Color(0xFF2E9E4F),
      NodeLightStatus.unavailable => colorScheme.error,
      NodeLightStatus.testing => const Color(0xFFC57F0A),
      NodeLightStatus.unknown =>
        colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
    };
  }

  List<Color> _ringColors(ZodiacVariant? variant) {
    if (variant == null) {
      final primary = context.colorScheme.primary;
      return [primary, primary.withValues(alpha: 0.35)];
    }
    final selected = variant.selected;
    if (selected.isGradient) return selected.stops!;
    if (!selected.isNone) return [selected.firstColor, variant.secondary];
    return [variant.primary, variant.accent];
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = ref.watch(
      runTimeProvider.select((value) => value != null),
    );
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final visibleGroups = ref.watch(
      currentGroupsStateProvider.select((state) => state.value),
    );
    final anchor = nodeLightAnchorGroup(
      mode: mode,
      visibleGroups: visibleGroups,
    );
    final delay = anchor == null
        ? null
        : ref.watch(getDelayProvider(proxyName: anchor.name));
    final status = resolveNodeLightStatus(isRunning: isRunning, delay: delay);

    final zodiac = context.zodiac;
    final variant = zodiac?.variant;
    final statusColor = _statusColor(variant, status);
    final ringColors = _ringColors(variant);
    final trackColor =
        variant?.outline ??
        context.colorScheme.outlineVariant.withValues(alpha: 0.6);
    final haloColor = variant?.glow ?? statusColor.withValues(alpha: 0.30);
    final sign = zodiac == null
        ? null
        : resolveZodiacTheme(zodiac.themeId).sign;

    return AnimatedBuilder(
      animation: globalDelayTestController,
      builder: (context, _) {
        final testRunning = globalDelayTestController.isRunning;
        final spinning = testRunning || status == NodeLightStatus.testing;
        _applySpin(spinning);
        final label = testRunning
            ? '${appLocalizations.globalDelayTesting} '
                  '${globalDelayTestController.completed}/'
                  '${globalDelayTestController.total}'
            : switch (status) {
                NodeLightStatus.available =>
                  appLocalizations.currentNodeAvailable,
                NodeLightStatus.unavailable =>
                  appLocalizations.currentNodeUnavailable,
                NodeLightStatus.testing => appLocalizations.globalDelayTesting,
                NodeLightStatus.unknown =>
                  appLocalizations.currentNodeUnknown,
              };
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(24, 24),
                          painter: _RingPainter(
                            rotation: _spinController,
                            colors: ringColors,
                            trackColor: trackColor,
                            spinning: spinning,
                          ),
                        ),
                        Container(
                          key: const ValueKey('nodeStatusLightDot'),
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                            boxShadow: [
                              BoxShadow(
                                color: haloColor,
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  if (sign != null) ...[
                    Text(
                      sign,
                      style: TextStyle(
                        fontSize: 13,
                        color: variant?.accent.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final Animation<double> rotation;
  final List<Color> colors;
  final Color trackColor;
  final bool spinning;

  _RingPainter({
    required this.rotation,
    required this.colors,
    required this.trackColor,
    required this.spinning,
  }) : super(repaint: rotation);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 3.0;
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor.withValues(alpha: 0.45);
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(colors: colors).createShader(rect);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    if (spinning) canvas.rotate(rotation.value * math.pi * 2);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      spinning ? math.pi * 1.5 : math.pi * 2,
      false,
      arcPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return spinning != oldDelegate.spinning ||
        trackColor != oldDelegate.trackColor ||
        colors != oldDelegate.colors;
  }
}
