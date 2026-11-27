import 'dart:async';

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/common.dart';
import 'package:angelamihomo/models/profile.dart';
import 'package:angelamihomo/models/widget.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/proxies/list.dart';
import 'package:angelamihomo/views/proxies/providers.dart';
import 'package:angelamihomo/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profiles/managed_options.dart' show showManagedOptions;
import '../profiles/scripts.dart'
    show showGroupSwitchOptions, showScriptCustomOptions;
import 'advanced_settings.dart';
import 'common.dart';
import 'setting.dart';
import 'tab.dart';

class ProxiesView extends ConsumerStatefulWidget {
  const ProxiesView({super.key});

  @override
  ConsumerState<ProxiesView> createState() => _ProxiesViewState();
}

class _ProxiesViewState extends ConsumerState<ProxiesView>
    with WidgetsBindingObserver {
  final GlobalKey<ProxiesTabViewState> _proxiesTabKey = GlobalKey();
  final GlobalKey<ProxiesListViewState> _proxiesListKey = GlobalKey();
  bool _hasProviders = false;
  bool _isTab = false;

  // T305: automatic delay freshness. The proxies page is where delay
  // numbers are read, so arriving here (or returning to the app with
  // this page up) starts a global test run, and a slow timer keeps
  // the numbers fresh while the page stays open. Every trigger goes
  // through _autoDelayTest's guards — active page, running core, and
  // a minimum spacing behind any run start (manual ones included,
  // tracked via _onDelayTestActivity) — so the automation can never
  // stack runs or pop an error strip over a stopped core.
  Timer? _autoDelayTestTimer;
  DateTime? _lastDelayTestAt;

  void _onDelayTestActivity() {
    if (globalDelayTestController.isRunning) {
      _lastDelayTestAt = DateTime.now();
    }
  }

  void _autoDelayTest() {
    if (!mounted) return;
    final scope = context.getInheritedWidgetOfExactType<PageActivityScope>();
    if (scope != null && !scope.isActive) return;
    if (ref.read(runTimeProvider) == null) return;
    final last = _lastDelayTestAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 45)) {
      return;
    }
    _lastDelayTestAt = DateTime.now();
    globalDelayTest();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _autoDelayTest();
    }
  }

  List<Widget> _buildActions() {
    final (autoStickyHeader, showHiddenItems, hideTimeoutProxies) = ref.watch(
      proxiesStyleSettingProvider.select(
        (state) => (
          state.autoStickyHeader,
          state.showHiddenItems,
          state.hideTimeoutProxies,
        ),
      ),
    );
    final compatible = ref.watch(
      currentProfileScriptProvider.select(
        (script) => script?.compatible ?? false,
      ),
    );
    final managed = ref.watch(
      currentProfileProvider.select((p) => p?.isManaged ?? false),
    );
    final hasScriptCustom = managed || compatible;
    final hasGroupCustom =
        !hasScriptCustom && ref.read(currentProfileIdProvider) != null;
    final hasCustom = hasScriptCustom || hasGroupCustom;
    return [
      AnimatedBuilder(
        animation: Listenable.merge([
          globalDelayTestController,
          delayTestCoordinator,
        ]),
        builder: (_, _) {
          if (globalDelayTestController.isRunning) {
            return IconButton(
              onPressed: () => cancelGlobalDelayTest(),
              tooltip: appLocalizations.cancel,
              icon: const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return IconButton(
            onPressed: delayTestCoordinator.isTesting
                ? null
                : () => globalDelayTest(),
            tooltip: appLocalizations.globalDelayTest,
            icon: const Icon(Icons.speed),
          );
        },
      ),
      if (_isTab)
        IconButton(
          onPressed: () {
            _proxiesTabKey.currentState?.scrollToGroupSelected();
          },
          tooltip: appLocalizations.locate,
          icon: const Icon(Icons.adjust, weight: 1),
        ),
      if (hasCustom)
        IconButton(
          onPressed: _handleCustomOptions,
          icon: const Icon(Icons.tune),
          tooltip: appLocalizations.custom,
        ),
      CommonPopupBox(
        targetBuilder: (open) {
          return IconButton(
            onPressed: () {
              open(offset: const Offset(0, 20));
            },
            tooltip: appLocalizations.more,
            icon: const Icon(Icons.more_vert),
          );
        },
        popup: CommonPopupMenu(
          items: [
            PopupMenuItemData(
              icon: Icons.tune,
              label: appLocalizations.settings,
              onPressed: () {
                showSheet(
                  context: context,
                  props: SheetProps(isScrollControlled: true),
                  builder: (_, type) {
                    return AdaptiveSheetScaffold(
                      type: type,
                      body: const ProxiesSetting(),
                      title: appLocalizations.settings,
                    );
                  },
                );
              },
            ),
            if (_hasProviders)
              PopupMenuItemData(
                icon: Icons.poll_outlined,
                label: appLocalizations.providers,
                onPressed: () {
                  showExtend(
                    context,
                    builder: (_, type) {
                      return ProvidersView(type: type);
                    },
                  );
                },
              ),
            PopupMenuItemData(
              icon: Icons.settings_suggest,
              label: appLocalizations.advancedSettings,
              onPressed: () {
                showExtend(
                  context,
                  builder: (_, type) {
                    return AdaptiveSheetScaffold(
                      type: type,
                      body: const ProxiesAdvancedSettings(),
                      title: appLocalizations.advancedSettings,
                    );
                  },
                );
              },
            ),
            if (!_isTab)
              PopupMenuItemData(
                icon: autoStickyHeader
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                label: appLocalizations.autoStickyHeader,
                onPressed: () {
                  ref
                      .read(proxiesStyleSettingProvider.notifier)
                      .updateState(
                        (state) =>
                            state.copyWith(autoStickyHeader: !autoStickyHeader),
                      );
                },
              ),
            PopupMenuItemData(
              icon: showHiddenItems
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              label: appLocalizations.showHiddenItems,
              onPressed: () {
                ref
                    .read(proxiesStyleSettingProvider.notifier)
                    .updateState(
                      (state) =>
                          state.copyWith(showHiddenItems: !showHiddenItems),
                    );
              },
            ),
            PopupMenuItemData(
              icon: hideTimeoutProxies
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              label: appLocalizations.hideTimeoutProxies,
              onPressed: () {
                ref
                    .read(proxiesStyleSettingProvider.notifier)
                    .updateState(
                      (state) => state.copyWith(
                        hideTimeoutProxies: !hideTimeoutProxies,
                      ),
                    );
                globalState.appController.addSortNum();
              },
            ),
          ],
        ),
      ),
    ];
  }

  Widget? _buildFAB() {
    if (!_isTab || globalState.isAndroidTV) return null;
    return Consumer(
      builder: (_, ref, _) {
        final isMobileView = ref.watch(isMobileViewProvider);
        final currentGroupName = ref.watch(
          proxiesTabControllerStateProvider.select((state) => state.b),
        );
        return Padding(
          padding: EdgeInsets.only(
            bottom: isMobileView
                ? getFloatingBottomBarFABReserveHeight(context)
                : 0,
          ),
          child: DelayTestButton(
            groupName: currentGroupName ?? '',
            onClick: () async {
              await _proxiesTabKey.currentState?.delayTestCurrentGroup();
            },
          ),
        );
      },
    );
  }

  void _collapseAllGroups() {
    _proxiesListKey.currentState?.collapseAll();
  }

  void _onSearch(String value) {
    ref.read(queryProvider.notifier).value = value;
  }

  Future<void> _handleCustomOptions() async {
    final profile = ref.read(currentProfileProvider);
    if (profile?.isManaged ?? false) {
      await showManagedOptions(context);
      return;
    }
    final script = ref.read(currentProfileScriptProvider);
    if (script != null && script.compatible) {
      await showScriptCustomOptions(context, script: script);
      return;
    }
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId != null) {
      await showGroupSwitchOptions(context, profileId: profileId);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    globalDelayTestController.addListener(_onDelayTestActivity);
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoDelayTest());
    _autoDelayTestTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _autoDelayTest(),
    );
    ref.listenManual(providersProvider.select((state) => state.isNotEmpty), (
      prev,
      next,
    ) {
      if (prev != next) {
        setState(() {
          _hasProviders = next;
        });
      }
    }, fireImmediately: true);
    ref.listenManual(
      proxiesStyleSettingProvider.select(
        (state) => state.type == ProxiesType.tab,
      ),
      (prev, next) {
        if (prev != next) {
          setState(() {
            _isTab = next;
          });
        }
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (proxiesType, autoStickyHeader) = ref.watch(
      proxiesStyleSettingProvider.select(
        (state) => (state.type, state.autoStickyHeader),
      ),
    );
    final hasGroups = ref.watch(
      groupsProvider.select((state) => state.isNotEmpty),
    );
    ref.watch(appSettingProvider.select((state) => state.locale));
    return CommonScaffold(
      floatingActionButton: _buildFAB(),
      actions: _buildActions(),
      title: appLocalizations.proxies,
      scrollEdgeFade: proxiesType == ProxiesType.list && !autoStickyHeader,
      onAppBarDoubleTap: proxiesType == ProxiesType.list
          ? _collapseAllGroups
          : null,
      searchState: AppBarSearchState(onSearch: _onSearch),
      body: Column(
        children: [
          const _GlobalDelayTestStatusBar(),
          Expanded(
            child: switch (hasGroups) {
              false => NullStatus(
                label: appLocalizations.noProxy,
                icon: Icons.cloud_off_outlined,
                description: appLocalizations.noProxyDesc,
                action: FilledButton.tonalIcon(
                  onPressed: globalState.appController.toProfiles,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(appLocalizations.addProfile),
                ),
              ),
              true => switch (proxiesType) {
                ProxiesType.tab => ProxiesTabView(key: _proxiesTabKey),
                ProxiesType.list => ProxiesListView(key: _proxiesListKey),
              },
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    globalDelayTestController.removeListener(_onDelayTestActivity);
    _autoDelayTestTimer?.cancel();
    if (globalDelayTestController.isRunning) {
      cancelGlobalDelayTest();
    }
    super.dispose();
  }
}

/// In-page progress/result strip for the global linked delay test, shown
/// under the app bar while a run is in flight and after it completes.
class _GlobalDelayTestStatusBar extends StatelessWidget {
  const _GlobalDelayTestStatusBar();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: globalDelayTestController,
      builder: (context, _) {
        final state = globalDelayTestController;
        if (state.phase == GlobalDelayTestPhase.idle) {
          return const SizedBox.shrink();
        }
        final running = state.isRunning;
        final failed = state.failed;
        final colorScheme = context.colorScheme;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: colorScheme.secondaryContainer,
          child: Row(
            children: [
              if (running)
                const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  failed > 0 ? Icons.error_outline : Icons.check_circle_outline,
                  size: 16,
                  color: failed > 0 ? colorScheme.error : colorScheme.primary,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  running
                      ? '${appLocalizations.globalDelayTest} · '
                            '${appLocalizations.globalDelayTesting} '
                            '${state.completed}/${state.total}'
                      : '${appLocalizations.globalDelayTest} · '
                            '${appLocalizations.globalDelayTestDone}'
                            '${failed > 0 ? ' · ${appLocalizations.globalDelayTestFailed} $failed' : ''}',
                  style: context.textTheme.bodySmall,
                ),
              ),
              if (!running)
                IconButton(
                  onPressed: state.dismiss,
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
