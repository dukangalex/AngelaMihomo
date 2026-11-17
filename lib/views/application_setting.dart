import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/providers/config.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsageItem extends ConsumerWidget {
  const UsageItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final onlyStatisticsProxy = ref.watch(
      appSettingProvider.select((state) => state.onlyStatisticsProxy),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.onlyStatisticsProxy),
      subtitle: Text(appLocalizations.onlyStatisticsProxyDesc),
      delegate: SwitchDelegate(
        value: onlyStatisticsProxy,
        onChanged: (bool value) async {
          ref
              .read(appSettingProvider.notifier)
              .updateState(
                (state) => state.copyWith(onlyStatisticsProxy: value),
              );
        },
      ),
    );
  }
}

class AutoLaunchItem extends ConsumerWidget {
  const AutoLaunchItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoLaunch = ref.watch(
      appSettingProvider.select((state) => state.autoLaunch),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.autoLaunch),
      subtitle: Text(appLocalizations.autoLaunchDesc),
      delegate: SwitchDelegate(
        value: autoLaunch,
        onChanged: (bool value) {
          ref
              .read(appSettingProvider.notifier)
              .updateState((state) => state.copyWith(autoLaunch: value));
        },
      ),
    );
  }
}

class SilentLaunchItem extends ConsumerWidget {
  const SilentLaunchItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final silentLaunch = ref.watch(
      appSettingProvider.select((state) => state.silentLaunch),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.silentLaunch),
      subtitle: Text(appLocalizations.silentLaunchDesc),
      delegate: SwitchDelegate(
        value: silentLaunch,
        onChanged: (bool value) {
          ref
              .read(appSettingProvider.notifier)
              .updateState((state) => state.copyWith(silentLaunch: value));
        },
      ),
    );
  }
}

class AutoRunItem extends ConsumerWidget {
  const AutoRunItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoRun = ref.watch(
      appSettingProvider.select((state) => state.autoRun),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.autoRun),
      subtitle: Text(appLocalizations.autoRunDesc),
      delegate: SwitchDelegate(
        value: autoRun,
        onChanged: (bool value) {
          ref
              .read(appSettingProvider.notifier)
              .updateState((state) => state.copyWith(autoRun: value));
        },
      ),
    );
  }
}

class HiddenItem extends ConsumerWidget {
  const HiddenItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(
      appSettingProvider.select((state) => state.hidden),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.exclude),
      subtitle: Text(appLocalizations.excludeDesc),
      delegate: SwitchDelegate(
        value: hidden,
        onChanged: (value) {
          ref
              .read(appSettingProvider.notifier)
              .updateState((state) => state.copyWith(hidden: value));
        },
      ),
    );
  }
}

class KeepDockIconItem extends ConsumerWidget {
  const KeepDockIconItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keepDockIcon = ref.watch(
      appSettingProvider.select((state) => state.keepDockIcon),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.keepDockIcon),
      subtitle: Text(appLocalizations.keepDockIconDesc),
      delegate: SwitchDelegate(
        value: keepDockIcon,
        onChanged: (value) {
          ref
              .read(appSettingProvider.notifier)
              .updateState((state) => state.copyWith(keepDockIcon: value));
        },
      ),
    );
  }
}

class _SidebarFlyoutDialog extends StatefulWidget {
  final SidebarFlyoutDelay delay;
  final List<SidebarFlyoutEntry> entries;
  final bool outsideTools;

  const _SidebarFlyoutDialog({
    required this.delay,
    required this.entries,
    required this.outsideTools,
  });

  @override
  State<_SidebarFlyoutDialog> createState() => _SidebarFlyoutDialogState();
}

class _SidebarFlyoutDialogState extends State<_SidebarFlyoutDialog> {
  late SidebarFlyoutDelay _delay = widget.delay;
  late final _entries = widget.entries.toSet();
  late bool _outsideTools = widget.outsideTools;

