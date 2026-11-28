// ignore_for_file: invalid_annotation_target

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:material_ui/material_ui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';

part 'generated/config.freezed.dart';
part 'generated/config.g.dart';

const defaultBypassDomain = [
  '*.jd.com',
  '*.zhihu.com',
  '*.zhimg.com',
  '*.360buyimg.com',
  'localhost',
  '127.*',
  '[::1]',
  '*.local',
  '10.*',
  '172.16.*',
  '172.17.*',
  '172.18.*',
  '172.19.*',
  '172.20.*',
  '172.21.*',
  '172.22.*',
  '172.23.*',
  '172.24.*',
  '172.25.*',
  '172.26.*',
  '172.27.*',
  '172.28.*',
  '172.29.*',
  '172.30.*',
  '172.31.*',
  '192.168.*',
];

const defaultAppSettingProps = AppSettingProps();
const defaultVpnProps = VpnProps();
const defaultNetworkProps = NetworkProps();
const defaultProxiesStyle = ProxiesStyle();
const defaultWindowProps = WindowProps();
const defaultAccessControl = AccessControl();
const defaultThemeProps = ThemeProps();

/// T337 (fusion): the default layouts present each readout once,
/// arranged for reading — the exit node full-width (name on its
/// own line, chain info under it), the speeds full-width, today
/// traffic and subscription remaining side by side at equal
/// width, the outbound mode (mode only; the delay lives in the
/// hero's pill), then the full-width subscription card with the
/// traffic statistics inside it and the speed test as an in-card
/// button. The standalone traffic-usage tile stays in the
/// catalog as an option but out of the defaults, so its numbers
/// are not shown twice. Everything here is a grid tile: the user
/// rearranges, resizes and removes freely in edit mode.
const List<DashboardWidget> defaultDashboardWidgets = [
  DashboardWidget.exitNode,
  DashboardWidget.networkSpeed,
  DashboardWidget.todayTraffic,
  DashboardWidget.subscriptionRemaining,
  DashboardWidget.outboundMode,
  DashboardWidget.subscription,
  DashboardWidget.systemProxyButton,
  DashboardWidget.tunButton,
  DashboardWidget.networkDetection,
  DashboardWidget.intranetIp,
  DashboardWidget.memoryInfo,
  DashboardWidget.connectionsCount,
];

const List<DashboardWidget> defaultAndroidDashboardWidgets = [
  DashboardWidget.exitNode,
  DashboardWidget.networkSpeed,
  DashboardWidget.todayTraffic,
  DashboardWidget.subscriptionRemaining,
  DashboardWidget.outboundMode,
  DashboardWidget.subscription,
];

final _dashboardWidgetNames = {
  for (final entry in _$DashboardWidgetEnumMap.entries) entry.value: entry.key,
};

/// Names of dashboard widgets that no longer exist. Layouts
/// saved before T147 named the profile and mode cards separately
/// (profileInfo / outboundMode / outboundModeV2); T147 merged
/// them into profileMode; T337 retired profileMode itself — its
/// functions live on as separate tiles (exitNode, outboundMode,
/// subscription) — and startButton, whose home is the hero's
/// power core. Those names decode by being dropped: a saved
/// layout simply loses the retired shapes and keeps every
/// surviving widget in its saved relative order.
const _retiredDashboardWidgetNames = {
  'profileInfo',
  'outboundModeV2',
  'outboundMode',
  'profileMode',
  'startButton',
};

List<DashboardWidget> _decodeDashboardWidgets(List<dynamic> values) {
  final widgets = <DashboardWidget>[];
  for (final value in values) {
    if (_retiredDashboardWidgetNames.contains(value)) continue;
    final widget = _dashboardWidgetNames[value];
    if (widget == null) continue;
    widgets.add(widget);
  }
  return widgets;
}

/// Size-table normalization for the dashboard layouts: entries
/// naming retired widgets (see _retiredDashboardWidgetNames) are
/// dropped — their tiles are gone, so a saved size for one could
/// never resolve. Every surviving widget's entry is kept as saved.
Map<String, String> _normalizeDashboardSizes(Map<String, String> sizes) {
  return {
    for (final entry in sizes.entries)
      if (!_retiredDashboardWidgetNames.contains(entry.key))
        entry.key: entry.value,
  };
}

