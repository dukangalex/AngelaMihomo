import 'dart:math' as math;

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/state.dart';
import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'builder.dart';
import 'card.dart';
import 'grid.dart';

typedef EditableGridWrapper = Widget Function(Widget child);

class EditableGrid<T extends Object> extends StatefulWidget {
  final List<T> items;
  final bool editing;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double? mainAxisExtent;
  final Object Function(T item) keyOf;
  final int Function(T item) crossAxisCellCountOf;
  final num? Function(T item)? mainAxisCellCountOf;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool Function(T item)? canResize;
  final ValueChanged<T>? onResize;
  final bool Function(T item)? canDelete;
  final ValueChanged<T>? onDelete;
  final bool Function(T item)? canMove;
  final void Function(T from, T to)? onMove;
  final VoidCallback? onLongPress;
  final EditableGridWrapper? overlayWrapper;

  const EditableGrid({
    super.key,
    required this.items,
    required this.editing,
    required this.crossAxisCount,
    required this.keyOf,
    required this.crossAxisCellCountOf,
    required this.itemBuilder,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.mainAxisExtent,
    this.mainAxisCellCountOf,
    this.canResize,
    this.onResize,
    this.canDelete,
    this.onDelete,
    this.canMove,
    this.onMove,
    this.onLongPress,
    this.overlayWrapper,
  });

  @override
  State<EditableGrid<T>> createState() => _EditableGridState<T>();
}

class _EditableGridState<T extends Object> extends State<EditableGrid<T>>
    with SingleTickerProviderStateMixin {
  final _gridKey = GlobalKey();
  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 0.5,
  );
  DateTime _lastMove = DateTime.fromMillisecondsSinceEpoch(0);

  // While a drag is in flight the grid must not FLIP-animate the
  // tiles a hover-reorder displaces (T343): the slides run
  // unclipped over neighbouring tiles, and with translucent card
  // faces the text of the sliding tile and the tile beneath reads
  // as one doubled image. During a drag the displaced tiles snap
  // straight into their yielded cells instead — the yield itself
  // (the layout reflow on hover) is unchanged.
  bool _dragActive = false;

  void _setDragActive(bool value) {
    if (_dragActive == value || !mounted) return;
    setState(() => _dragActive = value);
  }

  @override
  void initState() {
    super.initState();
    if (widget.editing) _shake.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(EditableGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editing == widget.editing) return;
    if (widget.editing) {
      _shake.repeat(reverse: true);
    } else {
      _shake.stop();
      _shake.value = 0.5;
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _move(T from, T to) {
    final now = DateTime.now();
    if (now.difference(_lastMove) < const Duration(milliseconds: 220)) return;
    _lastMove = now;
    widget.onMove?.call(from, to);
  }

  Widget _buildTile(BuildContext context, T item, int index) {
    final child = widget.itemBuilder(context, item);
    if (!widget.editing) {
      final onLongPress = widget.onLongPress;
      if (onLongPress == null) return child;
      return GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onLongPress();
        },
        child: child,
      );
    }
    final canResize = widget.canResize?.call(item) ?? false;
    final canDelete = widget.canDelete?.call(item) ?? false;
    final canMove = widget.canMove?.call(item) ?? true;
    final onResize = widget.onResize;
    final onDelete = widget.onDelete;
    return _EditTile<T>(
      item: item,
      keyOf: widget.keyOf,
      shake: _shake,
      phase: index * 1.7,
      cells: math.max(1, widget.crossAxisCellCountOf(item)),
      onResize: canResize && onResize != null
          ? () {
              HapticFeedback.selectionClick();
              onResize(item);
            }
          : null,
      onDelete: canDelete && onDelete != null ? () => onDelete(item) : null,
      // An item that cannot move is neither a drag source nor a drop
      // target, so nothing can displace it either.
      onMove: widget.onMove == null || !canMove ? null : _move,
      onDragStarted: () => _setDragActive(true),
      onDragEnded: () => _setDragActive(false),
      overlayWrapper: widget.overlayWrapper,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DeferredPointerHandler(
      child: Grid(
        key: _gridKey,
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
        mainAxisExtent: widget.mainAxisExtent,
        children: [
          for (final (index, item) in widget.items.indexed)
            GridItem(
              key: ValueKey(widget.keyOf(item)),
              crossAxisCellCount: math.min(
                widget.crossAxisCellCountOf(item),
                widget.crossAxisCount,
              ),
              mainAxisCellCount: widget.mainAxisCellCountOf?.call(item),
              child: _FlipTile(
                gridKey: _gridKey,
                animate: !_dragActive,
                child: _buildTile(context, item, index),
              ),
            ),
        ],
      ),
    );
  }
}

class _FlipTile extends StatefulWidget {
  final GlobalKey gridKey;
  final Widget child;

  /// When false, relocations apply instantly with no slide: the
  /// tile is painted exactly in its layout cell, never over a
  /// neighbour. Used while a drag is in flight (T343).
  final bool animate;

  const _FlipTile({
    required this.gridKey,
    required this.child,
    this.animate = true,
  });

  @override
  State<_FlipTile> createState() => _FlipTileState();
}

