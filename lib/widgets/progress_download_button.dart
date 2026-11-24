// Lucian UX/UI Prompt #004 · MIT License
//
// Progress download button, ported from the #004 interaction spec
// (angela-uxui): press to start and the button itself becomes the
// progress bar — gradient fill with a sweeping shine, percentage on
// the left, status on the right. Press again while running to
// cancel. When the transfer completes the button folds into a
// circle, draws its check, then opens back up as the done label
// before settling back to idle.
//
// The widget is driven by the owner: [phase] says idle / running /
// done, [progress] is the 0..1 fraction (null = indeterminate).
// Fold and done timing live here so every call site behaves the
// same: fold 650ms after completion, done label held ~2.75s, then
// [onDoneSettled] fires and the owner returns [phase] to idle.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'lucian_tokens.dart';

enum ProgressDownloadPhase { idle, running, done }

class ProgressDownloadButton extends StatefulWidget {
  final ProgressDownloadPhase phase;

  /// Transfer fraction 0..1 while running; null shows an
  /// indeterminate sweep instead of a percentage.
  final double? progress;
  final String label;
  final String? detail;
  final String? runningDetail;
  final String doneLabel;
  final VoidCallback? onPressed;
  final VoidCallback? onCancel;
  final VoidCallback? onDoneSettled;
  final double height;
  final double width;

  const ProgressDownloadButton({
    super.key,
    required this.phase,
    required this.label,
    required this.doneLabel,
    this.progress,
    this.detail,
    this.runningDetail,
    this.onPressed,
    this.onCancel,
    this.onDoneSettled,
    this.height = 44,
    this.width = 200,
  });

  @override
  State<ProgressDownloadButton> createState() => _ProgressDownloadButtonState();
}