List<DashboardWidget> dashboardWidgetsSafeFromJson(
  List<dynamic>? dashboardWidgets,
) {
  if (dashboardWidgets == null) {
    return system.isAndroid
        ? defaultAndroidDashboardWidgets
        : defaultDashboardWidgets;
  }
  return _decodeDashboardWidgets(dashboardWidgets);
}

List<DashboardWidget> mobileDashboardWidgetsSafeFromJson(
  List<dynamic>? dashboardWidgets,
) {
  if (dashboardWidgets == null) {
    return defaultAndroidDashboardWidgets;
  }
  return _decodeDashboardWidgets(dashboardWidgets);
}

List<DashboardWidget> desktopDashboardWidgetsSafeFromJson(
  List<dynamic>? dashboardWidgets,
) {
  if (dashboardWidgets == null) {
    return defaultDashboardWidgets;
  }
  return _decodeDashboardWidgets(dashboardWidgets);
}

const List<SidebarFlyoutEntry> defaultSidebarFlyoutEntries = [
  SidebarFlyoutEntry.resources,
  SidebarFlyoutEntry.script,
  SidebarFlyoutEntry.toolbox,
  SidebarFlyoutEntry.theme,
  SidebarFlyoutEntry.basicConfig,
  SidebarFlyoutEntry.otherSettings,
  SidebarFlyoutEntry.application,
  SidebarFlyoutEntry.about,
];

List<SidebarFlyoutEntry> sidebarFlyoutEntriesSafeFromJson(
  List<dynamic>? sidebarFlyoutEntries,
) {
  try {
    return sidebarFlyoutEntries
            ?.map((e) => $enumDecode(_$SidebarFlyoutEntryEnumMap, e))
            .toList() ??
        defaultSidebarFlyoutEntries;
  } catch (_) {
    return defaultSidebarFlyoutEntries;
  }
}

@freezed
abstract class AppSettingProps with _$AppSettingProps {
  const factory AppSettingProps({
    String? locale,
    @Default(defaultDashboardWidgets)
    @JsonKey(fromJson: dashboardWidgetsSafeFromJson)
    List<DashboardWidget> dashboardWidgets,
    @Default(defaultAndroidDashboardWidgets)
    @JsonKey(fromJson: mobileDashboardWidgetsSafeFromJson)
    List<DashboardWidget> mobileDashboardWidgets,
    @Default(defaultDashboardWidgets)
    @JsonKey(fromJson: desktopDashboardWidgetsSafeFromJson)
    List<DashboardWidget> desktopDashboardWidgets,
    @Default(true) bool onlyStatisticsProxy,
    @Default(false) bool autoLaunch,
    @Default(false) bool silentLaunch,
    @Default(false) bool smartDelayLaunch,
    @Default(false) bool autoRun,
    @Default(true) bool openLogs,
    @Default(true) bool closeConnections,
    @Default(defaultTestUrl) String testUrl,
    @Default(true) bool showStartSwitch,
    @Default(StartSwitchStyle.outlined) StartSwitchStyle startSwitchStyle,
    String? startSwitchOnLabel,
    String? startSwitchOffLabel,
    @Default(true) bool enableNavBarHapticFeedback,
    @Default(true) bool autoCheckUpdate,
    // chain.28 (T199): the single authoritative switch for every
    // data-channel auto update (city database + managed script).
    @Default(true) bool dataAutoUpdate,
    @Default(false) bool showLabel,
    @Default(false) bool disclaimerAccepted,
    @Default(true) bool minimizeOnExit,
    @Default(false) bool hidden,
    @Default(true) bool keepDockIcon,
    @Default(false) bool developerMode,
    @Default(RecoveryStrategy.compatible) RecoveryStrategy recoveryStrategy,
    @Default('') String backupPassword,
    @Default(false) bool enableHighPriority,
    @Default(true) bool sidebarCollapsed,
    @Default(false) bool sidebarFlyout,
    @Default(false) bool sidebarFlyoutOutsideTools,
    @Default(SidebarFlyoutDelay.standard) SidebarFlyoutDelay sidebarFlyoutDelay,
    @Default(defaultSidebarFlyoutEntries)
    @JsonKey(fromJson: sidebarFlyoutEntriesSafeFromJson)
    List<SidebarFlyoutEntry> sidebarFlyoutEntries,
    String? dashboardTitle,
    @Default(false) bool dashboardWatermark,
    @Default(<String>[]) List<String> toolboxTiles,
    @Default(false) bool mrsCopyRawLink,
    @JsonKey(unknownEnumValue: MrsRawSource.angelamihomoGeo)
    @Default(MrsRawSource.angelamihomoGeo)
    MrsRawSource mrsRawSource,
    @JsonKey(unknownEnumValue: MrsTapAction.viewRules)
    @Default(MrsTapAction.viewRules)
    MrsTapAction mrsTapAction,
    @Default(true) bool mrsResolveDns,
    @Default(false) bool ipRiskDetail,
    @Default(false) bool ipRiskAlert,
    @Default(IperfOptions()) IperfOptions iperfOptions,
    @Default(LocalPingOptions()) LocalPingOptions localPingOptions,
    @Default(<String, String>{}) Map<String, String> mobileDashboardSizes,
    @Default(<String, String>{}) Map<String, String> desktopDashboardSizes,
  }) = _AppSettingProps;

