// Lucian UX/UI Prompt #082 · MIT License
//
// Install progress on the icon, ported from the #082 interaction
// spec (angela-uxui): a dark veil over the icon sweeps away
// clockwise as progress climbs, the percentage and the meta line
// (transferred / total · rate) climb with it, and tapping the icon
// toggles pause — the centre badge cross-fades between pause and
// play. When the transfer finishes the veil and badge fade away
// and the icon hops once.
//
// Veil colour rgba(12,10,24,.55), badge ring and hop keyframes
// (30%: scale .9, 60%: scale 1.08 with a -4px lift, 700ms spring)
// are the spec's values.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'lucian_tokens.dart';

class IconSweepProgress extends StatefulWidget {
  /// Transfer fraction 0..1; null renders the untouched icon with a
  /// spinning badge (the transfer has not produced numbers yet).
  final double? progress;
  final bool paused;
  final bool done;

  /// The icon artwork the veil sweeps over (e.g. the app icon).
  final Widget icon;
  final double size;

  /// Meta line under the percentage, e.g. "12 MB / 186 MB · 3.1 MB/s"
  /// or a paused / finished wording supplied by the owner.
  final String? metaText;
  final VoidCallback? onTap;

  const IconSweepProgress({
    super.key,
    required this.icon,
    required this.progress,
    this.paused = false,
    this.done = false,
    this.size = 104,
    this.metaText,
    this.onTap,
  });

  @override
  State<IconSweepProgress> createState() => _IconSweepProgressState();
}

class _IconSweepProgressState extends State<IconSweepProgress>
    with TickerProviderStateMixin {
  late final AnimationController _hop;
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _hop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat();
    if (widget.done) _hop.forward();
  }

  @override
  void didUpdateWidget(IconSweepProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.done && !oldWidget.done) {
      if (lucianReducedMotion(context)) {
        _hop.value = 1;
      } else {
        _hop.forward(from: 0);
      }
    }
    if (widget.progress == null && !_spin.isAnimating) {
      _spin.repeat();
    } else if (widget.progress != null && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.progress ?? 0).clamp(0.0, 1.0);
    final percent = (progress * 100).floor();
    final radius = widget.size * 0.24;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _hop,
          builder: (context, child) {
            final t = _hop.value;
            var scale = 1.0;
            var dy = 0.0;
            if (widget.done && t > 0 && t < 1) {
              if (t < 0.3) {
                scale = 1 - 0.1 * (t / 0.3);
              } else if (t < 0.6) {
                final x = (t - 0.3) / 0.3;
                scale = 0.9 + 0.18 * x;
                dy = -4 * x;
              } else {
                final x = (t - 0.6) / 0.4;
                scale = 1.08 - 0.08 * x;
                dy = -4 * (1 - x);
              }
            }
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: widget.icon,
                  ),
                  // The sweeping veil: everything not yet revealed
                  // stays under rgba(12,10,24,.55).
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: widget.done ? 0 : 1,
                    child: CustomPaint(
                      painter: _VeilPainter(progress: progress, radius: radius),
                    ),
                  ),
                  // Centre badge: pause ⇄ play cross-fade, a spinner
                  // before the first numbers, gone when done.
                  Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: widget.done ? 0 : 1,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 450),
                        curve: lucianSpring,
                        scale: widget.done ? 0.4 : 1,
                        child: Container(
                          width: widget.size * 0.44,
                          height: widget.size * 0.44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFF0C0A18,
                            ).withValues(alpha: 0.5),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                              width: 3,
                            ),
                          ),
                          child: widget.progress == null
                              ? AnimatedBuilder(
                                  animation: _spin,
                                  builder: (context, _) => Transform.rotate(
                                    angle: _spin.value * 2 * math.pi,
                                    child: const Icon(
                                      Icons.downloading,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                )
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    widget.paused
                                        ? Icons.play_arrow
                                        : Icons.pause,
                                    key: ValueKey(widget.paused),
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (widget.metaText != null)
          Text(
            widget.metaText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        const SizedBox(height: 6),
        Semantics(
          liveRegion: true,
          label: widget.done ? '100%' : '$percent%',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.done ? '100' : '$percent',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Paints the un-revealed sector: the conic sweep starts at the
/// top and opens clockwise with progress, so the veil is the pie
/// slice from the progress angle back around to the top.
class _VeilPainter extends CustomPainter {
  final double progress;
  final double radius;

  const _VeilPainter({required this.progress, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = const Color(0xFF0C0A18).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    if (progress <= 0) {
      canvas.drawRect(rect, paint);
    } else {
      final center = rect.center;
      final sweep = (1 - progress) * 2 * math.pi;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: size.longestSide),
          -math.pi / 2 + progress * 2 * math.pi,
          sweep,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VeilPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.radius != radius;
}
