import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// T114: health of the node traffic currently exits through, shown next
/// to the outbound-mode card on the dashboard. The lamp never guesses:
/// green only on a measured-good delay, red only on a measured failure,
/// grey whenever there is no measurement to stand on (core stopped,
/// node untested, test in flight, or a direct exit).
enum NodeHealth { available, unavailable, unknown }

/// Pure three-state resolution, fed with the same delay face the proxy
/// cards use (null = untested, 0 = test in flight, >0 = measured good,
/// <0 = measured failure).
NodeHealth resolveNodeHealth({required bool coreRunning, required int? delay}) {
  if (!coreRunning) return NodeHealth.unknown;
  if (delay == null || delay == 0) return NodeHealth.unknown;
  return delay > 0 ? NodeHealth.available : NodeHealth.unavailable;
}

/// Resolve the current exit node by walking the GLOBAL group's
/// selection chain through nested groups, mirroring how the core itself
/// resolves the default exit. Returns the leaf node name plus the test
/// URL of the group that directly contains it (the URL its delay is
/// measured against), or null when there is no proxy exit to report
/// (no GLOBAL group, empty selection, a DIRECT pick, or a cycle).
({String name, String? testUrl})? resolveCurrentExitNode({
  required List<Group> groups,
  required SelectedMap selectedMap,
}) {
  final byName = {for (final group in groups) group.name: group};
  final global = byName['GLOBAL'];
  if (global == null) return null;
  var group = global;
  final visited = <String>{};
  while (visited.add(group.name)) {
    final selected = group.getCurrentSelectedName(
      selectedMap[group.name] ?? '',
    );
    if (selected.isEmpty || selected == 'DIRECT') return null;
    final next = byName[selected];
    if (next == null) {
      return (name: selected, testUrl: group.testUrl);
    }
    group = next;
  }
  return null;
}

class CurrentNodeHealthLamp extends ConsumerWidget {
  const CurrentNodeHealthLamp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStart = ref.watch(runTimeProvider.select((value) => value != null));
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    var health = NodeHealth.unknown;
    if (isStart && mode != Mode.direct) {
      final groups = ref.watch(groupsProvider);
      final selectedMap = ref.watch(selectedMapProvider);
      final exit = resolveCurrentExitNode(
        groups: groups,
        selectedMap: selectedMap,
      );
      if (exit != null) {
        final delay = ref.watch(
          getDelayProvider(proxyName: exit.name, testUrl: exit.testUrl),
        );
        health = resolveNodeHealth(coreRunning: isStart, delay: delay);
      }
    }
    final colorScheme = context.colorScheme;
    // T115 spec 3.5.1: the health lamp wears the family status
    // tokens (success / error / secondary text).
    final palette = context.zodiac.palette;
    final (dotColor, label, textColor) = switch (health) {
      NodeHealth.available => (
        palette.success,
        appLocalizations.currentNodeAvailable,
        colorScheme.onSurfaceVariant,
      ),
      NodeHealth.unavailable => (
        colorScheme.error,
        appLocalizations.currentNodeUnavailable,
        colorScheme.error,
      ),
      NodeHealth.unknown => (
        colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
        appLocalizations.currentNodeUnknown,
        colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(color: textColor),
        ),
      ],
    );
  }
}