class _FlipTileState extends State<_FlipTile>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
    value: 1,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  Offset? _last;
  Offset _from = Offset.zero;

  Offset get _offset =>
      Offset.lerp(_from, Offset.zero, _curve.value) ?? Offset.zero;

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FlipTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate && !widget.animate) {
      // A drag just started: settle any in-flight slide into the
      // layout cell at once, so nothing keeps gliding over its
      // neighbours while the finger is down.
      _controller.stop();
      _controller.value = 1;
      _from = Offset.zero;
    }
  }

  void _check(Duration _) {
    if (!mounted) return;
    final box = context.findRenderObject();
    final grid = widget.gridKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || grid == null) return;
    final position = box.localToGlobal(Offset.zero, ancestor: grid);
    final last = _last;
    _last = position;
    if (!widget.animate) return;
    if (last == null || (last - position).distance < 0.5) return;
    _from = _offset + last - position;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_check);
    return AnimatedBuilder(
      animation: _curve,
      builder: (_, child) => Transform.translate(offset: _offset, child: child),
      child: widget.child,
    );
  }
}

class _EditTile<T extends Object> extends StatelessWidget {
  final T item;
  final Object Function(T item) keyOf;
  final Animation<double> shake;
  final double phase;
  final int cells;
  final VoidCallback? onResize;
  final VoidCallback? onDelete;
  final void Function(T from, T to)? onMove;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final EditableGridWrapper? overlayWrapper;
  final Widget child;

  const _EditTile({
    required this.item,
    required this.keyOf,
    required this.shake,
    required this.phase,
    required this.cells,
    required this.onResize,
    required this.onDelete,
    required this.onMove,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.overlayWrapper,
    required this.child,
  });

  Widget _badge(BuildContext context, IconData icon, Color color, Color fg) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, size: 13, color: fg),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isTv = globalState.isAndroidTV;
    final onResize = this.onResize;
    final onDelete = this.onDelete;
    final content = AbsorbPointer(child: child);
    final tappable = isTv
        ? FocusStateBuilder(
            builder: (context, focused) => DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: focused
                    ? Border.all(color: colorScheme.primary, width: 2.5)
                    : null,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onDelete ?? onResize,
                child: ExcludeFocus(child: content),
              ),
            ),
          )
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onResize,
            child: content,
          );
    final decorated = Stack(
      clipBehavior: Clip.none,
      children: [
        tappable,
        if (onResize != null)
          PositionedDirectional(
            top: 6,
            end: 6,
            child: IgnorePointer(
              child: _badge(
                context,
                Icons.open_in_full_rounded,
                colorScheme.primary,
                colorScheme.onPrimary,
              ),
            ),
          ),
        if (onDelete != null)
          PositionedDirectional(
            top: -8,
            start: -8,
            child: DeferPointer(
              child: GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: _badge(
                    context,
                    Icons.close_rounded,
                    colorScheme.error,
                    colorScheme.onError,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    final jiggle = AnimatedBuilder(
      animation: shake,
      builder: (_, child) => Transform.rotate(
        angle: math.sin(shake.value * math.pi + phase) * 0.012 / cells,
        child: child,
      ),
      child: decorated,
    );
    final onMove = this.onMove;
    if (onMove == null || isTv) return jiggle;
    final target = DragTarget<T>(
      onWillAcceptWithDetails: (details) {
        if (keyOf(details.data) != keyOf(item)) onMove(details.data, item);
        return false;
      },
      builder: (_, _, _) => jiggle,
    );
    final feedback = Builder(
      builder: (_) {
        final box = context.findRenderObject();
        final size = box is RenderBox && box.hasSize ? box.size : null;
        Widget lifted = Transform.scale(
          scale: 1.04,
          child: SizedBox(
            width: size?.width,
            height: size?.height,
            child: AbsorbPointer(child: child),
          ),
        );
        lifted = overlayWrapper?.call(lifted) ?? lifted;
        return Material(type: MaterialType.transparency, child: lifted);
      },
    );
    // T343: the drag origin keeps an empty slot marker, never a
    // copy of the tile. The old placeholder repainted the full
    // content at 30% opacity under the feedback's full copy — two
    // text-bearing images of the same tile at once, and when a
    // hover-reorder moved the origin cell the ghost copy slid
    // across its neighbours. The dragged tile now exists exactly
    // once: in the feedback.
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(commonCardRadius),
      ),
      child: const SizedBox.expand(),
    );
    final onDragStarted = this.onDragStarted;
    final onDragEnded = this.onDragEnded;
    return system.isDesktop
        ? Draggable<T>(
            data: item,
            feedback: feedback,
            childWhenDragging: placeholder,
            onDragStarted: onDragStarted,
            onDraggableCanceled: (_, _) => onDragEnded?.call(),
            onDragEnd: (_) => onDragEnded?.call(),
            child: target,
          )
        : LongPressDraggable<T>(
            data: item,
            delay: const Duration(milliseconds: 200),
            feedback: feedback,
            childWhenDragging: placeholder,
            onDragStarted: onDragStarted,
            onDraggableCanceled: (_, _) => onDragEnded?.call(),
            onDragEnd: (_) => onDragEnded?.call(),
            child: target,
          );
  }
}
