import 'dart:async';
import 'dart:math';

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/widgets/text.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

const _lightShadows = [
  BoxShadow(color: Color(0x0F000000), offset: Offset(0, 1), blurRadius: 2),
  BoxShadow(color: Color(0x14000000), offset: Offset(0, 8), blurRadius: 20),
  BoxShadow(
    color: Color(0x24000000),
    offset: Offset(0, 24),
    blurRadius: 48,
    spreadRadius: -12,
  ),
];

const _darkShadows = [
  BoxShadow(color: Color(0x80000000), offset: Offset(0, 2), blurRadius: 5),
  BoxShadow(
    color: Color(0x99000000),
    offset: Offset(0, 24),
    blurRadius: 48,
    spreadRadius: -12,
  ),
];

/// Lucian UX/UI Prompt #070 · MIT License
///
/// Toast kinds from the #070 stacking-toast spec (angela-uxui):
/// info (accent), success (mint), error (danger) and loading
/// (warn, spins and never auto-dismisses until it is resolved into
/// a final kind in place).
enum ToastKind { info, success, error, loading }

class _ToastEntry {
  CommonMessage message;
  ToastKind kind;
  Duration remaining;
  bool exiting = false;

  _ToastEntry(this.message, this.kind) : remaining = message.duration;

  String get id => message.id;
  bool get isLoading => kind == ToastKind.loading;
}

/// Lucian UX/UI Prompt #070 · MIT License
///
/// The app's notifier surface, rebuilt as the #070 stacking toast:
/// a new toast rises from the bottom to the front while earlier
/// ones tuck behind it (14px steps, 6% scale per step, hidden past
/// the second). Only the front toast's countdown runs — its length
/// is the message's own duration — shown as a shrinking bar in its
/// kind colour; tapping the stack (or long-pressing) fans it out
/// into a list and pauses the countdown. A toast can be swiped
/// sideways past 90px to dismiss just that one, or closed with its
/// × button. The previous single-toast behaviour is replaced, not
/// layered: every message still arrives, in order, none is dropped.
class MessageManager extends StatefulWidget {
  final Widget child;

  const MessageManager({super.key, required this.child});

  @override
  State<MessageManager> createState() => MessageManagerState();
}

class MessageManagerState extends State<MessageManager> {
  final List<_ToastEntry> _entries = [];
  final Map<String, double> _heights = {};
  bool _expanded = false;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> message(
    String text, {
    ToastKind kind = ToastKind.info,
    VoidCallback? onAction,
    String? actionLabel,
    bool showCountdown = false,
  }) async {
    if (_entries.any((e) => e.message.text == text)) {
      return;
    }
    final entry = _ToastEntry(
      CommonMessage(
        id: utils.uuidV4,
        text: text,
        // The spec's auto-dismiss lifetime for a toast.
        duration: const Duration(milliseconds: 4500),
        onAction: onAction,
        actionLabel: actionLabel,
        showCountdown: showCountdown,
      ),
      kind,
    );
    setState(() {
      _entries.add(entry);
      _expanded = false;
    });
    _ensureTicker();
  }

  /// Pushes a loading toast (spinner, no countdown) and returns its
  /// id so the owner can resolve it in place with [resolveMessage].
  String messageLoading(String text) {
    final id = utils.uuidV4;
    setState(() {
      _entries.add(
        _ToastEntry(
          CommonMessage(
            id: id,
            text: text,
            duration: const Duration(milliseconds: 4500),
          ),
          ToastKind.loading,
        ),
      );
      _expanded = false;
    });
    _ensureTicker();
    return id;
  }