  factory AppSettingProps.fromJson(Map<String, Object?> json) =>
      _$AppSettingPropsFromJson(json);

  factory AppSettingProps.safeFromJson(Map<String, Object?>? json) {
    var props = json == null
        ? defaultAppSettingProps
        : AppSettingProps.fromJson(json);

    if (json != null) {
      final oldWidgets = json['dashboardWidgets'];
      if (oldWidgets is List) {
        final parsedOld = dashboardWidgetsSafeFromJson(oldWidgets);
        if (json['mobileDashboardWidgets'] == null) {
          props = props.copyWith(mobileDashboardWidgets: parsedOld);
        }
        if (json['desktopDashboardWidgets'] == null) {
          props = props.copyWith(desktopDashboardWidgets: parsedOld);
        }
      }
      props = props.copyWith(
        mobileDashboardSizes: _normalizeDashboardSizes(
          props.mobileDashboardSizes,
        ),
        desktopDashboardSizes: _normalizeDashboardSizes(
          props.desktopDashboardSizes,
        ),
      );
    } else if (system.isAndroid) {
      props = props.copyWith(
        mobileDashboardWidgets: defaultAndroidDashboardWidgets,
      );
    }

    return props.copyWith(minimizeOnExit: true, openLogs: true);
  }
}

@freezed
abstract class AccessControl with _$AccessControl {
  const factory AccessControl({
    @Default(false) bool enable,
    @Default(AccessControlMode.rejectSelected) AccessControlMode mode,
    @Default([]) List<String> acceptList,
    @Default([]) List<String> rejectList,
    @Default([]) List<String> manualList,
    @JsonKey(unknownEnumValue: AccessSortType.none)
    @Default(AccessSortType.none)
    AccessSortType sort,
    @Default(false) bool isFilterSystemApp,
    @Default(false) bool isFilterNonInternetApp,
  }) = _AccessControl;

  factory AccessControl.fromJson(Map<String, Object?> json) =>
      _$AccessControlFromJson(json);
}

extension AccessControlExt on AccessControl {
  List<String> get currentList => switch (mode) {
    AccessControlMode.acceptSelected => acceptList,
    AccessControlMode.rejectSelected => rejectList,
  };
}

@freezed
abstract class WindowProps with _$WindowProps {
  const factory WindowProps({
    @Default(910) double width,
    @Default(620) double height,
    double? top,
    double? left,
    @Default(false) bool isPinned,
    @Default(1.0) double scaleFactor,
  }) = _WindowProps;

  factory WindowProps.fromJson(Map<String, Object?>? json) =>
      json == null ? const WindowProps() : _$WindowPropsFromJson(json);
}

