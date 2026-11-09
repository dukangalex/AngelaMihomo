import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/common.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/widgets/glass.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoogleBottomNavBar extends ConsumerStatefulWidget {
  final List<NavigationItem> navigationItems;
  final int selectedIndex;
  final ValueChanged<int> onTabChange;

  const GoogleBottomNavBar({
    super.key,
    required this.navigationItems,
    required this.selectedIndex,
    required this.onTabChange,
  });

  @override
  ConsumerState<GoogleBottomNavBar> createState() => _GoogleBottomNavBarState();
}

class _GoogleBottomNavBarState extends ConsumerState<GoogleBottomNavBar>
    with TickerProviderStateMixin {
  late final AnimationController _posController = AnimationController.unbounded(
    vsync: this,
    value: widget.selectedIndex.toDouble(),
  );

  late final AnimationController _liftController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
  );

  /// Selection bubble "pop": springs from [NavBarPillPainter.bubblePopStart]
  /// back to 1.0 every time the selected tab changes, so the enlarged glass
  /// bubble settles with a spring instead of snapping (T38 round 3).
  late final AnimationController _bubbleController =
      AnimationController.unbounded(vsync: this, value: 1.0);

  void _popBubble() {
    if (!_motion) {
      _bubbleController.value = 1.0;
      return;
    }
    _bubbleController.value = NavBarPillPainter.bubblePopStart;
    _bubbleController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 320, damping: 21),
        NavBarPillPainter.bubblePopStart,
        1.0,
        0,
      ),
    );
  }

  int? _activePointerId;
  bool _isDragging = false;
  bool _dragCancel = false;
  Offset? _downPosition;
  VelocityTracker? _velocityTracker;
  double _anchorSlot = 0.0;
  double _barWidth = 0;
  int _lastSnappedIndex = 0;
  int _lastHapticTime = 0;
  late final ValueNotifier<int> _highlightedIndex = ValueNotifier(
    widget.selectedIndex,
  );
  late final ValueNotifier<int?> _pressedIndex = ValueNotifier(null);
  final ValueNotifier<double> _dragOffset = ValueNotifier(0.0);

  static const double _horizontalInset = 17.0;

  double? _posTarget;
  bool _motion = true;
  int? _jumpFromIndex;
  int? _jumpToIndex;

  void _glideTo(int index, int milliseconds) {
    _posTarget = index.toDouble();
    final fromIndex = _posController.value.round().clamp(
      0,
      widget.navigationItems.length - 1,
    );
    if ((fromIndex - index).abs() > 1 && !_isDragging) {
      _jumpFromIndex = fromIndex;
      _jumpToIndex = index;
    } else {
      _jumpFromIndex = null;
      _jumpToIndex = null;
    }
    if (milliseconds <= 0) {
      _posController.value = index.toDouble();
      _jumpFromIndex = null;
      _jumpToIndex = null;
      return;
    }
    _posController
        .animateTo(
          index.toDouble(),
          duration: Duration(milliseconds: milliseconds),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (mounted && _posTarget == index.toDouble()) {
            _jumpFromIndex = null;
            _jumpToIndex = null;
          }
        });
  }

  void _liftTo(double value, int milliseconds) {
    _liftController.animateTo(
      value,
      duration: Duration(milliseconds: milliseconds),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();
    ControlStyleStore.load();
    _lastSnappedIndex = widget.selectedIndex;
    // Best-effort: when the refraction shader lands, rebuild once so the
    // bar picks up the rim-displacement stage. Failure leaves plain glass.
    GlassRefraction.ensureLoaded().then((ready) {
      if (ready && mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant GoogleBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _popBubble();
    }
    if (widget.selectedIndex != oldWidget.selectedIndex &&
        _activePointerId == null) {
      _highlightedIndex.value = widget.selectedIndex;
      _lastSnappedIndex = widget.selectedIndex;
      if (!_posController.isAnimating) {
        _glideTo(widget.selectedIndex, _motion ? 160 : 0);
      }
    }
  }

  @override
  void dispose() {
    _highlightedIndex.dispose();
    _pressedIndex.dispose();
    _dragOffset.dispose();
    _posController.dispose();
    _liftController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _triggerHapticFeedback(bool enableFeedback) {
    if (system.isAndroid && enableFeedback) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastHapticTime > 35) {
        _lastHapticTime = now;
        HapticFeedback.selectionClick();
      }
    }
  }

  double _clampWithResistance(double slot, int count) {
    const maxOvershoot = 0.22;
    final maxIndex = math.max(0, count - 1).toDouble();
    if (slot < 0.0) {
      return -maxOvershoot * (1.0 - math.exp(slot / maxOvershoot));
    }
    if (slot > maxIndex) {
      return maxIndex +
          maxOvershoot * (1.0 - math.exp((maxIndex - slot) / maxOvershoot));
    }
    return slot;
  }

  double get _slotWidth {
    final count = widget.navigationItems.length;
    if (count == 0) return 0.0;
    return math.max(0.0, _barWidth - 2.0) / count;
  }

  void _commitDragOffset() {
    if (_dragOffset.value == 0.0) return;
    _posController.value = _clampWithResistance(
      _posController.value + _dragOffset.value,
      widget.navigationItems.length,
    );
    _dragOffset.value = 0.0;
  }

  int _indexFromLocalDx(double dx) {
    const borderWidth = 1.0;
    final innerWidth = math.max(0.0, _barWidth - (2 * borderWidth));
    final count = widget.navigationItems.length;
    if (innerWidth <= 0 || count == 0) return widget.selectedIndex;
    final slotWidth = innerWidth / count;
    final localDx = (dx - borderWidth).clamp(0.0, innerWidth - 0.001);
    return (localDx / slotWidth).floor().clamp(0, count - 1);
  }

  @override
  Widget build(BuildContext context) {
    // T64: the keycap bar skin was retired with the keycap style
    // (2026-11-08 ruling); the bar is always the glass bar now.
    return _buildBar(context);
  }

  Widget _buildBar(BuildContext context) {
    final enableFeedback = ref.watch(
      appSettingProvider.select((state) => state.enableNavBarHapticFeedback),
    );
    _motion = enableFeedback;
    final pureBlack = ref.watch(
      themeSettingProvider.select((s) => s.pureBlack),
    );
    final colorScheme = context.colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;
    final primaryColor = colorScheme.primary;
    final onSurfaceVariantColor = colorScheme.onSurfaceVariant;

    // Body color matching CommonCard (widget) formula for visual harmony
    final widgetBodyColor = isLight
        ? Color.lerp(
            colorScheme.surface,
            colorScheme.surfaceContainerLowest,
            0.5,
          )!
        : (pureBlack ? Colors.black : colorScheme.surfaceContainerHigh);

    final glassTokens = GlassTokens.resolve(
      colorScheme,
      GlassKind.navigationBar,
      base: widgetBodyColor,
    );
    final effectiveGlassTokens = glassTokens;
    const itemTextStyle = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w500,
    );

    final count = widget.navigationItems.length;
    final localizedLabels = [
      for (final item in widget.navigationItems) item.label.localizedName,
    ];

    return SafeArea(
      top: false,
      left: false,
      right: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (_activePointerId != null) return;
            _activePointerId = event.pointer;
            _downPosition = event.localPosition;
            _velocityTracker = VelocityTracker.withKind(event.kind)
              ..addPosition(event.timeStamp, event.localPosition);
            _dragCancel = false;
            _isDragging = false;
            _dragOffset.value = 0.0;

            final touchedIndex = _indexFromLocalDx(
              event.localPosition.dx - _horizontalInset,
            );
            _anchorSlot = touchedIndex.toDouble();
            _lastSnappedIndex = touchedIndex;
            _highlightedIndex.value = touchedIndex;
            _pressedIndex.value = touchedIndex;
            if (touchedIndex != widget.selectedIndex) {
              _triggerHapticFeedback(enableFeedback);
            }

            final distance = (_posController.value - touchedIndex.toDouble())
                .abs();
            final glideMs = (160 + (distance * 30)).clamp(180, 240).toInt();
            _glideTo(touchedIndex, _motion ? glideMs : 0);

            _liftTo(1.0, 140);
          },
          onPointerMove: (event) {
            if (_activePointerId != event.pointer || _dragCancel) return;
            final downPos = _downPosition;
            if (downPos == null) return;
            _velocityTracker?.addPosition(event.timeStamp, event.localPosition);
            final delta = event.localPosition - downPos;
            if (delta.dy < -50 || delta.dy > 80) {
              _dragCancel = true;
              _isDragging = false;
              _velocityTracker = null;
              _pressedIndex.value = null;
              _highlightedIndex.value = widget.selectedIndex;
              _commitDragOffset();
              _glideTo(widget.selectedIndex, 180);
              _liftTo(0.0, 180);
              return;
            }

            final slotWidth = _slotWidth;
            if (!_isDragging && delta.dx.abs() > 4) {
              _isDragging = true;
              _jumpFromIndex = null;
              _jumpToIndex = null;
            }
            if (!_isDragging || slotWidth <= 0) return;

            _dragOffset.value = delta.dx / slotWidth;
            final index = (_anchorSlot + _dragOffset.value).round().clamp(
              0,
              count - 1,
            );
            _highlightedIndex.value = index;
            _pressedIndex.value = index;
            if (index != _lastSnappedIndex) {
              _lastSnappedIndex = index;
              _triggerHapticFeedback(enableFeedback);
            }
          },
          onPointerUp: (event) {
            if (_activePointerId != event.pointer) return;
            _activePointerId = null;
            _pressedIndex.value = null;
            _liftTo(0.0, 180);
            if (_dragCancel) {
              _dragCancel = false;
              _isDragging = false;
              _velocityTracker = null;
              return;
            }

            final slotWidth = _slotWidth;
            final int targetIndex;
            if (_isDragging && slotWidth > 0) {
              final velocityPx =
                  _velocityTracker?.getVelocity().pixelsPerSecond.dx ?? 0.0;
              final slotVelocity = velocityPx / slotWidth;
              final currentSlot = _anchorSlot + _dragOffset.value;
              final fling = (slotVelocity * 0.16).clamp(-1.2, 1.2);
              var projected = (currentSlot + fling).round();
              if (velocityPx.abs() > 240.0) {
                final baseIndex = currentSlot.round();
                if (projected == baseIndex) {
                  projected += velocityPx.sign.toInt();
                }
              }
              targetIndex = projected.clamp(0, count - 1);

              _commitDragOffset();
              _highlightedIndex.value = targetIndex;
              final distance = (_posController.value - targetIndex.toDouble())
                  .abs();
              final snapMs = (130 + (distance * 80) - (velocityPx.abs() * 0.03))
                  .clamp(120, 220)
                  .toInt();
              _glideTo(targetIndex, snapMs);
            } else {
              targetIndex = _indexFromLocalDx(
                event.localPosition.dx - _horizontalInset,
              );
              _highlightedIndex.value = targetIndex;
              final distance = (_posController.value - targetIndex.toDouble())
                  .abs();
              final glideMs = (160 + (distance * 30)).clamp(180, 240).toInt();
              final needsGlide = _posController.isAnimating
                  ? _posTarget != targetIndex.toDouble()
                  : distance > 0.01;
              if (needsGlide) {
                _glideTo(targetIndex, _motion ? glideMs : 0);
              }
            }

            _velocityTracker = null;
            _isDragging = false;
            if (targetIndex != widget.selectedIndex) {
              widget.onTabChange(targetIndex);
            }
          },
          onPointerCancel: (event) {
            if (_activePointerId != event.pointer) return;
            _activePointerId = null;
            _isDragging = false;
            _dragCancel = false;
            _velocityTracker = null;
            _pressedIndex.value = null;
            _highlightedIndex.value = widget.selectedIndex;
            _commitDragOffset();
            _glideTo(widget.selectedIndex, 180);
            _liftTo(0.0, 180);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _horizontalInset),
            child: LayoutBuilder(
              builder: (context, constraints) {
                _barWidth = constraints.maxWidth;
                const barHeight = 60.0;

                final barShape = RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                );

                return RepaintBoundary(
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: barShape,
                      shadows: [
                        // Shadow calibrated against Apple's iOS 27 kit
                        // (T38): 0 8px 15px at 2% black — a whisper of a
                        // shadow; separation comes from the rim and fill,
                        // not from a drop shadow.
                        BoxShadow(
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                          color: Colors.black.withValues(alpha: 0.02),
                        ),
                      ],
                    ),
                    child: GlassSurface(
                      shape: barShape,
                      tokens: effectiveGlassTokens,
                      refractionSize: Size(constraints.maxWidth, barHeight),
                      refractionRadius: 30,
                      child: Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: glassTokens.effectiveFill,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: glassTokens.rim,
                            // 0.5px hairline stroke (Apple kit calibre);
                            // the brighter rim light stays in
                            // GlassSurface and the pill painter.
                            width: 0.5,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            if (count > 0)
                              Positioned.fill(
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    painter: NavBarPillPainter(
                                      position: _posController,
                                      lift: _liftController,
                                      dragOffset: _dragOffset,
                                      bubble: _bubbleController,
                                      count: count,
                                      slot: _clampWithResistance,
                                      color: primaryColor,
                                      baseAlpha: isLight ? 0.30 : 0.34,
                                      activeAlpha: isLight ? 0.38 : 0.42,
                                      rimColor: Colors.white.withValues(
                                        alpha: isLight ? 0.55 : 0.40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _posController,
                                  _dragOffset,
                                  _pressedIndex,
                                  _liftController,
                                ]),
                                builder: (context, _) {
                                  final currentPos = _clampWithResistance(
                                    _posController.value + _dragOffset.value,
                                    count,
                                  );
                                  final pressedIdx = _pressedIndex.value;
                                  final liftValue = _liftController.value;

                                  final jumpFrom = _jumpFromIndex;
                                  final jumpTo = _jumpToIndex;
                                  final isNonAdjacentJump =
                                      jumpFrom != null &&
                                      jumpTo != null &&
                                      (jumpFrom - jumpTo).abs() > 1;
                                  final minJump = isNonAdjacentJump
                                      ? math.min(jumpFrom, jumpTo)
                                      : -1;
                                  final maxJump = isNonAdjacentJump
                                      ? math.max(jumpFrom, jumpTo)
                                      : -1;

                                  return Row(
                                    children: List.generate(count, (index) {
                                      final item =
                                          widget.navigationItems[index];
                                      final isPressed = index == pressedIdx;
                                      final double itemScale;
                                      final Color itemColor;
                                      if (isNonAdjacentJump &&
                                          index > minJump &&
                                          index < maxJump) {
                                        itemScale = 1.0;
                                        itemColor = onSurfaceVariantColor;
                                      } else {
                                        final double selectFactor;
                                        if (isNonAdjacentJump) {
                                          if (index == jumpFrom) {
                                            final distFromOrigin =
                                                (currentPos - jumpFrom)
                                                    .abs()
                                                    .clamp(0.0, 1.0);
                                            selectFactor =
                                                1.0 -
                                                Curves.easeOut.transform(
                                                  distFromOrigin,
                                                );
                                          } else if (index == jumpTo) {
                                            final distToTarget =
                                                (currentPos - jumpTo)
                                                    .abs()
                                                    .clamp(0.0, 1.0);
                                            selectFactor =
                                                1.0 -
                                                Curves.easeOut.transform(
                                                  distToTarget,
                                                );
                                          } else {
                                            selectFactor = 0.0;
                                          }
                                        } else {
                                          final rawDist = (currentPos - index)
                                              .abs();
                                          if (rawDist >= 1.0) {
                                            selectFactor = 0.0;
                                          } else {
                                            final dist = rawDist.clamp(
                                              0.0,
                                              1.0,
                                            );
                                            selectFactor =
                                                1.0 -
                                                Curves.easeOut.transform(dist);
                                          }
                                        }

                                        if (selectFactor <= 0.0 && !isPressed) {
                                          itemScale = 1.0;
                                          itemColor = onSurfaceVariantColor;
                                        } else {
                                          itemScale = isPressed
                                              ? (1.0 - 0.05 * liftValue)
                                              : (1.0 + 0.04 * selectFactor);
                                          itemColor = Color.lerp(
                                            onSurfaceVariantColor,
                                            primaryColor,
                                            selectFactor,
                                          )!;
                                        }
                                      }

                                      // Shared item content: icon
                                      // (with the T29 patrol badge on
                                      // both skins) + label.
                                      final itemContent = Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconTheme(
                                            data: IconThemeData(
                                              color: itemColor,
                                              size: 22,
                                            ),
                                            child:
                                                item.label == PageLabel.patrol
                                                ? ValueListenableBuilder<int>(
                                                    valueListenable:
                                                        patrolAttentionCount,
                                                    builder:
                                                        (context, count, child) =>
                                                            Badge(
                                                              isLabelVisible:
                                                                  count > 0,
                                                              label: Text(
                                                                '$count',
                                                              ),
                                                              child: child,
                                                            ),
                                                    child: item.icon,
                                                  )
                                                : item.icon,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            localizedLabels[index],
                                            style: itemTextStyle.copyWith(
                                              color: itemColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      );
                                      return Expanded(
                                        child: Center(
                                          child: Transform.scale(
                                            scale: itemScale,
                                            alignment: Alignment.center,
                                            child: itemContent,
                                          ),
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class NavBarPillPainter extends CustomPainter {
  final Animation<double> position;
  final Animation<double> lift;
  final ValueListenable<double> dragOffset;
  final Animation<double> bubble;
  final int count;
  final double Function(double slot, int count) slot;
  final Color color;
  final double baseAlpha;
  final double activeAlpha;
  final Color rimColor;

  NavBarPillPainter({
    required this.position,
    required this.lift,
    required this.dragOffset,
    required this.bubble,
    required this.count,
    required this.slot,
    required this.color,
    required this.baseAlpha,
    required this.activeAlpha,
    required this.rimColor,
  }) : super(repaint: Listenable.merge([position, lift, dragOffset, bubble]));

  static const double _restingGap = 4.0;

  /// Resting size of the selection bubble relative to the plain pill
  /// (T38 round 3: an enlarged glass bubble, per the reference research —
  /// selected = inflated + brightened, not recoloured).
  static const double bubbleInflation = 1.18;

  /// Where the bubble spring starts on every selection change (it springs
  /// back to 1.0 with a slight overshoot, which scales the inflation).
  static const double bubblePopStart = 0.85;

  Rect pillRect(Size size) {
    final slotWidth = size.width / count;
    final gap = _restingGap * (1 - lift.value);
    final baseWidth = math.max(0.0, slotWidth - 2 * gap);
    final baseHeight = size.height - 2 * gap;
    final pop = bubble.value;
    final width = math.min(baseWidth * bubbleInflation * pop, slotWidth * 1.3);
    final height = math.min(
      baseHeight * (1 + (bubbleInflation - 1) * 0.55) * pop,
      size.height - 4,
    );
    final centerX =
        (slot(position.value + dragOffset.value, count) + 0.5) * slotWidth;
    return Rect.fromCenter(
      center: Offset(centerX, size.height / 2),
      width: width,
      height: height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = lift.value;
    final alpha = baseAlpha + (activeAlpha - baseAlpha) * t;
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.height / 2),
      ),
    );
    final rect = pillRect(size);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );
    // Glass body of the bubble.
    canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: alpha));
    // Specular sheen across the top of the bubble.
    final sheen = Paint()
      ..shader = ui.Gradient.linear(
        rect.topCenter,
        rect.bottomCenter,
        [
          Colors.white.withValues(alpha: 0.30 + 0.12 * t),
          Colors.white.withValues(alpha: 0),
        ],
        const [0, 0.55],
      );
    canvas.drawRRect(rrect, sheen);
    // Bright rim: the bubble's refraction edge.
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = rimColor.withValues(alpha: rimColor.a * (0.75 + 0.25 * t)),
    );
  }

  @override
  bool shouldRepaint(NavBarPillPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.lift != lift ||
        oldDelegate.dragOffset != dragOffset ||
        oldDelegate.bubble != bubble ||
        oldDelegate.count != count ||
        oldDelegate.color != color ||
        oldDelegate.baseAlpha != baseAlpha ||
        oldDelegate.activeAlpha != activeAlpha ||
        oldDelegate.rimColor != rimColor;
  }
}
