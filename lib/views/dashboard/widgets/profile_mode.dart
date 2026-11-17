import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'node_status_light.dart';
import 'profile_info.dart';
import 'quick_options.dart';

const List<double> _emptySegments = [0];

/// The merged home card (T147): the former profile card and the former
/// running-mode card as one dashboard widget, still added, removed and
/// resized as a single grid item. The two zones keep every function of
/// the cards they replace —
///
/// * profile zone: name with the switch-sheet entry, last-update time,
///   subscription usage with its segment bar and the current selection
///   (node name + delay);
/// * mode zone: the node status light, the VPN / system-proxy chips
///   and the rule / global / direct mode switch.
///
/// One speed test only (user directive): the light is the card's sole
/// test trigger and runs the shared global linked delay test (T131,
/// measure-only). The current selection's delay number reads the very
/// same delay data source the light reads, so the two always agree.
/// The upstream per-group test entry the old profile card carried into
/// its group sheet is not part of this card. The card carries no
/// refresh action either (T149): subscription refresh lives on the
/// profiles page, because a refresh makes the core re-test delays
/// through the upstream path and would read as a second test entry
/// on this card.
class ProfileModeCard extends ConsumerWidget {
  final DashboardTileSize? size;

  const ProfileModeCard({super.key, this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = this.size ?? DashboardTileSize.large;
    final tall = size == DashboardTileSize.tall;
    return SizedBox(
      height: getWidgetHeight(context, size.rows),
      child: CommonCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Expanded(child: _ProfileZone(tall: tall)),
            Divider(
              height: 1,
              thickness: 1,
              indent: 16.ap,
              endIndent: 16.ap,
              color: context.colorScheme.outlineVariant.withValues(
                alpha: 0.5,
              ),
            ),
            _ModeZone(tall: tall),
          ],
        ),
      ),
    );
  }
}

class _ProfileZone extends ConsumerWidget {
  final bool tall;

  const _ProfileZone({required this.tall});