@freezed
abstract class VpnProps with _$VpnProps {
  const factory VpnProps({
    @Default(true) bool enable,
    @Default(true) bool systemProxy,
    @Default(false) bool allowBypass,
    @Default(true) bool bypassPrivateRoute,
    @Default(true) bool dozeSuspend,
    @Default(false) bool smartAutoStop,
    @Default('') String smartAutoStopNetworks,
    @Default(false) bool storeFix,
    @Default(false) bool networkFix,
    @Default(false) bool loopbackProtection,
    @Default(false) bool disableQuic,
    @Default(false) bool highPriorityNotification,
    @Default(false) bool networkSpeedNotification,
    @Default(false) bool trayEnhancement,
    @Default(TrayClickBehavior.showPanel)
    TrayClickBehavior trayLeftClickBehavior,
    @Default(TrayClickBehavior.showMenu)
    TrayClickBehavior trayRightClickBehavior,
    @Default(false) bool enableTraySpeed,
    @Default(true) bool alwaysShowTitleBar,
    @Default(true) bool quickResponse,
    @Default(defaultAccessControl) AccessControl accessControl,
  }) = _VpnProps;

  factory VpnProps.fromJson(Map<String, Object?> json) =>
      _$VpnPropsFromJson(json);

  factory VpnProps.safeFromJson(Map<String, Object?>? json) {
    return json == null ? defaultVpnProps : VpnProps.fromJson(json);
  }
}

List<String> bypassDomainSafeFromJson(List<dynamic>? bypassDomain) {
  try {
    return bypassDomain
            ?.map((e) => e.toString())
            .where((e) => e != '::1')
            .toList() ??
        defaultBypassDomain;
  } catch (_) {
    return defaultBypassDomain;
  }
}

int concurrencyLimitFromJson(Object? value) {
  if (value is! int || value > 32) return maxDelayTestConcurrency;
  return value < 1 ? 1 : value;
}

@freezed
abstract class NetworkProps with _$NetworkProps {
  const factory NetworkProps({
    @Default(true) bool systemProxy,
    @Default(defaultBypassDomain)
    @JsonKey(fromJson: bypassDomainSafeFromJson)
    List<String> bypassDomain,
    @Default(true) bool bypassPrivateRoute,
    @Default([]) List<String> bypassPrivateRouteAddress,
    @Default(ProfileSwitchMode.hotReload) ProfileSwitchMode profileSwitchMode,
  }) = _NetworkProps;

  factory NetworkProps.fromJson(Map<String, Object?>? json) =>
      json == null ? const NetworkProps() : _$NetworkPropsFromJson(json);
}

extension NetworkPropsExt on NetworkProps {
  List<String> get realBypassPrivateRouteAddress {
    if (bypassPrivateRouteAddress.isNotEmpty) return bypassPrivateRouteAddress;
    return system.isDesktop
        ? defaultDesktopBypassPrivateRouteAddress
        : defaultBypassPrivateRouteAddress;
  }
}

@freezed
abstract class ProxiesStyle with _$ProxiesStyle {
  const factory ProxiesStyle({
    @Default(ProxiesType.tab) ProxiesType type,
    @Default(ProxiesSortType.none) ProxiesSortType sortType,
    @Default(ProxiesLayout.standard) ProxiesLayout layout,
    @Default(ProxiesIconStyle.none) ProxiesIconStyle iconStyle,
    @Default(ProxyCardType.expand) ProxyCardType cardType,
    @Default(DelayAnimationType.pulse) DelayAnimationType delayAnimation,
    @Default(true) bool syncDelayAnimation,
    @Default({}) Map<String, String> iconMap,
    @Default(maxDelayTestConcurrency)
    @JsonKey(fromJson: concurrencyLimitFromJson)
    int concurrencyLimit,
    @Default(false) bool autoStickyHeader,
    @Default(false) bool showHiddenItems,
    @Default(false) bool hideTimeoutProxies,
    @Default(false) bool hasCustomizedStyle,
  }) = _ProxiesStyle;

  factory ProxiesStyle.fromJson(Map<String, Object?>? json) =>
      json == null ? defaultProxiesStyle : _$ProxiesStyleFromJson(json);
}

