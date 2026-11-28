import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'node_status_light.dart';
import 'profile_info.dart';

/// The exit-node tile (T337): the hero-era exit readout as an
/// editable-grid tile. The node name takes the value line on its
/// own (single line, gracefully ellipsized when long) and the
/// chain line under it carries the node status light and the
/// group · region chain info. Tapping the card opens the same
/// group sheet the hero's exit card opened (the two-step node
/// selection, unchanged); tapping the light runs the same global
/// linked delay test it ran inside the merged card — the light
/// keeps its own tap, exactly as it did there.
class ExitNode extends ConsumerWidget {
  const ExitNode({super.key, this.size});

  final DashboardTileSize? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(patchClashConfigProvider.select((s) => s.mode));
    final isDirect = mode == Mode.direct;
    final groupName = isDirect ? null : ref.watch(currentMainGroupNameProvider);
    final nodeName = isDirect
        ? appLocalizations.direct
        : groupName == null
        ? ''
        : ref.watch(
            getProxyCardStateProvider(
              groupName,
            ).select((state) => state.proxyName),
          );
    return ReadoutTileCard(
      label: appLocalizations.speedTestExitNode,
      value: nodeName,
      footnote: _ChainLine(groupName: groupName),
      onTap: groupName == null
          ? null
          : () => showGroupProxySheet(context, groupName),
    );
  }
}

/// The chain line: status light, then the chain info — the main
/// group the exit hangs off and the region the network detection
/// last resolved it to (country · city, the same DetectionState
/// the network detection tile renders). Empty parts drop out.
class _ChainLine extends StatelessWidget {
  const _ChainLine({required this.groupName});

  final String? groupName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const NodeStatusLight(compact: true),
        const SizedBox(width: 2),
        Expanded(
          child: ValueListenableBuilder<NetworkDetectionState>(
            valueListenable: detectionState.state,
            builder: (_, state, _) {
              final ipInfo = state.ipInfo;
              final location = ipInfo == null
                  ? ''
                  : [
                      ipInfo.country,
                      if (ipInfo.city != ipInfo.country) ipInfo.city,
                    ].where((item) => item?.isNotEmpty ?? false).join(' · ');
              final text = [
                ?groupName,
                if (location.isNotEmpty) location,
              ].join(' · ');
              return Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