  /// Turns a loading toast into its final kind (and optionally a
  /// final text) in place; its auto-dismiss countdown starts now.
  void resolveMessage(String id, {required ToastKind kind, String? text}) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index < 0) return;
    setState(() {
      final entry = _entries[index];
      entry.kind = kind;
      if (text != null) {
        entry.message = entry.message.copyWith(text: text);
      }
      entry.remaining = entry.message.duration;
    });
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_entries.isEmpty) {
        _ticker?.cancel();
        _ticker = null;
        return;
      }
      if (_expanded) return;
      final front = _entries.last;
      if (front.isLoading || front.exiting) return;
      front.remaining -= const Duration(milliseconds: 50);
      if (front.remaining <= Duration.zero) {
        _removeEntry(front);
      } else {
        setState(() {});
      }
    });
  }

  void _removeEntry(_ToastEntry entry) {
    setState(() {
      _entries.remove(entry);
      _heights.remove(entry.id);
      if (_entries.length <= 1) _expanded = false;
    });
  }

  void _handleSize(String id, double height) {
    if (_heights[id] == height) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _heights[id] != height) {
        setState(() => _heights[id] = height);
      }
    });
  }

  Color _kindColor(BuildContext context, ToastKind kind) {
    final colorScheme = context.colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;
    return switch (kind) {
      ToastKind.success =>
        isLight ? const Color(0xFF119C72) : const Color(0xFF7EE8C0),
      ToastKind.error =>
        isLight ? const Color(0xFFD93A55) : const Color(0xFFFF7D8C),
      ToastKind.loading =>
        isLight ? const Color(0xFFD6731E) : const Color(0xFFFFB26B),
      ToastKind.info => colorScheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        utils.getViewMode(MediaQuery.sizeOf(context).width) == ViewMode.mobile;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        widget.child,
        if (_entries.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomInset + 16,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 500,
                ),
                child: _buildStack(context),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStack(BuildContext context) {
    final count = _entries.length;
    double heightOf(int stackIndex) {
      final entry = _entries[count - 1 - stackIndex];
      return _heights[entry.id] ?? 68;
    }

    final double stackHeight;
    if (_expanded) {
      var total = 0.0;
      for (var i = 0; i < count; i++) {
        total += heightOf(i) + (i > 0 ? 8 : 0);
      }
      stackHeight = total;
    } else {
      stackHeight = heightOf(0) + min(count - 1, 2) * 14.0;
    }
    return SizedBox(
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < count; index++)
            _buildCard(context, index),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, int index) {
    final count = _entries.length;
    final entry = _entries[index];
    // Stack index: 0 is the front (newest, at the bottom), growing
    // upwards as toasts tuck behind it.
    final stackIndex = count - 1 - index;
    final isFront = stackIndex == 0;
    double offsetFromBottom;
    if (_expanded) {
      var acc = 0.0;
      for (var i = 0; i < stackIndex; i++) {
        acc += (_heights[_entries[count - 1 - i].id] ?? 68) + 8;
      }
      offsetFromBottom = acc;
    } else {
      offsetFromBottom = stackIndex * 14.0;
    }
    final scale = _expanded ? 1.0 : 1 - stackIndex * 0.06;
    final hidden = !_expanded && stackIndex > 2;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: offsetFromBottom),
        duration: const Duration(milliseconds: 500),
        curve: const Cubic(0.34, 1.45, 0.64, 1),
        builder: (context, offset, child) {
          return Transform.translate(
            offset: Offset(0, -offset),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.bottomCenter,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                opacity: hidden ? 0 : 1,
                child: child,
              ),
            ),
          );
        },
        child: _ToastCard(
          key: ValueKey(entry.id),
          entry: entry,
          isFront: isFront,
          expanded: _expanded,
          kindColor: _kindColor(context, entry.kind),
          progress: entry.isLoading
              ? null
              : (entry.remaining.inMilliseconds /
                        entry.message.duration.inMilliseconds)
                    .clamp(0.0, 1.0),
          onSize: (height) => _handleSize(entry.id, height),
          onClose: () => _removeEntry(entry),
          onTapStack: () {
            if (!isFront || _entries.length > 1) {
              setState(() => _expanded = !_expanded);
            }
          },
          onLongPress: () {
            if (_entries.length > 1) {
              setState(() => _expanded = true);
            }
          },
        ),
      ),
    );
  }
}

class _ToastCard extends StatefulWidget {
  final _ToastEntry entry;
  final bool isFront;
  final bool expanded;
  final Color kindColor;
  final double? progress;
  final ValueChanged<double> onSize;
  final VoidCallback onClose;
  final VoidCallback onTapStack;
  final VoidCallback onLongPress;

