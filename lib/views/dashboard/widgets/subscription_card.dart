import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/pages/speed_test.dart';
import 'package:angelamihomo/pages/toolbox/traffic_stats.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'profile_info.dart';

/// The subscription tile (T337): the hero-era subscription card
/// as an editable-grid tile — name / updated / source / expiry
/// subtitle, tap for the switch sheet, the zodiac-wheel refresh
/// button, the plan usage figure and segment bar, the session
/// traffic totals, and the in-card speed-test button (a card
/// button, never a floating one). Every action is the merged
/// card's original helper on the original flow; only the surface
/// moved, from the fixed hero into the grid the user arranges.
class SubscriptionCard extends ConsumerWidget {
  const SubscriptionCard({super.key, this.size});

  /// Grid size slot (T337): the card joins the editable grid as
  /// a tile; its content is the hero-era subscription card plus
  /// the session totals row below.
  final DashboardTileSize? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    if (profile == null) {
      return CommonCard(
        radius: commonCardRadius,
        onPressed: () => globalState.appController.toProfiles(),
        solidSurface: true,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appLocalizations.profile,
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              appLocalizations.nullProfileDesc,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final usage = ProfileUsage.of(profile);
    final segments = usage?.segments ?? const <double>[];
    final subtitle = [
      ?profile.lastUpdateDate?.lastUpdateTimeDesc,
      ?usage?.primarySourceName,
      ?profile.usageExpireText(usage),
    ].join(' · ');
    final canRefresh =
        !profile.isUpdating &&
        !(profile.type == ProfileType.file &&
            profile.providerSubscriptions.isEmpty);

    return CommonCard(
      radius: commonCardRadius,
      solidSurface: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: canRefresh
                    ? () => refreshProfileSubscription(context, ref, profile)
                    : null,
                tooltip: appLocalizations.update,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                  maxWidth: 28,
                  maxHeight: 28,
                ),
                icon: ZodiacWheelUpdateIcon(
                  updating: profile.isUpdating,
                  dimmed: !canRefresh && !profile.isUpdating,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => showProfileSwitchSheet(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EmojiText(
                          profile.label ?? profile.id,
                          maxLines: 2,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: context.textTheme.labelMedium?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (usage != null) ...[
            Row(
              children: [
                Text(
                  appLocalizations.trafficUsage,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  usage.cardUsageText,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            if (segments.isNotEmpty) ...[
              const SizedBox(height: 6),
              UsageSegmentBar(segments: segments, height: 4),
            ],
          ] else
            Text(
              appLocalizations.noUsageData,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          // T337: the traffic statistics, complete inside this
          // card — the session totals the traffic-usage tile used
          // to present on its own (same totalTrafficProvider, same
          // 1 s cadence, same stats page behind the total). The
          // standalone tile stays in the catalog as an option;
          // the default layout shows the numbers here, once.
          ValueListenableBuilder<int>(
            valueListenable: dashboardRefreshManager.tick1s,
            builder: (_, _, _) {
              final totalTraffic = ref.read(totalTrafficProvider);
              final up = totalTraffic.up;
              final down = totalTraffic.down;
              final total = TrafficValue(value: up.value + down.value);
              return Row(
                children: [
                  Expanded(
                    child: MiniReadout(
                      label: appLocalizations.upload,
                      value: up.show,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MiniReadout(
                      label: appLocalizations.download,
                      value: down.show,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MiniReadout(
                      label: appLocalizations.dashboardTotal,
                      value: total.show,
                      onTap: () =>
                          BaseNavigator.push(context, const TrafficStatsPage()),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => BaseNavigator.push(context, const SpeedTestPage()),
            icon: const Icon(Icons.speed_sharp, size: 19),
            label: Text(appLocalizations.speedTest),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(StarRailRadius.button),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