@freezed
abstract class TextScale with _$TextScale {
  const factory TextScale({
    @Default(false) bool enable,
    @Default(1.0) double scale,
  }) = _TextScale;

  factory TextScale.fromJson(Map<String, Object?> json) =>
      _$TextScaleFromJson(json);
}

@freezed
abstract class ThemeProps with _$ThemeProps {
  const factory ThemeProps({
    int? primaryColor,
    @Default(defaultPrimaryColors) List<int> primaryColors,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(DynamicSchemeVariant.content) DynamicSchemeVariant schemeVariant,
    @Default(TextScale()) TextScale textScale,
    @Default(false) bool useDarkIcon,
    @Default(false) bool useHarmonyFont,
    @Default(false) bool invertTrayIcon,

    /// The twelve-constellation theme family selection (zodiac theme id).
    /// Brightness always follows the system; legacy upstream color choices
    /// above are kept only for stored-config compatibility and no longer
    /// drive the color scheme.
    @Default(zodiacDefaultThemeId) String zodiacTheme,
  }) = _ThemeProps;

  factory ThemeProps.fromJson(Map<String, Object?> json) =>
      _$ThemePropsFromJson(json);

  factory ThemeProps.safeFromJson(Map<String, Object?>? json) {
    if (json == null) {
      return defaultThemeProps;
    }
    try {
      return ThemeProps.fromJson(json);
    } catch (_) {
      return defaultThemeProps;
    }
  }
}

@freezed
abstract class ScriptProps with _$ScriptProps {
  const factory ScriptProps({@Default([]) List<Script> scripts}) = _ScriptProps;

  factory ScriptProps.fromJson(Map<String, Object?> json) =>
      _$ScriptPropsFromJson(json);
}

extension ScriptPropsExt on ScriptProps {
  Script? findScript(String? id) =>
      scripts.where((script) => script.id == id).firstOrNull;

  Script? scriptOf(Profile profile) =>
      profile.isManaged ? null : findScript(profile.scriptId);

  Script? scriptById(String id) {
    final index = scripts.indexWhere((script) => script.id == id);
    if (index != -1) {
      return scripts[index];
    }
    return null;
  }

  Future<ScriptProps> externalize() async {
    if (scripts.every((script) => script.content.isEmpty)) return this;
    final next = <Script>[];
    for (final script in scripts) {
      if (script.content.isEmpty) {
        next.add(script);
        continue;
      }
      try {
        next.add(await script.writeContent(script.content));
      } catch (e) {
        commonPrint.error('Failed to store script ${script.label}: $e');
        next.add(script);
      }
    }
    return copyWith(scripts: next);
  }
}

@freezed
abstract class CustomRoute with _$CustomRoute {
  const factory CustomRoute({
    required String id,
    required String name,
    String? icon,
    @Default([]) List<String> sets,
    String? target,
    @Default(true) bool enabled,
  }) = _CustomRoute;

  factory CustomRoute.fromJson(Map<String, Object?> json) =>
      _$CustomRouteFromJson(json);
}

@freezed
abstract class CustomRegion with _$CustomRegion {
  const factory CustomRegion({required String name, required String regex}) =
      _CustomRegion;

  factory CustomRegion.fromJson(Map<String, Object?> json) =>
      _$CustomRegionFromJson(json);
}

@freezed
abstract class ManagedProps with _$ManagedProps {
  const factory ManagedProps({
    @Default({}) Map<String, bool> options,
    String? syncedVersion,
    @Default([]) List<CustomRoute> routes,
    @Default([]) List<String> order,
    @Default([]) List<String> removed,
    List<String>? regions,
    @Default([]) List<CustomRegion> customRegions,
  }) = _ManagedProps;

  factory ManagedProps.fromJson(Map<String, Object?> json) =>
      _$ManagedPropsFromJson(json);
}

