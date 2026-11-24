// Lucian UX/UI Prompt #438 · MIT License
//
// Loading-to-done morph button, ported from the #438 interaction
// spec (angela-uxui): press and the button squishes, its label
// fades as it shrinks into a circle and spins; on success a check
// draws itself inside the mint circle with a pop and an expanding
// ring, then the button stretches back to full width and the label
// returns. On failure it stretches straight back to its idle state
// — surfacing the reason is the caller's job (dialog / toast).
//
// Timing from the spec: shrink 460ms cubic-bezier(.65,0,.35,1),
// spinner fades in after 220ms and turns at 0.75s/rev, success pop
// 500ms cubic-bezier(.34,1.7,.5,1), check draw 380ms after 120ms,
// ring 700ms after 100ms, success held 1000ms, grow-back 620ms
// cubic-bezier(.34,1.32,.5,1) with the label returning at +160ms.
import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'lucian_tokens.dart';

enum _Phase { idle, busy, ok, growing }

class MorphActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;

  /// Runs the action; true = success (check + grow back, then
  /// [onCompleted]), false or a throw = straight back to idle.
  final Future<bool> Function() onPressed;

  /// Called once the success animation has fully settled back to
  /// the idle shape (e.g. to leave the page after a save).
  final VoidCallback? onCompleted;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;

  const MorphActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.onCompleted,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 48,
  });

  @override
  State<MorphActionButton> createState() => _MorphActionButtonState();
}

