import 'package:bett_box/clash/clash.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/common/profile_chain.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kernel adapter type names (core constant/adapters.go, AdapterType
/// String values). Offered as exclude-type choices next to the types
/// actually present in the current config; the kernel matches exclude-type
/// entries against these names ignoring letter case (groupbase.go).
const kernelProxyTypes = <String>[
  'Shadowsocks',
  'ShadowsocksR',
  'Snell',
  'Socks5',
  'Http',
  'Vmess',
  'Vless',
  'Trojan',
  'Hysteria',
  'Hysteria2',
  'WireGuard',
  'Tuic',
  'Ssh',
  'Mieru',
  'AnyTLS',
  'Sudoku',
  'Masque',
  'TrustTunnel',
  'ShadowQuic',
  'OpenVPN',
  'Tailscale',
  'ZeroTier',
  'EasyTier',
  'GostRelay',
];

const _strategyValues = <String>[
  '',
  'consistent-hashing',
  'round-robin',
  'sticky-sessions',
];

/// T76: per-group parameter editor.
///
/// A group's parameters used to exist only in the Dart model — users could
/// change them solely by editing the subscription text or an override
/// script. This page edits them as switches, pickers and inputs. Values
/// are persisted as a minimal diff on the profile (Profile.groupOverrides)
/// and merged into the raw groups by the Go patch pipeline on every setup,
/// so subscription updates never wash them away and untouched parameters
/// keep following the subscription.
class GroupSettingsView extends ConsumerStatefulWidget {
  final String groupName;

  const GroupSettingsView({super.key, required this.groupName});

  @override
  ConsumerState<GroupSettingsView> createState() => _GroupSettingsViewState();
}