  void _handleToggleEntry(SidebarFlyoutEntry entry) {
    if (_entries.length == 1 && _entries.contains(entry)) {
      return;
    }
    setState(() {
      if (!_entries.remove(entry)) {
        _entries.add(entry);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: appLocalizations.sidebarFlyout,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(appLocalizations.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop((
              delay: _delay,
              entries: SidebarFlyoutEntry.values
                  .where(_entries.contains)
                  .toList(),
              outsideTools: _outsideTools,
            ));
          },
          child: Text(appLocalizations.confirm),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalizations.sidebarFlyoutDelay,
            style: context.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentButtonGroup<SidebarFlyoutDelay>(
            options: [
              SegmentOption(
                value: SidebarFlyoutDelay.fast,
                label: appLocalizations.fast,
              ),
              SegmentOption(
                value: SidebarFlyoutDelay.standard,
                label: appLocalizations.standard,
              ),
              SegmentOption(
                value: SidebarFlyoutDelay.slow,
                label: appLocalizations.slow,
              ),
            ],
            selected: _delay,
            onSelected: (delay) => setState(() => _delay = delay),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(appLocalizations.sidebarFlyoutOutsideTools)),
              const SizedBox(width: 16),
              Switch(
                value: _outsideTools,
                onChanged: (value) => setState(() => _outsideTools = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            appLocalizations.sidebarFlyoutEntries,
            style: context.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in SidebarFlyoutEntry.supportedValues)
                FilterChip(
                  selected: _entries.contains(entry),
                  showCheckmark: false,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(entry.localizedName),
                  onSelected: (_) => _handleToggleEntry(entry),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class SidebarFlyoutItem extends ConsumerWidget {
  const SidebarFlyoutItem({super.key});

  Future<void> _showSettingDialog(WidgetRef ref) async {
    final appSetting = ref.read(appSettingProvider);
    final result = await globalState
        .showCommonDialog<
          ({
            SidebarFlyoutDelay delay,
            List<SidebarFlyoutEntry> entries,
            bool outsideTools,
          })
        >(
          child: _SidebarFlyoutDialog(
            delay: appSetting.sidebarFlyoutDelay,
            entries: appSetting.sidebarFlyoutEntries,
            outsideTools: appSetting.sidebarFlyoutOutsideTools,
          ),
        );
    if (result == null) return;
    ref
        .read(appSettingProvider.notifier)
        .updateState(
          (state) => state.copyWith(
            sidebarFlyoutDelay: result.delay,
            sidebarFlyoutEntries: result.entries,
            sidebarFlyoutOutsideTools: result.outsideTools,
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidebarFlyout = ref.watch(
      appSettingProvider.select((state) => state.sidebarFlyout),
    );
    return ListItem.switchItem(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(appLocalizations.sidebarFlyout),
          TitleSettingButton(
            tooltip: appLocalizations.settings,
            onTap: () => _showSettingDialog(ref),
          ),
        ],
      ),
      subtitle: Text(appLocalizations.sidebarFlyoutDesc),
      delegate: SwitchDelegate(
        value: sidebarFlyout,
        onChanged: (bool value) {
          ref
              .read(appSettingProvider.notifier)
              .updateState((state) => state.copyWith(sidebarFlyout: value));
        },
      ),
    );
  }
}

class AlwaysShowTitleBarItem extends ConsumerWidget {
  const AlwaysShowTitleBarItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alwaysShowTitleBar = ref.watch(
      vpnSettingProvider.select((state) => state.alwaysShowTitleBar),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.alwaysShowTitleBar),
      subtitle: Text(appLocalizations.alwaysShowTitleBarDesc),
      delegate: SwitchDelegate(
        value: alwaysShowTitleBar,
        onChanged: (bool value) async {
          ref
              .read(vpnSettingProvider.notifier)
              .updateState(
                (state) => state.copyWith(alwaysShowTitleBar: value),
              );
        },
      ),
    );
  }
}

class NavBarHapticFeedbackItem extends ConsumerWidget {
  const NavBarHapticFeedbackItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enableNavBarHapticFeedback = ref.watch(
      appSettingProvider.select((state) => state.enableNavBarHapticFeedback),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.navBarHapticFeedback),
      subtitle: Text(appLocalizations.navBarHapticFeedbackDesc),
      delegate: SwitchDelegate(
        value: enableNavBarHapticFeedback,
        onChanged: (value) {
          ref
              .read(appSettingProvider.notifier)
              .updateState(
                (state) => state.copyWith(enableNavBarHapticFeedback: value),
              );
        },
      ),
    );
  }
}

class AutoCheckUpdateItem extends ConsumerWidget {
  const AutoCheckUpdateItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoCheckUpdate = ref.watch(
      appSettingProvider.select((state) => state.autoCheckUpdate),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.autoCheckUpdate),
      subtitle: Text(appLocalizations.autoCheckUpdateDesc),
      delegate: SwitchDelegate(
        value: autoCheckUpdate,
        onChanged: (bool value) {
          ref
              .read(appSettingProvider.notifier)
              .updateState((state) => state.copyWith(autoCheckUpdate: value));
        },
      ),
    );
  }
}

class ApplicationSettingView extends StatelessWidget {
  const ApplicationSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [
      AutoLaunchItem(),
      if (system.isDesktop) ...[SilentLaunchItem()],
      AutoRunItem(),
      if (system.isAndroid) ...[HiddenItem()],
      if (system.isDesktop) ...[
        if (system.isWindows || system.isLinux) const AlwaysShowTitleBarItem(),
      ],
      if (system.isDesktop) const SidebarFlyoutItem(),
      if (system.isAndroid) const NavBarHapticFeedbackItem(),
      if (system.isMacOS) const KeepDockIconItem(),
      UsageItem(),
      AutoCheckUpdateItem(),
    ];
    return generateListView(generateSection(items: items));
  }
}