  Widget _nameRow(
    BuildContext context,
    Profile profile,
    TextStyle? style,
  ) {
    return _TapArea(
      onTap: () => showProfileSwitchSheet(context),
      child: _ProfileName(name: profile.label ?? profile.id, style: style),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final colorScheme = context.colorScheme;
    if (profile == null) {
      return InkWell(
        onTap: () => globalState.appController.toProfiles(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.ap, 8.ap, 16.ap, 8.ap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appLocalizations.profile,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                appLocalizations.nullProfileDesc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final usage = ProfileUsage.of(profile);
    final segments = usage?.segments ?? _emptySegments;
    final subtitle = [
      ?profile.lastUpdateDate?.lastUpdateTimeDesc,
      ?profile.usageExpireText(usage),
    ].join(' · ');
    // Compact two-row form, like the former wide profile card: the
    // name row doubles as the zone header, so the merged card's two
    // zones fit the two grid rows the pair of cards used to occupy.
    return Padding(
      padding: EdgeInsets.fromLTRB(16.ap, 6.ap, 16.ap, 6.ap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _nameRow(
                    context,
                    profile,
                    context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // The status light lives at the card's top-right (T211):
              // in the mode header row it crowded out the running-mode
              // label on narrow screens.
              tall
                  ? const NodeStatusLight(compact: true)
                  : const NodeStatusLight(),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                color: usage?.isExpired == true
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
          if (tall) ...[
            Text(
              usage?.usageText ?? appLocalizations.noUsageData,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium?.copyWith(
                color: usage == null ? colorScheme.onSurfaceVariant : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            const _CurrentNode(style: _NodeStyle.plain),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        usage?.usageText ?? appLocalizations.noUsageData,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: usage == null
                              ? colorScheme.onSurfaceVariant
                              : null,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (segments.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        UsageSegmentBar(segments: segments, height: 4),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: const _CurrentNode(style: _NodeStyle.pill),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ModeZone extends StatelessWidget {
  final bool tall;

  const _ModeZone({required this.tall});

  @override
  Widget build(BuildContext context) {
    // The status light moved to the profile zone's top-right (T211),
    // so this header row carries only the mode label and, in the wide
    // form, the status chips; the segmented mode switch is shared
    // with the tall form, which does not repeat the chips.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InfoHeader(
          padding: EdgeInsets.fromLTRB(16.ap, 9.ap, 12.ap, 0),
          info: Info(
            label: appLocalizations.runningMode,
            iconData: Icons.call_split_sharp,
          ),
          actions: tall ? const [] : const [_OutboundStatusChips()],
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(10.ap, 6.ap, 10.ap, 8.ap),
          child: SizedBox(
            height: 34.ap,
            child: Consumer(
              builder: (_, ref, _) {
                final mode = ref.watch(
                  patchClashConfigProvider.select((state) => state.mode),
                );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in Mode.values) ...[
                      if (item != Mode.values.first) const SizedBox(width: 2),
                      Expanded(
                        child: _OutboundModeButton(
                          mode: item,
                          selected: item == mode,
                          first: item == Mode.values.first,
                          last: item == Mode.values.last,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _OutboundModeButton extends StatelessWidget {
  final Mode mode;
  final bool selected;
  final bool first;
  final bool last;

  const _OutboundModeButton({
    required this.mode,
    required this.selected,
    required this.first,
    required this.last,
  });

  IconData get _icon => switch (mode) {
    Mode.rule => Icons.list_alt_rounded,
    Mode.global => Icons.language_rounded,
    Mode.direct => Icons.east_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;
    final foreground = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.82);
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = Radius.circular(constraints.maxHeight / 2);
        const inner = Radius.circular(8);
        final shape = RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            left: selected || first ? full : inner,
            right: selected || last ? full : inner,
          ),
        );
        return Focus(
          child: Builder(
            builder: (context) {
              final isFocused =
                  globalState.isAndroidTV && Focus.of(context).hasFocus;
              return AnimatedContainer(
                duration: midDuration,
                curve: Curves.easeOutCubic,
                decoration: ShapeDecoration(
                  color: selected
                      ? colorScheme.primary.withValues(
                          alpha: isLight ? 0.12 : 0.20,
                        )
                      : colorScheme.onSurface.withValues(
                          alpha: isLight ? 0.04 : 0.06,
                        ),
                  shape: shape.copyWith(
                    side: isFocused
                        ? BorderSide(color: colorScheme.primary, width: 2)
                        : BorderSide.none,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: shape,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => globalState.appController.changeMode(mode),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_icon, size: 17, color: foreground),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            Intl.message(mode.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: foreground,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _OutboundStatusChips extends ConsumerWidget {
  const _OutboundStatusChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStart = ref.watch(runTimeProvider.select((value) => value != null));
    final realTunEnable = ref.watch(realTunEnableProvider);
    final (tunEnable, systemProxyEnable) = system.isAndroid
        ? ref.watch(
            vpnSettingProvider.select(
              (state) => (state.enable, state.systemProxy),
            ),
          )
        : (
            ref.watch(
              patchClashConfigProvider.select((state) => state.tun.enable),
            ),
            ref.watch(
              networkSettingProvider.select((state) => state.systemProxy),
            ),
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusChip(
          label: system.isAndroid ? 'VPN' : 'TUN',
          active: isStart && tunEnable && (system.isAndroid || realTunEnable),
          onTap: () =>
              system.isAndroid ? showVpnSheet(context) : showTunSheet(context),
        ),
        const SizedBox(width: 6),
        _StatusChip(
          label: appLocalizations.systemProxy,
          active: isStart && systemProxyEnable,
          onTap: () => showSystemProxySheet(context),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;
    final color = active
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.55);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: midDuration,
          padding: const EdgeInsets.fromLTRB(7, 3, 8, 3),
          decoration: BoxDecoration(
            color: active
                ? colorScheme.primary.withValues(alpha: isLight ? 0.12 : 0.20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? colorScheme.primary.withValues(alpha: isLight ? 0.28 : 0.36)
                  : colorScheme.outlineVariant.withValues(
                      alpha: isLight ? 0.9 : 0.6,
                    ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: midDuration,
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? colorScheme.primary : Colors.transparent,
                  border: Border.all(
                    color: active
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapArea extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _TapArea({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return Transform.translate(
      offset: const Offset(-6, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ProfileName extends StatelessWidget {
  final String name;
  final TextStyle? style;

  const _ProfileName({required this.name, this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: EmojiText(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        const SizedBox(width: 2),
        Icon(
          Icons.unfold_more,
          size: 16,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

enum _NodeStyle { pill, grouped, plain }

class _CurrentNode extends ConsumerWidget {
  final _NodeStyle style;

  const _CurrentNode({required this.style});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDirect = ref.watch(
      patchClashConfigProvider.select((state) => state.mode == Mode.direct),
    );
    final groupName = ref.watch(currentMainGroupNameProvider);
    if (isDirect) {
      return _NodeLabel(style: style, nodeName: appLocalizations.direct);
    }
    if (groupName == null) return const SizedBox.shrink();
    return _GroupNode(style: style, groupName: groupName);
  }
}

class _GroupNode extends ConsumerWidget {
  final _NodeStyle style;
  final String groupName;

  const _GroupNode({required this.style, required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeName = ref.watch(
      getProxyCardStateProvider(groupName).select((state) => state.proxyName),
    );
    // The one shared delay data source: the same getDelayProvider the
    // status light reads, fed by the global linked test (T131).
    final delay = ref.watch(getDelayProvider(proxyName: groupName));
    return _NodeLabel(
      style: style,
      nodeName: nodeName,
      delay: delay,
      onTap: () => showGroupProxySheet(context, groupName),
    );
  }
}

class _NodeLabel extends StatelessWidget {
  final _NodeStyle style;
  final String nodeName;
  final int? delay;
  final VoidCallback? onTap;

  const _NodeLabel({
    required this.style,
    required this.nodeName,
    this.delay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final delay = this.delay;
    final isPlain = style == _NodeStyle.plain;
    final row = Row(
      mainAxisSize: style == _NodeStyle.pill
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: [
        if (style == _NodeStyle.grouped) ...[
          Text(
            appLocalizations.currentSelection,
            style: context.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
        Flexible(
          fit: isPlain ? FlexFit.tight : FlexFit.loose,
          child: EmojiText(
            nodeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: isPlain ? null : FontWeight.w600,
            ),
          ),
        ),
        if (delay != null) ...[
          const SizedBox(width: 8),
          Text(
            delay > 0 ? '$delay ms' : 'Timeout',
            style: context.textTheme.labelSmall?.copyWith(
              color: zodiacDelayColor(context.zodiac?.variant, delay),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
    if (isPlain) return _TapArea(onTap: onTap, child: row);
    final radius = BorderRadius.circular(10);
    return Material(
      color: colorScheme.primary.withValues(alpha: 0.08),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: row,
        ),
      ),
    );
  }
}

/// Subscription usage segment bar, shared with the profile switch
/// sheet's items.
class UsageSegmentBar extends StatelessWidget {
  final List<double> segments;
  final double height;

  const UsageSegmentBar({
    super.key,
    required this.segments,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, segment) in segments.indexed) ...[
          if (index > 0) const SizedBox(width: 3),
          Expanded(child: _UsageBar(value: segment, height: height)),
        ],
      ],
    );
  }
}

class _UsageBar extends StatelessWidget {
  final double value;
  final double height;

  const _UsageBar({required this.value, required this.height});

  @override
  Widget build(BuildContext context) {
    final primary = context.colorScheme.primary;
    final radius = BorderRadius.circular(height / 2);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        alignment: Alignment.centerLeft,
        color: primary.withValues(alpha: 0.15),
        child: FractionallySizedBox(
          widthFactor: value,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: primary, borderRadius: radius),
          ),
        ),
      ),
    );
  }
}