  const _ToastCard({
    super.key,
    required this.entry,
    required this.isFront,
    required this.expanded,
    required this.kindColor,
    required this.progress,
    required this.onSize,
    required this.onClose,
    required this.onTapStack,
    required this.onLongPress,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _swipe;
  double _dx = 0;
  bool _dragging = false;
  double _exitDirection = 0;

  _ToastEntry get entry => widget.entry;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _swipe =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addListener(() {
          if (_exitDirection != 0 && mounted) {
            setState(() {
              _dx = _exitDirection * 420 * _swipe.value;
            });
          }
        });
  }

  @override
  void dispose() {
    _enter.dispose();
    _swipe.dispose();
    super.dispose();
  }

  void _dismissSideways(double direction) {
    _exitDirection = direction;
    _swipe.forward(from: 0).whenComplete(() {
      if (mounted) widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;
    final shape = RoundedSuperellipseBorder(
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(
          alpha: isLight ? 0.5 : 0.35,
        ),
      ),
    );
    final showContent = widget.expanded || widget.isFront;
    final swipeOpacity = (1 - _dx.abs() / 260).clamp(0.2, 1.0);
    final exitOpacity = _exitDirection != 0 ? 1 - _swipe.value : 1.0;
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final t = const Cubic(0.34, 1.45, 0.64, 1).transform(_enter.value);
        return Opacity(
          opacity: (_enter.value.clamp(0.0, 1.0) * swipeOpacity * exitOpacity)
              .clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(_dx, 90 * (1 - t)),
            child: Transform.rotate(
              angle: _exitDirection * 0.14 * _swipe.value,
              child: Transform.scale(
                scale: 0.9 + 0.1 * t,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
          ),
        );
      },
      child: _SizeReporting(
        onSize: widget.onSize,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTapStack,
          onLongPress: widget.onLongPress,
          onHorizontalDragStart: (_) => _dragging = true,
          onHorizontalDragUpdate: (details) {
            if (!_dragging) return;
            setState(() => _dx += details.delta.dx);
          },
          onHorizontalDragEnd: (_) {
            _dragging = false;
            if (_dx.abs() > 90) {
              _dismissSideways(_dx > 0 ? 1 : -1);
            } else {
              setState(() => _dx = 0);
            }
          },
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: shape,
              shadows: isLight ? _lightShadows : _darkShadows,
            ),
            child: Material(
              shape: shape,
              clipBehavior: Clip.antiAlias,
              color: isLight
                  ? colorScheme.surfaceBright
                  : colorScheme.surfaceContainerHighest,
              child: Stack(
                children: [
                  Container(
                    constraints: const BoxConstraints(minHeight: 68),
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: showContent ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !showContent,
                        child: Row(
                          children: [
                            _buildIcon(context),
                            const SizedBox(width: 12),
                            if (entry.message.showCountdown)
                              _CountdownWidget(
                                duration: entry.message.duration,
                              ),
                            Expanded(
                              child: EmojiText(
                                entry.message.text,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (entry.message.actionLabel != null &&
                                entry.message.onAction != null) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  widget.onClose();
                                  entry.message.onAction?.call();
                                },
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 32),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                  ),
                                  foregroundColor: colorScheme.onSurface,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  textStyle: context.textTheme.labelLarge
                                      ?.copyWith(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(entry.message.actionLabel!),
                              ),
                            ],
                            IconButton(
                              onPressed: widget.onClose,
                              iconSize: 14,
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              padding: EdgeInsets.zero,
                              color: colorScheme.onSurfaceVariant,
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Countdown bar of the front toast (spec: 2px,
                  // kind colour at 50% opacity, shrinking with the
                  // remaining time).
                  if (widget.isFront &&
                      widget.progress != null &&
                      !entry.message.showCountdown)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 0,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: widget.progress,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: widget.kindColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final color = widget.kindColor;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: switch (entry.kind) {
        ToastKind.success => Icon(Icons.check, size: 18, color: color),
        ToastKind.error => Icon(Icons.priority_high, size: 18, color: color),
        ToastKind.info => Icon(
          Icons.mode_comment_outlined,
          size: 18,
          color: color,
        ),
        ToastKind.loading => SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
        ),
      },
    );
  }
}

/// Reports the card's laid-out height so the stack can fan out to
/// real heights when expanded.
class _SizeReporting extends SingleChildRenderObjectWidget {
  final ValueChanged<double> onSize;

  const _SizeReporting({required this.onSize, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporting(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporting renderObject,
  ) {
    renderObject.onSize = onSize;
  }
}

class _RenderSizeReporting extends RenderProxyBox {
  ValueChanged<double> onSize;

  _RenderSizeReporting(this.onSize);

  @override
  void performLayout() {
    super.performLayout();
    onSize(size.height);
  }
}

class _CountdownWidget extends StatefulWidget {
  final Duration duration;

  const _CountdownWidget({required this.duration});

  @override
  State<_CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<_CountdownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _totalSeconds;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.duration.inSeconds;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: 24,
        height: 24,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final remaining = (_totalSeconds * (1 - _controller.value)).ceil();
            final currentSecond = remaining > 0 ? remaining : 1;

            return Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1 - _controller.value,
                  strokeWidth: 2,
                  backgroundColor: primaryColor.withAlpha(56),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
                Text(
                  '$currentSecond',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