class _ProgressDownloadButtonState extends State<ProgressDownloadButton>
    with TickerProviderStateMixin {
  late final AnimationController _shine;
  late final AnimationController _check;
  bool _folded = false;
  bool _expanded = false;
  Timer? _foldTimer;
  Timer? _settleTimer;

  bool get _reduced => lucianReducedMotion(context);

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _check = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  bool _initialPhaseSynced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Entering the done phase reads MediaQuery (reduced motion),
    // which is not legal inside initState — run it here, once.
    if (!_initialPhaseSynced) {
      _initialPhaseSynced = true;
      if (widget.phase == ProgressDownloadPhase.done) _enterDone();
    }
  }

  @override
  void didUpdateWidget(ProgressDownloadButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase) {
      switch (widget.phase) {
        case ProgressDownloadPhase.done:
          _enterDone();
        case ProgressDownloadPhase.running:
          _resetDoneTimers();
          _shine.repeat();
        case ProgressDownloadPhase.idle:
          _resetDoneTimers();
          _shine.stop();
          _check.reset();
      }
    }
    if (widget.phase == ProgressDownloadPhase.running && !_shine.isAnimating) {
      _shine.repeat();
    }
    if (widget.phase != ProgressDownloadPhase.running && _shine.isAnimating) {
      _shine.stop();
    }
  }

  void _resetDoneTimers() {
    _foldTimer?.cancel();
    _settleTimer?.cancel();
    _foldTimer = null;
    _settleTimer = null;
    if (_folded || _expanded) {
      setState(() {
        _folded = false;
        _expanded = false;
      });
    }
  }

  void _enterDone() {
    _shine.stop();
    _check.reset();
    setState(() => _folded = true);
    // The check draws once the fold lands: 450ms draw, 250ms delay
    // in the spec, started against the 600ms width fold.
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted && widget.phase == ProgressDownloadPhase.done) {
        _check.forward();
      }
    });
    _foldTimer = Timer(Duration(milliseconds: _reduced ? 100 : 650), () {
      if (!mounted || widget.phase != ProgressDownloadPhase.done) return;
      setState(() => _expanded = true);
      _settleTimer = Timer(Duration(milliseconds: _reduced ? 1500 : 2750), () {
        if (mounted) widget.onDoneSettled?.call();
      });
    });
  }

  @override
  void dispose() {
    _foldTimer?.cancel();
    _settleTimer?.cancel();
    _shine.dispose();
    _check.dispose();
    super.dispose();
  }

  void _handleTap() {
    switch (widget.phase) {
      case ProgressDownloadPhase.idle:
        widget.onPressed?.call();
      case ProgressDownloadPhase.running:
        widget.onCancel?.call();
      case ProgressDownloadPhase.done:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final running = widget.phase == ProgressDownloadPhase.running;
    final done = widget.phase == ProgressDownloadPhase.done;
    final mint = lucianMint(context);
    final foldedWidth = _folded && !_expanded;
    final targetWidth = foldedWidth ? widget.height : widget.width;
    final progress = (widget.progress ?? 0).clamp(0.0, 1.0);
    final percentText = widget.progress == null
        ? '···'
        : '${(progress * 100).round()}%';
    final statusText = running
        ? percentText
        : done
        ? widget.doneLabel
        : widget.label;
    return Semantics(
      button: true,
      liveRegion: running || done,
      label: statusText,
      child: AnimatedContainer(
        duration: Duration(milliseconds: _reduced ? 0 : 600),
        curve: lucianEase,
        width: targetWidth,
        height: widget.height,
        decoration: BoxDecoration(
          color: done ? mint : colorScheme.onSurface,
          borderRadius: BorderRadius.circular(widget.height / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 10),
              spreadRadius: -10,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: done ? null : _handleTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (running) _buildTrack(context, progress),
                // Idle content slides up and fades as the run starts.
                AnimatedSlide(
                  duration: const Duration(milliseconds: 500),
                  curve: lucianEase,
                  offset: running || done
                      ? const Offset(0, -0.35)
                      : Offset.zero,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    curve: lucianEase,
                    opacity: running || done ? 0 : 1,
                    child: _buildIdleContent(context),
                  ),
                ),
                // Run content rises into place.
                AnimatedSlide(
                  duration: const Duration(milliseconds: 500),
                  curve: lucianEase,
                  offset: running ? Offset.zero : const Offset(0, 0.35),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    curve: lucianEase,
                    opacity: running ? 1 : 0,
                    child: _buildRunContent(context, percentText),
                  ),
                ),
                // Done content: check first, label expands after fold.
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  curve: lucianEase,
                  opacity: done ? 1 : 0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 500),
                    curve: lucianEase,
                    scale: done ? 1 : 0.6,
                    child: _buildDoneContent(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrack(BuildContext context, double progress) {
    final trackColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.88);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: trackColor),
        Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: widget.progress == null ? 1 : progress,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6A57F2),
                    Color(0xFF3D8BFF),
                    Color(0xFF22C3A6),
                  ],
                  stops: [0, 0.6, 1],
                ),
              ),
              child: widget.progress == null
                  ? null
                  : AnimatedBuilder(
                      animation: _shine,
                      builder: (context, _) {
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(-1.2 + _shine.value * 2.4, 0),
                              end: Alignment(0.2 + _shine.value * 2.4, 0),
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                              stops: const [0.3, 0.5, 0.7],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdleContent(BuildContext context) {
    final color = Theme.of(context).colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 16),
      child: Row(
        children: [
          Container(
            width: widget.height - 10,
            height: widget.height - 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
            child: Icon(Icons.arrow_downward, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            widget.label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          if (widget.detail != null) ...[
            const Spacer(),
            Text(
              widget.detail!,
              style: TextStyle(
                color: color.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRunContent(BuildContext context, String percentText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            percentText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (widget.runningDetail != null)
            Text(
              widget.runningDetail!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDoneContent(BuildContext context) {
    final ink = Theme.of(context).brightness == Brightness.light
        ? Colors.white
        : const Color(0xFF0B2E23);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ink.withValues(alpha: 0.18),
          ),
          child: AnimatedBuilder(
            animation: _check,
            builder: (context, _) => CustomPaint(
              painter: _CheckPainter(fraction: _check.value, color: ink),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 600),
          curve: lucianEase,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    widget.doneLabel,
                    style: TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : const SizedBox(width: 0),
        ),
      ],
    );
  }
}

/// Stroke-drawn check mark; [fraction] is the drawn proportion of
/// the path (spec: dash draw over 450ms after a 250ms delay).
class _CheckPainter extends CustomPainter {
  final double fraction;
  final Color color;

  const _CheckPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (fraction <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.45, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.34);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * fraction.clamp(0.0, 1.0)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}