class _MorphActionButtonState extends State<MorphActionButton>
    with TickerProviderStateMixin {
  final _measureKey = GlobalKey();
  late final AnimationController _spin;
  late final AnimationController _okFx;
  _Phase _phase = _Phase.idle;
  double? _fullWidth;
  double _pressScale = 1;
  bool _showSpinner = false;
  Timer? _spinnerTimer;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _okFx = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(MorphActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label || oldWidget.icon != widget.icon) {
      _fullWidth = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _measure() {
    final box = _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && mounted) {
      final width = box.size.width;
      if (width > 0 && width != _fullWidth) {
        setState(() => _fullWidth = width);
      }
    }
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    _holdTimer?.cancel();
    _spin.dispose();
    _okFx.dispose();
    super.dispose();
  }

  bool get _reduced => lucianReducedMotion(context);

  Future<void> _handleTap() async {
    if (_phase != _Phase.idle) return;
    setState(() {
      _phase = _Phase.busy;
      _showSpinner = false;
    });
    _spinnerTimer = Timer(Duration(milliseconds: _reduced ? 0 : 220), () {
      if (mounted && _phase == _Phase.busy) {
        setState(() => _showSpinner = true);
        _spin.repeat();
      }
    });
    bool ok;
    try {
      ok = await widget.onPressed();
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    _spinnerTimer?.cancel();
    _spin.stop();
    if (!ok) {
      setState(() => _phase = _Phase.growing);
      // Grow back with the spec's overshoot curve, then idle.
      Future.delayed(Duration(milliseconds: _reduced ? 0 : 620), () {
        if (mounted && _phase == _Phase.growing) {
          setState(() => _phase = _Phase.idle);
        }
      });
      return;
    }
    setState(() => _phase = _Phase.ok);
    _okFx.forward(from: 0);
    _holdTimer = Timer(Duration(milliseconds: _reduced ? 600 : 1000), () {
      if (!mounted || _phase != _Phase.ok) return;
      setState(() => _phase = _Phase.growing);
      Future.delayed(Duration(milliseconds: _reduced ? 0 : 700), () {
        if (!mounted) return;
        setState(() => _phase = _Phase.idle);
        widget.onCompleted?.call();
      });
    });
  }

  Widget _content(BuildContext context, Color fg) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: fg),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            color: fg,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mint = lucianMint(context);
    final bg = _phase == _Phase.ok
        ? mint
        : (widget.backgroundColor ?? colorScheme.primary);
    final fg = _phase == _Phase.ok
        ? (Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF0B2E23))
        : (widget.foregroundColor ?? colorScheme.onPrimary);
    final busy = _phase == _Phase.busy;
    final ok = _phase == _Phase.ok;
    final shrunk = busy || ok;
    final width = shrunk ? widget.height : _fullWidth;
    final widthCurve = _phase == _Phase.growing
        ? const Cubic(0.34, 1.32, 0.5, 1)
        : const Cubic(0.65, 0, 0.35, 1);
    final decoration = BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(widget.height / 2),
      boxShadow: [
        BoxShadow(
          color: bg.withValues(alpha: 0.5),
          blurRadius: 24,
          offset: const Offset(0, 10),
          spreadRadius: -12,
        ),
      ],
    );
    // Until the idle width has been measured, render the button at
    // its natural width (this very container is the measuring
    // copy). Feeding AnimatedContainer a null width first and a
    // finite width later makes its constraints tween interpolate
    // between unbounded and finite constraints, which asserts.
    if (_fullWidth == null) {
      return Container(
        key: _measureKey,
        height: widget.height,
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _phase == _Phase.idle ? _handleTap : null,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: _content(context, fg),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _okFx,
          builder: (context, child) {
            // Success pop: scale to 1.12 at 40% of 500ms, settle
            // back to 1 (spec keyframes, cubic-bezier(.34,1.7,.5,1)
            // approximated by the keyframe envelope).
            var pop = 1.0;
            if (_phase == _Phase.ok && !_reduced) {
              final x = (_okFx.value * 700 / 500).clamp(0.0, 1.0);
              pop = x < 0.4
                  ? 1 + 0.12 * (x / 0.4)
                  : 1 + 0.12 * (1 - (x - 0.4) / 0.6);
            }
            return Transform.scale(scale: _pressScale * pop, child: child);
          },
          child: AnimatedContainer(
            duration: Duration(
              milliseconds: _reduced
                  ? 0
                  : _phase == _Phase.growing
                  ? 620
                  : 460,
            ),
            curve: widthCurve,
            width: width,
            height: widget.height,
            decoration: decoration,
            clipBehavior: Clip.antiAlias,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTapDown: _phase == _Phase.idle
                    ? (_) => setState(() => _pressScale = 0.93)
                    : null,
                onTapUp: (_) => setState(() => _pressScale = 1),
                onTapCancel: () => setState(() => _pressScale = 1),
                onTap: _phase == _Phase.idle ? _handleTap : null,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Label fades / blurs / shrinks away while busy.
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      curve: lucianEase,
                      opacity: shrunk ? 0 : 1,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 300),
                        curve: lucianEase,
                        scale: shrunk ? 0.9 : 1,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: _content(context, fg),
                          ),
                        ),
                      ),
                    ),
                    // Spinner (0.75s per revolution, spec arc).
                    if (busy)
                      Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _showSpinner ? 1 : 0,
                          child: AnimatedBuilder(
                            animation: _spin,
                            builder: (context, _) => Transform.rotate(
                              angle: _spin.value * 2 * math.pi,
                              child: CustomPaint(
                                size: const Size(22, 22),
                                painter: _SpinnerPainter(color: fg),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Success: check draw + expanding ring.
                    if (ok)
                      AnimatedBuilder(
                        animation: _okFx,
                        builder: (context, _) {
                          final ringT = ((_okFx.value - 0.14) / 0.86).clamp(
                            0.0,
                            1.0,
                          );
                          final checkT = ((_okFx.value - 0.17) / 0.54).clamp(
                            0.0,
                            1.0,
                          );
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              if (ringT > 0 && ringT < 1)
                                Center(
                                  child: Container(
                                    width: widget.height * (1 + 0.7 * ringT),
                                    height: widget.height * (1 + 0.7 * ringT),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: mint.withValues(
                                          alpha: 0.7 * (1 - ringT),
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              Center(
                                child: CustomPaint(
                                  size: const Size(22, 22),
                                  painter: _MorphCheckPainter(
                                    fraction: checkT,
                                    color: fg,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final Color color;

  const _SpinnerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, base);
    final top = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 0.9, false, top);
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) => oldDelegate.color != color;
}

class _MorphCheckPainter extends CustomPainter {
  final double fraction;
  final Color color;

  const _MorphCheckPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (fraction <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.23, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.71)
      ..lineTo(size.width * 0.77, size.height * 0.29);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * fraction.clamp(0.0, 1.0)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_MorphCheckPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}