class _GroupSettingsViewState extends ConsumerState<GroupSettingsView> {
  bool _loading = true;
  bool _loadFailed = false;
  String? _profileId;
  String _rawType = '';
  bool _scriptActive = false;
  ProxyGroupParams? _subscription;
  ProxyGroupParams? _values;
  List<String> _memberNames = const [];
  List<String> _allNames = const [];
  List<String> _typeChoices = const [];
  // T81 C-4: chain health floor applying to this group, if it carries
  // a chain hop. The bridge raises lower health-check values to the
  // floor at setup; the rows echo the effective value so the raise is
  // visible instead of silent.
  ChainHealthFloor? _chainFloor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) {
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
      return;
    }
    _profileId = profile.id;
    await ProfileChainStore.instance.ensureLoaded();
    _chainFloor = chainHealthFloorForGroup(
      ProfileChainStore.instance.of(profile.id),
      currentProfileId: profile.id,
      groupName: widget.groupName,
    );
    _scriptActive =
        globalState.config.scriptProps.resolveScript(
          useScriptOverride: profile.useScriptOverride,
          scriptId: profile.scriptId,
        ) !=
        null;
    try {
      final raw = await globalState.getProfileConfig(profile.id);
      ProxyGroupParams? subscription;
      final rawGroups = raw['proxy-groups'];
      if (rawGroups is List) {
        for (final entry in rawGroups) {
          if (entry is Map && entry['name']?.toString() == widget.groupName) {
            _rawType = entry['type']?.toString() ?? '';
            subscription = ProxyGroupParams.fromRawMap(
              entry.map((key, value) => MapEntry(key.toString(), value)),
            );
            break;
          }
        }
      }
      if (subscription == null) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
        return;
      }
      var memberNames = const <String>[];
      var allNames = const <String>[];
      var typeChoices = kernelProxyTypes;
      try {
        final runtimeGroups = await clashCore.getProxiesGroups();
        final names = <String>{};
        final types = <String>{};
        for (final group in runtimeGroups) {
          names.add(group.name);
          for (final proxy in group.all) {
            names.add(proxy.name);
            if (proxy.type.isNotEmpty) types.add(proxy.type);
          }
          if (group.name == widget.groupName) {
            memberNames = group.all.map((proxy) => proxy.name).toList();
          }
        }
        allNames = names.toList();
        typeChoices = {...kernelProxyTypes, ...types}.toList();
      } catch (_) {
        // Core not up yet: name pickers fall back to just the current
        // values; the rest of the editor stays fully usable.
      }
      if (!mounted) return;
      setState(() {
        _subscription = subscription;
        _values = subscription!.applyOverride(
          profile.groupOverrides[widget.groupName],
        );
        _memberNames = memberNames;
        _allNames = allNames;
        _typeChoices = typeChoices;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  /// Persist [values] as this group's new override diff and re-apply the
  /// profile, mirroring the override page's save path (updateProfile +
  /// debounced setup, whose result surfaces through the usual notifiers).
  void _commit(ProxyGroupParams values) {
    final profileId = _profileId;
    final subscription = _subscription;
    if (profileId == null || subscription == null) return;
    final override = values.diffAgainst(subscription);
    ref
        .read(profilesProvider.notifier)
        .updateProfile(profileId, (profile) {
          final next = Map<String, ProxyGroupOverride>.from(
            profile.groupOverrides,
          );
          if (override.isEmpty) {
            next.remove(widget.groupName);
          } else {
            next[widget.groupName] = override;
          }
          return profile.copyWith(groupOverrides: next);
        });
    setState(() => _values = values);
    globalState.appController.setupClashConfigDebounce();
  }

  Future<void> _handleResetAll() async {
    final subscription = _subscription;
    if (subscription == null) return;
    final res = await globalState.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(text: appLocalizations.groupSettingsResetConfirm),
    );
    if (res == true) {
      _commit(subscription);
    }
  }

  Widget _overrideTag(VoidCallback onReset) {
    return InkWell(
      onTap: onReset,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          appLocalizations.groupOverriddenTag,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required String info,
    required bool value,
    required bool overridden,
    required ValueChanged<bool> onChanged,
    required VoidCallback onReset,
  }) {
    return ListItem.switchItem(
      title: InfoTitle(text: label, info: info),
      trailing: overridden ? _overrideTag(onReset) : null,
      delegate: SwitchDelegate(value: value, onChanged: onChanged),
    );
  }

  Widget _intRow({
    required String label,
    required String info,
    required int? value,
    required bool overridden,
    required ValueChanged<int?> onChanged,
    required VoidCallback onReset,
    int? floorMin,
  }) {
    // T81 C-4: when the chain floor raises this value at runtime, the
    // subtitle echoes the effective value next to the configured one.
    final floored = floorMin == null
        ? null
        : chainFlooredValue(value, floorMin);
    return ListItem.input(
      title: InfoTitle(text: label, info: info),
      subtitle: Text(
        floored != null
            ? '$value · ${appLocalizations.groupChainFloorEffective(floored)}'
            : value?.toString() ?? appLocalizations.notSet,
      ),
      trailing: overridden ? _overrideTag(onReset) : null,
      delegate: InputDelegate(
        title: label,
        value: value?.toString() ?? '',
        validator: (input) {
          if (input == null || input.trim().isEmpty) return null;
          final parsed = int.tryParse(input.trim());
          if (parsed == null || parsed < 0) {
            return appLocalizations.numberTip(label);
          }
          return null;
        },
        onChanged: (input) {
          if (input == null) return;
          final trimmed = input.trim();
          onChanged(trimmed.isEmpty ? null : int.tryParse(trimmed));
        },
      ),
    );
  }

  Widget _textRow({
    required String label,
    required String info,
    required String value,
    required bool overridden,
    required ValueChanged<String> onChanged,
    required VoidCallback onReset,
  }) {
    return ListItem.input(
      title: InfoTitle(text: label, info: info),
      subtitle: Text(value.isEmpty ? appLocalizations.notSet : value),
      trailing: overridden ? _overrideTag(onReset) : null,
      delegate: InputDelegate(
        title: label,
        value: value,
        onChanged: (input) {
          if (input == null) return;
          onChanged(input.trim());
        },
      ),
    );
  }

  /// T84: the health-check URL row opens the shared
  /// [TestUrlPickerDialog] — the same preset list and picker widget as
  /// the global test-URL setting. Only the save semantics differ: the
  /// selection is committed as this group's override diff (and picking
  /// the subscription's own value again removes the override, via
  /// [_commit]'s diff). No global-only controls (e.g. the "override
  /// config" switch) appear here.
  Widget _urlRow({
    required String label,
    required String info,
    required String value,
    required String subscriptionValue,
    required bool overridden,
    required ValueChanged<String> onChanged,
    required VoidCallback onReset,
  }) {
    return ListItem(
      title: InfoTitle(text: label, info: info),
      subtitle: Text(value.isEmpty ? appLocalizations.notSet : value),
      trailing: overridden ? _overrideTag(onReset) : null,
      onTap: () async {
        await globalState.showCommonDialog(
          child: TestUrlPickerDialog(
            title: label,
            currentUrl: value,
            fieldLabel: label,
            customResetValue: subscriptionValue.isEmpty
                ? null
                : subscriptionValue,
            onSelected: onChanged,
          ),
        );
      },
    );
  }

  Widget _nameRow({
    required String label,
    required String info,
    required String value,
    required List<String> choices,
    required bool overridden,
    required ValueChanged<String> onChanged,
    required VoidCallback onReset,
  }) {
    final options = <String>{
      '',
      ...choices,
      if (value.isNotEmpty) value,
    }.toList();
    return ListItem<String>.options(
      title: InfoTitle(text: label, info: info),
      subtitle: Text(value.isEmpty ? appLocalizations.notSet : value),
      trailing: overridden ? _overrideTag(onReset) : null,
      delegate: OptionsDelegate<String>(
        title: label,
        options: options,
        value: value,
        textBuilder: (option) =>
            option.isEmpty ? appLocalizations.notSet : option,
        onChanged: (option) {
          if (option == null) return;
          onChanged(option);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        '${appLocalizations.groupSettings} · ${widget.groupName}';
    if (_loading) {
      return CommonScaffold(
        title: title,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final subscription = _subscription;
    final values = _values;
    if (_loadFailed || subscription == null || values == null) {
      return CommonScaffold(
        title: title,
        body: Center(child: Text(appLocalizations.groupSettingsLoadFailed)),
      );
    }
    final hasOverride = !values.diffAgainst(subscription).isEmpty;
    return CommonScaffold(
      title: title,
      body: generateListView([
        if (_scriptActive)
          SectionContainer(
            plain: true,
            items: [
              ListItem(
                title: Text(
                  appLocalizations.groupSettingsScriptInactive,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        SectionContainer(
          title: appLocalizations.groupSectionHealthCheck,
          isFirst: !_scriptActive,
          items: [
            _urlRow(
              label: appLocalizations.groupParamUrl,
              info: appLocalizations.groupParamUrlInfo,
              value: values.url,
              subscriptionValue: subscription.url,
              overridden: values.url != subscription.url,
              onChanged: (v) => _commit(values.copyWith(url: v)),
              onReset: () =>
                  _commit(values.copyWith(url: subscription.url)),
            ),
            _intRow(
              label: appLocalizations.groupParamInterval,
              info: appLocalizations.groupParamIntervalInfo,
              value: values.interval,
              overridden: values.interval != subscription.interval,
              onChanged: (v) => _commit(values.copyWith(interval: v)),
              onReset: () =>
                  _commit(values.copyWith(interval: subscription.interval)),
              floorMin: _chainFloor?.interval,
            ),
            _switchRow(
              label: appLocalizations.groupParamLazy,
              info: appLocalizations.groupParamLazyInfo,
              value: values.lazy,
              overridden: values.lazy != subscription.lazy,
              onChanged: (v) => _commit(values.copyWith(lazy: v)),
              onReset: () =>
                  _commit(values.copyWith(lazy: subscription.lazy)),
            ),
            _intRow(
              label: appLocalizations.groupParamTimeout,
              info: appLocalizations.groupParamTimeoutInfo,
              value: values.timeout,
              overridden: values.timeout != subscription.timeout,
              onChanged: (v) => _commit(values.copyWith(timeout: v)),
              onReset: () =>
                  _commit(values.copyWith(timeout: subscription.timeout)),
              floorMin: _chainFloor?.timeout,
            ),
            _intRow(
              label: appLocalizations.groupParamMaxFailedTimes,
              info: appLocalizations.groupParamMaxFailedTimesInfo,
              value: values.maxFailedTimes,
              overridden: values.maxFailedTimes != subscription.maxFailedTimes,
              onChanged: (v) => _commit(values.copyWith(maxFailedTimes: v)),
              onReset: () => _commit(
                values.copyWith(maxFailedTimes: subscription.maxFailedTimes),
              ),
            ),
            if (_rawType == 'url-test')
              _intRow(
                label: appLocalizations.groupParamTolerance,
                info: appLocalizations.groupParamToleranceInfo,
                value: values.tolerance,
                overridden: values.tolerance != subscription.tolerance,
                onChanged: (v) => _commit(values.copyWith(tolerance: v)),
                onReset: () => _commit(
                  values.copyWith(tolerance: subscription.tolerance),
                ),
                floorMin: _chainFloor?.tolerance,
              ),
            _textRow(
              label: appLocalizations.groupParamExpectedStatus,
              info: appLocalizations.groupParamExpectedStatusInfo,
              value: values.expectedStatus,
              overridden: values.expectedStatus != subscription.expectedStatus,
              onChanged: (v) => _commit(values.copyWith(expectedStatus: v)),
              onReset: () => _commit(
                values.copyWith(expectedStatus: subscription.expectedStatus),
              ),
            ),
          ],
        ),
        SectionContainer(
          title: appLocalizations.groupSectionFiltering,
          items: [
            _textRow(
              label: appLocalizations.groupParamFilter,
              info: appLocalizations.groupParamFilterInfo,
              value: values.filter,
              overridden: values.filter != subscription.filter,
              onChanged: (v) => _commit(values.copyWith(filter: v)),
              onReset: () =>
                  _commit(values.copyWith(filter: subscription.filter)),
            ),
            _textRow(
              label: appLocalizations.groupParamExcludeFilter,
              info: appLocalizations.groupParamExcludeFilterInfo,
              value: values.excludeFilter,
              overridden: values.excludeFilter != subscription.excludeFilter,
              onChanged: (v) => _commit(values.copyWith(excludeFilter: v)),
              onReset: () => _commit(
                values.copyWith(excludeFilter: subscription.excludeFilter),
              ),
            ),
            ListItem.next(
              title: InfoTitle(
                text: appLocalizations.groupParamExcludeType,
                info: appLocalizations.groupParamExcludeTypeInfo,
              ),
              subtitle: Text(
                values.excludeType.isEmpty
                    ? appLocalizations.notSet
                    : values.excludeType,
              ),
              trailing: values.excludeType != subscription.excludeType
                  ? _overrideTag(
                      () => _commit(
                        values.copyWith(
                          excludeType: subscription.excludeType,
                        ),
                      ),
                    )
                  : null,
              delegate: NextDelegate(
                blur: false,
                title: appLocalizations.groupParamExcludeType,
                builder: (context) => _ExcludeTypePicker(
                  types: _typeChoices,
                  selected: values.excludeType
                      .split('|')
                      .where((item) => item.isNotEmpty)
                      .toSet(),
                  onChanged: (selected) {
                    final joined = (selected.toList()..sort()).join('|');
                    _commit(values.copyWith(excludeType: joined));
                  },
                ),
              ),
            ),
            _switchRow(
              label: appLocalizations.groupParamIncludeAll,
              info: appLocalizations.groupParamIncludeAllInfo,
              value: values.includeAll,
              overridden: values.includeAll != subscription.includeAll,
              onChanged: (v) => _commit(values.copyWith(includeAll: v)),
              onReset: () => _commit(
                values.copyWith(includeAll: subscription.includeAll),
              ),
            ),
            _switchRow(
              label: appLocalizations.groupParamIncludeAllProxies,
              info: appLocalizations.groupParamIncludeAllProxiesInfo,
              value: values.includeAllProxies,
              overridden:
                  values.includeAllProxies != subscription.includeAllProxies,
              onChanged: (v) =>
                  _commit(values.copyWith(includeAllProxies: v)),
              onReset: () => _commit(
                values.copyWith(
                  includeAllProxies: subscription.includeAllProxies,
                ),
              ),
            ),
            _switchRow(
              label: appLocalizations.groupParamIncludeAllProviders,
              info: appLocalizations.groupParamIncludeAllProvidersInfo,
              value: values.includeAllProviders,
              overridden: values.includeAllProviders !=
                  subscription.includeAllProviders,
              onChanged: (v) =>
                  _commit(values.copyWith(includeAllProviders: v)),
              onReset: () => _commit(
                values.copyWith(
                  includeAllProviders: subscription.includeAllProviders,
                ),
              ),
            ),
          ],
        ),
        SectionContainer(
          title: appLocalizations.groupSectionBehavior,
          items: [
            if (_rawType == 'select')
              _nameRow(
                label: appLocalizations.groupParamDefaultSelected,
                info: appLocalizations.groupParamDefaultSelectedInfo,
                value: values.defaultSelected,
                choices: _memberNames,
                overridden:
                    values.defaultSelected != subscription.defaultSelected,
                onChanged: (v) => _commit(values.copyWith(defaultSelected: v)),
                onReset: () => _commit(
                  values.copyWith(
                    defaultSelected: subscription.defaultSelected,
                  ),
                ),
              ),
            if (_rawType == 'load-balance')
              ListItem<String>.options(
                title: InfoTitle(
                  text: appLocalizations.groupParamStrategy,
                  info: appLocalizations.groupParamStrategyInfo,
                ),
                subtitle: Text(
                  values.strategy.isEmpty
                      ? appLocalizations.notSet
                      : values.strategy,
                ),
                trailing: values.strategy != subscription.strategy
                    ? _overrideTag(
                        () => _commit(
                          values.copyWith(strategy: subscription.strategy),
                        ),
                      )
                    : null,
                delegate: OptionsDelegate<String>(
                  title: appLocalizations.groupParamStrategy,
                  options: _strategyValues,
                  value: values.strategy,
                  textBuilder: (option) => switch (option) {
                    '' => appLocalizations.notSet,
                    'consistent-hashing' =>
                      appLocalizations.groupStrategyConsistentHashing,
                    'round-robin' => appLocalizations.groupStrategyRoundRobin,
                    'sticky-sessions' =>
                      appLocalizations.groupStrategyStickySessions,
                    _ => option,
                  },
                  onChanged: (option) {
                    if (option == null) return;
                    _commit(values.copyWith(strategy: option));
                  },
                ),
              ),
            if (_rawType == 'load-balance')
              _textRow(
                label: appLocalizations.groupParamHashKey,
                info: appLocalizations.groupParamHashKeyInfo,
                value: values.hashKey,
                overridden: values.hashKey != subscription.hashKey,
                onChanged: (v) => _commit(values.copyWith(hashKey: v)),
                onReset: () =>
                    _commit(values.copyWith(hashKey: subscription.hashKey)),
              ),
            _nameRow(
              label: appLocalizations.groupParamEmptyFallback,
              info: appLocalizations.groupParamEmptyFallbackInfo,
              value: values.emptyFallback,
              choices: _allNames,
              overridden: values.emptyFallback != subscription.emptyFallback,
              onChanged: (v) => _commit(values.copyWith(emptyFallback: v)),
              onReset: () => _commit(
                values.copyWith(emptyFallback: subscription.emptyFallback),
              ),
            ),
            _switchRow(
              label: appLocalizations.groupParamDisableUdp,
              info: appLocalizations.groupParamDisableUdpInfo,
              value: values.disableUdp,
              overridden: values.disableUdp != subscription.disableUdp,
              onChanged: (v) => _commit(values.copyWith(disableUdp: v)),
              onReset: () => _commit(
                values.copyWith(disableUdp: subscription.disableUdp),
              ),
            ),
            _switchRow(
              label: appLocalizations.groupParamHidden,
              info: appLocalizations.groupParamHiddenInfo,
              value: values.hidden,
              overridden: values.hidden != subscription.hidden,
              onChanged: (v) => _commit(values.copyWith(hidden: v)),
              onReset: () =>
                  _commit(values.copyWith(hidden: subscription.hidden)),
            ),
            _textRow(
              label: appLocalizations.groupParamIcon,
              info: appLocalizations.groupParamIconInfo,
              value: values.icon,
              overridden: values.icon != subscription.icon,
              onChanged: (v) => _commit(values.copyWith(icon: v)),
              onReset: () =>
                  _commit(values.copyWith(icon: subscription.icon)),
            ),
          ],
        ),
        if (hasOverride)
          SectionContainer(
            plain: true,
            items: [
              ListItem(
                title: Text(
                  appLocalizations.groupSettingsResetAll,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colorScheme.error,
                  ),
                ),
                onTap: _handleResetAll,
              ),
            ],
          ),
      ]),
    );
  }
}

/// Multi-select page for exclude-type: one checkbox row per kernel adapter
/// type. Stored tokens that are not in the known list stay visible (and
/// checked) so editing never silently drops them.
class _ExcludeTypePicker extends StatefulWidget {
  final List<String> types;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _ExcludeTypePicker({
    required this.types,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_ExcludeTypePicker> createState() => _ExcludeTypePickerState();
}

class _ExcludeTypePickerState extends State<_ExcludeTypePicker> {
  late final Set<String> _selected = {...widget.selected};
  late final List<String> _types = {...widget.types, ...widget.selected}
      .toList()
    ..sort();

  @override
  Widget build(BuildContext context) {
    return generateListView([
      for (final type in _types)
        ListItem.checkbox(
          title: Text(type),
          delegate: CheckboxDelegate(
            value: _selected.contains(type),
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selected.add(type);
                } else {
                  _selected.remove(type);
                }
              });
              widget.onChanged({..._selected});
            },
          ),
        ),
    ]);
  }
}
