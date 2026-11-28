import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/config/network.dart';
import 'package:angelamihomo/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showOutboundModeSheet(BuildContext context) {
  showSheet(
    context: context,
    props: const SheetProps(expandable: false),
    builder: (_, type) {
      return AdaptiveSheetScaffold(
        type: type,
        body: Consumer(
          builder: (context, ref, _) {
            final currentMode = ref.watch(
              patchClashConfigProvider.select((state) => state.mode),
            );
            return generateListView(
              shrinkWrap: true,
              generateSection(
                items: [
                  for (final item in Mode.values)
                    ListItem(
                      leading: Icon(switch (item) {
                        Mode.rule => Icons.alt_route_rounded,
                        Mode.global => Icons.language_rounded,
                        Mode.direct => Icons.east_rounded,
                      }),
                      title: Text(Intl.message(item.name)),
                      trailing: item == currentMode
                          ? Icon(
                              Icons.check_rounded,
                              color: context.colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        if (system.isAndroid &&
                            ref.read(
                              appSettingProvider.select(
                                (s) => s.enableNavBarHapticFeedback,
                              ),
                            )) {
                          HapticFeedback.selectionClick();
                        }
                        globalState.appController.changeMode(item);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            );
          },
        ),
        title: appLocalizations.outboundMode,
      );
    },
  );
}

void showTunSheet(BuildContext context) {
  showSheet(
    context: context,
    props: const SheetProps(expandable: false),
    builder: (_, type) {
      return AdaptiveSheetScaffold(
        type: type,
        body: generateListView(
          shrinkWrap: true,
          generateSection(
            items: [
              if (system.isDesktop) const TUNItem(),
              if (system.isDesktop) const DnsHijackItem(),
              if (!system.isAndroid) const StrictRouteItem(),
              const IcmpForwardingItem(),
              if (system.isDesktop) const NetworkInterfaceItem(),
              if (!AppIdentity.isLite) const TunStackItem(),
            ],
          ),
        ),
        title: appLocalizations.tun,
      );
    },
  );
}

void showVpnSheet(BuildContext context) {
  showSheet(
    context: context,
    props: const SheetProps(expandable: false),
    builder: (_, type) {
      return AdaptiveSheetScaffold(
        type: type,
        body: generateListView(
          shrinkWrap: true,
          generateSection(
            items: [
              const VPNItem(),
              if (!system.isAndroid) const StrictRouteItem(),
              const IcmpForwardingItem(),
              if (!AppIdentity.isLite) const TunStackItem(),
            ],
          ),
        ),
        title: 'VPN',
      );
    },
  );
}

void showSystemProxySheet(BuildContext context) {
  showSheet(
    context: context,
    props: const SheetProps(expandable: false),
    builder: (_, type) {
      return AdaptiveSheetScaffold(
        type: type,
        body: generateListView(
          shrinkWrap: true,
          generateSection(
            items: [
              system.isAndroid
                  ? const VpnSystemProxyItem()
                  : const SystemProxyItem(),
              const BypassDomainItem(),
            ],
          ),
        ),
        title: appLocalizations.systemProxy,
      );
    },
  );
}

class TUNButton extends StatelessWidget {
  const TUNButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(context, 1),
      child: CommonCard(
        onPressed: () => showTunSheet(context),
        info: Info(
          label: appLocalizations.tun,
          iconData: Icons.stacked_line_chart,
        ),
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 4, bottom: 8, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 1,
                child: TooltipText(
                  text: Text(
                    appLocalizations.options,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.adjustSize(-2).toLight,
                  ),
                ),
              ),
              Consumer(
                builder: (_, ref, _) {
                  final enable = ref.watch(
                    patchClashConfigProvider.select(
                      (state) => state.tun.enable,
                    ),
                  );

                  return Switch(
                    value: enable,
                    onChanged: (value) {
                      ref
                          .read(patchClashConfigProvider.notifier)
                          .updateState(
                            (state) => state.copyWith.tun(enable: value),
                          );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SystemProxyButton extends StatelessWidget {
  const SystemProxyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(context, 1),
      child: CommonCard(
        onPressed: () => showSystemProxySheet(context),
        info: Info(
          label: appLocalizations.systemProxy,
          iconData: Icons.shuffle,
        ),
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 4, bottom: 8, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 1,
                child: TooltipText(
                  text: Text(
                    appLocalizations.options,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.adjustSize(-2).toLight,
                  ),
                ),
              ),
              Consumer(
                builder: (_, ref, _) {
                  final systemProxy = ref.watch(
                    networkSettingProvider.select((state) => state.systemProxy),
                  );

                  return Switch(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: systemProxy,
                    onChanged: (value) {
                      ref
                          .read(networkSettingProvider.notifier)
                          .updateState(
                            (state) => state.copyWith(systemProxy: value),
                          );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VpnButton extends StatelessWidget {
  const VpnButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(context, 1),
      child: CommonCard(
        onPressed: () => showVpnSheet(context),
        info: Info(label: 'VPN', iconData: Icons.stacked_line_chart),
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 4, bottom: 8, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 1,
                child: TooltipText(
                  text: Text(
                    appLocalizations.options,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.adjustSize(-2).toLight,
                  ),
                ),
              ),
              Consumer(
                builder: (_, ref, _) {
                  final enable = ref.watch(
                    vpnSettingProvider.select((state) => state.enable),
                  );
                  return Switch(
                    value: enable,
                    onChanged: (value) {
                      ref
                          .read(vpnSettingProvider.notifier)
                          .updateState(
                            (state) => state.copyWith(enable: value),
                          );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The running-mode status chips (TUN/VPN and system proxy: state
/// dot plus a tap into the very same sheets the quick-option
/// buttons open). They lived on the merged profile/mode card's
/// mode zone until T337 retired that card into the star-rail hero;
/// the chips moved here beside the sheets they open — same state
/// sources, same destinations, presentation only.
class OutboundStatusChips extends ConsumerWidget {
  const OutboundStatusChips({super.key});

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
        OutboundStatusChip(
          label: system.isAndroid ? 'VPN' : 'TUN',
          active: isStart && tunEnable && (system.isAndroid || realTunEnable),
          onTap: () =>
              system.isAndroid ? showVpnSheet(context) : showTunSheet(context),
        ),
        const SizedBox(width: 6),
        OutboundStatusChip(
          label: appLocalizations.systemProxy,
          active: isStart && systemProxyEnable,
          onTap: () => showSystemProxySheet(context),
        ),
      ],
    );
  }
}

class OutboundStatusChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const OutboundStatusChip({
    super.key,
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
