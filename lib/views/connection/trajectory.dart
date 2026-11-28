import 'package:angelamihomo/common/common.dart';
import 'package:material_ui/material_ui.dart';

/// T334 batch 4: the trajectory timeline for the connections page
/// (frozen design: files/ui-redesign/DESIGN-LANGUAGE.md, screen 4 —
/// signature interaction 3). Active connections are grouped by the
/// process that owns them; one vertical rail line runs down the
/// left of the list and every group header is a glowing node on
/// that line.
///
/// The grouping is a pure presentation transform of the very list
/// the filtered providers already produce: same items, same order
/// inside each group, groups in first-appearance order. Nothing
/// here touches connection state, filtering, sorting or closing —
/// rows are still the stock TrackerInfoItem with the stock block
/// button, and the closed tab keeps its chronological flat list
/// (its scroll anchoring is built on that order).
class ConnectionProcessGroup<T> {
  /// The grouping key: TrackerInfo.metadata.process, verbatim.
  /// Empty when the core did not attribute the flow to a process.
  final String process;
  final List<T> items;

  const ConnectionProcessGroup({required this.process, required this.items});
}

/// Groups [items] by [processOf], preserving the input order both
/// across groups (first appearance wins) and inside each group.
List<ConnectionProcessGroup<T>> groupConnectionsByProcess<T>(
  List<T> items,
  String Function(T item) processOf,
) {
  final order = <String>[];
  final byProcess = <String, List<T>>{};
  for (final item in items) {
    final process = processOf(item);
    final bucket = byProcess[process];
    if (bucket == null) {
      byProcess[process] = [item];
      order.add(process);
    } else {
      bucket.add(item);
    }
  }
  return [
    for (final process in order)
      ConnectionProcessGroup(process: process, items: byProcess[process]!),
  ];
}

/// Paints one vertical segment of the trajectory rail: a 2dp line
/// in the gutter plus, for group headers, the glowing node the
/// line strings together. Segments stack contiguously inside the
/// scroll view, so the per-row segments compose into one unbroken
/// line; the first header starts its line at the node instead of
/// the row's top edge.
class TrajectoryRailPainter extends CustomPainter {
  /// Width of the gutter the rail lives in; rows indent their
  /// content by this much.
  static const double gutterWidth = 40;

  /// X of the rail line inside the gutter.
  static const double lineCenter = 20;

  final Color lineColor;
  final Color? nodeColor;
  final bool lineAboveNode;

  const TrajectoryRailPainter({
    required this.lineColor,
    this.nodeColor,
    this.lineAboveNode = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(lineCenter, size.height / 2);
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final top = nodeColor != null && !lineAboveNode ? center.dy : 0.0;
    canvas.drawLine(Offset(lineCenter, top), Offset(lineCenter, size.height), linePaint);
    final node = nodeColor;
    if (node != null) {
      // Halo, orbit ring, core — the batch 3 rail-dot vocabulary
      // (lit dot + small ring + glow) at group scale.
      canvas.drawCircle(
        center,
        11,
        Paint()..color = node.withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        center,
        8.5,
        Paint()
          ..color = node.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(center, 4.5, Paint()..color = node);
    }
  }

  @override
  bool shouldRepaint(TrajectoryRailPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.nodeColor != nodeColor ||
        oldDelegate.lineAboveNode != lineAboveNode;
  }
}

/// One group header on the timeline: rail node, the process icon
/// (the same widget the rows use, with the same tap-to-filter
/// behaviour), the app name and the group's connection count.
class TrajectoryGroupHeader extends StatelessWidget {
  final String process;
  final int count;
  final bool isFirst;
  final Widget? icon;

  const TrajectoryGroupHeader({
    super.key,
    required this.process,
    required this.count,
    required this.isFirst,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tokens =
        context.starRail ??
        StarRailTokens.forBrightness(Theme.of(context).brightness);
    final label = process.isEmpty ? appLocalizations.other : process;
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: TrajectoryRailPainter.gutterWidth,
            child: CustomPaint(
              painter: TrajectoryRailPainter(
                lineColor: tokens.glowLine.withValues(alpha: 0.35),
                nodeColor: tokens.secondary,
                lineAboveNode: !isFirst,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: TrajectoryRailPainter.gutterWidth,
              right: 16,
            ),
            child: Row(
              children: [
                ?icon,
                if (icon != null) const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.itemsCount(count),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps one connection row with its rail segment: the line runs
/// behind the row's gutter while the row itself keeps its stock
/// layout and width behaviour inside the remaining space.
class TrajectoryRailRow extends StatelessWidget {
  final Widget child;

  const TrajectoryRailRow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens =
        context.starRail ??
        StarRailTokens.forBrightness(Theme.of(context).brightness);
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: TrajectoryRailPainter.gutterWidth,
          child: CustomPaint(
            painter: TrajectoryRailPainter(
              lineColor: tokens.glowLine.withValues(alpha: 0.35),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: TrajectoryRailPainter.gutterWidth),
          child: child,
        ),
      ],
    );
  }
}