@freezed
abstract class Config with _$Config {
  const factory Config({
    @JsonKey(fromJson: AppSettingProps.safeFromJson)
    @Default(defaultAppSettingProps)
    AppSettingProps appSetting,
    @Default([]) List<Profile> profiles,
    @Default([]) List<HotKeyAction> hotKeyActions,
    String? currentProfileId,
    @Default(false) bool overrideDns,
    @Default(false) bool overrideNtp,
    @Default(false) bool overrideSniffer,
    @Default(false) bool overrideTunnel,
    @Default(false) bool overrideExperimental,
    DAV? dav,
    @Default(defaultNetworkProps) NetworkProps networkProps,
    @JsonKey(fromJson: VpnProps.safeFromJson)
    @Default(defaultVpnProps)
    VpnProps vpnProps,
    @JsonKey(fromJson: ThemeProps.safeFromJson) required ThemeProps themeProps,
    @Default(defaultProxiesStyle) ProxiesStyle proxiesStyle,
    @Default(defaultTrafficStatsProps) TrafficStatsProps trafficStatsProps,
    @Default(defaultWindowProps) WindowProps windowProps,
    @JsonKey(fromJson: ClashConfig.safeFormJson)
    @Default(defaultClashConfig)
    ClashConfig patchClashConfig,
    @Default(ScriptProps()) ScriptProps scriptProps,
    @Default(ManagedProps()) ManagedProps managedProps,
    @Default('') String nodeExcludeFilter,
    @Default(5000) int healthCheckTimeout,
  }) = _Config;

  factory Config.fromJson(Map<String, Object?> json) => _$ConfigFromJson(json);

  factory Config.compatibleFromJson(Map<String, Object?> json) {
    try {
      final accessControlMap = json['accessControl'];
      final isAccessControl = json['isAccessControl'];
      if (accessControlMap != null) {
        (accessControlMap as Map)['enable'] = isAccessControl;
        if (json['vpnProps'] != null) {
          (json['vpnProps'] as Map)['accessControl'] = accessControlMap;
        }
      }
    } catch (_) {}

    // Migrate legacy AccessControl sort values: 'name' -> 'none', 'time' -> 'updateTime'
    try {
      void migrateSort(dynamic accessControl) {
        if (accessControl is Map) {
          final sort = accessControl['sort'];
          if (sort == 'name') {
            accessControl['sort'] = 'none';
          } else if (sort == 'time') {
            accessControl['sort'] = 'updateTime';
          }
        }
      }

      migrateSort(json['accessControl']);
      if (json['vpnProps'] is Map) {
        migrateSort((json['vpnProps'] as Map)['accessControl']);
      }
    } catch (_) {}

    // Migrate legacy int profile IDs to string
    try {
      final currentProfileId = json['currentProfileId'];
      if (currentProfileId != null && currentProfileId is int) {
        json['currentProfileId'] = currentProfileId.toString();
      }
    } catch (_) {}

    try {
      final profiles = json['profiles'];
      if (profiles != null && profiles is List) {
        for (final profile in profiles) {
          if (profile is Map) {
            final id = profile['id'];
            if (id != null && id is int) {
              profile['id'] = id.toString();
            }
          }
        }
      }
    } catch (_) {}

    try {
      final scriptProps = json['scriptProps'];
      final profiles = json['profiles'];
      if (scriptProps is Map && profiles is List) {
        final currentId = scriptProps.remove('currentId');
        for (final profile in profiles) {
          if (profile is! Map) continue;
          final enabled = profile.remove('useScriptOverride') != false;
          if (currentId is String &&
              enabled &&
              profile['scriptId'] == null &&
              profile['bundle'] == null) {
            profile['scriptId'] = currentId;
          }
        }
      }
    } catch (_) {}

    try {
      final themeProps = json['themeProps'];
      if (themeProps is Map &&
          themeProps['primaryColor'] != legacyPrimaryColors.last) {
        final colors = themeProps['primaryColors'];
        if (colors is List &&
            intListEquality.equals(colors.cast<int>(), legacyPrimaryColors)) {
          themeProps.remove('primaryColors');
        }
      }
    } catch (_) {}

    return Config.fromJson(json);
  }
}

extension ConfigExt on Config {
  Profile? get currentProfile {
    return profiles.getProfile(currentProfileId);
  }
}
