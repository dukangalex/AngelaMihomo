import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/proxies/common.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'tile.dart';

/// Card-face location text: country · city (city only when the local
/// GeoIP lookup produced one and it differs from the country name).
String networkDetectionLocationText(IpInfo ipInfo) {
  return [
    ipInfo.country,
    if (ipInfo.city != ipInfo.country) ipInfo.city,
  ].where((item) => item?.isNotEmpty ?? false).join(' · ');
}

/// Card-face operator text: ASN + AS name (ISP as fallback).
String networkDetectionOperatorText(IpInfo ipInfo) {
  return [
    ipInfo.asn,
    ipInfo.asName ?? ipInfo.isp,
  ].where((item) => item?.isNotEmpty ?? false).join(' ');
}

/// Compact-card attribution block (T109). The location and operator
/// used to share one ellipsized line next to the IP, which cut the
/// city down to a stub ('United States · B…') on narrow cards. The
/// attribution now sits full-width under the IP line, each element
/// on its own line(s) with no ellipsis: the location (country ·
/// city) may wrap to two lines, the operator gets a full-width line
/// of its own.
class NetworkDetectionAttribution extends StatelessWidget {
  final String location;
  final String operator;

  const NetworkDetectionAttribution({
    super.key,
    required this.location,
    required this.operator,
  });

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.labelSmall?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
      height: 1.1,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (location.isNotEmpty)
          Text(location, maxLines: 2, softWrap: true, style: style),
        if (operator.isNotEmpty)
          Text(operator, maxLines: 1, softWrap: true, style: style),
      ],
    );
  }
}

class NetworkDetection extends ConsumerStatefulWidget {
  final DashboardTileSize? size;

  const NetworkDetection({super.key, this.size});

  @override
  ConsumerState<NetworkDetection> createState() => _NetworkDetectionState();
}

class _NetworkDetectionState extends ConsumerState<NetworkDetection> {
  // T113 global speed test state: while a run is in flight the card
  // header shows live progress; after it finishes the header keeps a
  // one-line summary until the next run or refresh replaces it.
  bool _globalTesting = false;
  int _globalDone = 0;
  int _globalTotal = 0;
  String? _globalSummary;

  String get _headerTitle {
    if (_globalTesting) {
      return '${appLocalizations.globalSpeedTest} $_globalDone/$_globalTotal';
    }
    return _globalSummary ?? appLocalizations.networkDetection;
  }

  Widget _buildGlobalSpeedTestAction(BuildContext context) {
    if (_globalTesting) {
      return AspectRatio(
        aspectRatio: 1,
        child: Center(
          child: SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 1,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: appLocalizations.globalSpeedTest,
        onPressed: _runGlobalSpeedTest,
        icon: Icon(
          size: 16.ap,
          Icons.speed_rounded,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _runGlobalSpeedTest() async {
    if (_globalTesting) return;
    if (ref.read(runTimeProvider) == null) {
      globalState.showNotifier(appLocalizations.globalSpeedTestNeedCore);
      return;
    }
    setState(() {
      _globalTesting = true;
      _globalDone = 0;
      _globalTotal = 0;
      _globalSummary = null;
    });
    try {
      final result = await runGlobalDelayTest(
        onProgress: (done, total) {
          if (!mounted) return;
          setState(() {
            _globalDone = done;
            _globalTotal = total;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _globalTesting = false;
        _globalSummary = result.totalNodes == 0
            ? null
            : appLocalizations.globalSpeedTestSummary(
                result.availableNodes,
                result.totalNodes,
                result.optimizedSelections.length,
              );
      });
      if (result.totalNodes == 0) {
        globalState.showNotifier(appLocalizations.globalSpeedTestNoProxies);
        return;
      }
      _showGlobalSpeedTestResult(result);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _globalTesting = false;
      });
      globalState.showNotifier(appLocalizations.globalSpeedTestFailed);
    }
  }

  void _showGlobalSpeedTestResult(GlobalDelayTestResult result) {
    globalState.showCommonDialog(
      child: CommonDialog(
        title: appLocalizations.globalSpeedTest,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: Text(appLocalizations.confirm),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${appLocalizations.globalSpeedTestTestedLabel}${result.totalNodes}',
            ),
            Text(
              '${appLocalizations.globalSpeedTestAvailableLabel}${result.availableNodes}',
            ),
            Text(
              '${appLocalizations.globalSpeedTestOptimizedLabel}${result.optimizedSelections.length}',
            ),
            if (result.optimizedSelections.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final entry in result.optimizedSelections.entries)
                Text('${entry.key} → ${entry.value}'),
            ],
            if (result.noAvailableGroups.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${appLocalizations.globalSpeedTestKeptLabel}${result.noAvailableGroups.join(', ')}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _countryCodeToEmoji(String countryCode) {
    final String code = countryCode.toUpperCase();
    if (code.length != 2) {
      return countryCode;
    }
    final int firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  void _showIpClickBehaviorSettings() {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    globalState.showCommonDialog<IpClickBehavior>(
      child: CommonDialog(
        title: appLocalizations.ipClickBehavior,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.sync),
              title: Text(appLocalizations.manualRefreshIp),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                detectionState.manualRefresh();
              },
            ),
            if (isZh)
              ListTile(
                leading: Icon(Icons.public),
                title: Text(appLocalizations.switchToDomesticIp),
                onTap: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  detectionState.switchToDomesticIp();
                },
              ),
            ListTile(
              leading: Icon(Icons.security),
              title: Text(appLocalizations.ipPrivacyProtection),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                detectionState.toggleIpPrivacy();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Widget? action,
    Widget? customValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                customValue ??
                    SelectableText(
                      value,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 4), action],
        ],
      ),
    );
  }

  void _showMoreIpInfoDialog() {
    final rawIpInfo = detectionState.rawIpInfo;
    if (rawIpInfo == null) return;

    final flagEmoji = rawIpInfo.countryCode.isNotEmpty
        ? _countryCodeToEmoji(rawIpInfo.countryCode)
        : '';

    final countryName =
        (rawIpInfo.country != null && rawIpInfo.country!.isNotEmpty)
        ? rawIpInfo.country!
        : (rawIpInfo.countryCode.isNotEmpty ? rawIpInfo.countryCode : '');

    final countryContinent = [
      if (countryName.isNotEmpty) countryName,
      if (rawIpInfo.continent != null && rawIpInfo.continent!.isNotEmpty)
        rawIpInfo.continent,
    ].join(' · ');

    final provinceCity = [
      if (rawIpInfo.province != null && rawIpInfo.province!.isNotEmpty)
        rawIpInfo.province,
      if (rawIpInfo.city != null &&
          rawIpInfo.city!.isNotEmpty &&
          rawIpInfo.city != rawIpInfo.province)
        rawIpInfo.city,
    ].join(' · ');

    final ispText = (rawIpInfo.isp != null && rawIpInfo.isp!.isNotEmpty)
        ? rawIpInfo.isp!
        : '';

    final operatorText = [
      if (rawIpInfo.asName != null &&
          rawIpInfo.asName!.isNotEmpty &&
          rawIpInfo.asName != rawIpInfo.isp &&
          rawIpInfo.asName != rawIpInfo.asDomain)
        rawIpInfo.asName,
      if (rawIpInfo.asn != null && rawIpInfo.asn!.isNotEmpty) rawIpInfo.asn,
    ].join(' · ');

    final items = <Widget>[
      _buildStatTile(
        icon: Icons.location_on_rounded,
        iconColor: context.colorScheme.primary,
        label: appLocalizations.ipAddress,
        value: rawIpInfo.ip,
      ),
      if (countryContinent.isNotEmpty || flagEmoji.isNotEmpty)
        _buildStatTile(
          icon: Icons.flag_rounded,
          iconColor: context.colorScheme.secondary,
          label: appLocalizations.countryOrRegion,
          value: countryContinent,
          customValue: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (flagEmoji.isNotEmpty) ...[
                Text(
                  flagEmoji,
                  style: TextStyle(
                    fontFamily: FontFamily.twEmoji.value,
                    fontFamilyFallback: [FontFamily.twEmoji.value],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: SelectableText(
                  countryContinent,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      if (provinceCity.isNotEmpty)
        _buildStatTile(
          icon: Icons.location_city_rounded,
          iconColor: context.colorScheme.tertiary,
          label: appLocalizations.provinceAndCity,
          value: provinceCity,
        ),
      if (operatorText.isNotEmpty)
        _buildStatTile(
          icon: Icons.business_rounded,
          iconColor: context.colorScheme.secondary,
          label: appLocalizations.operatorOrAsn,
          value: operatorText,
        ),
      if (ispText.isNotEmpty)
        _buildStatTile(
          icon: Icons.router_rounded,
          iconColor: context.colorScheme.primary,
          label: appLocalizations.isp,
          value: ispText,
        ),
      if (rawIpInfo.asDomain != null && rawIpInfo.asDomain!.isNotEmpty)
        _buildStatTile(
          icon: Icons.link_rounded,
          iconColor: context.colorScheme.tertiary,
          label: appLocalizations.organizationDomain,
          value: rawIpInfo.asDomain!,
        ),
    ];

    globalState.showCommonDialog(
      child: CommonDialog(
        title: appLocalizations.moreIpInfo,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: Text(appLocalizations.confirm),
          ),
        ],
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, IpInfo? ipInfo) {
    return Container(
      // T109: 6dp shorter than the shared card header so the
      // two-line attribution block fits the one-row card height.
      height: globalState.measure.titleMediumHeight + 10,
      padding: baseInfoEdgeInsets.copyWith(bottom: 0),
      child: Row(
        children: [
          ipInfo != null
              ? Text(
                  _countryCodeToEmoji(ipInfo.countryCode),
                  style: Theme.of(context).textTheme.titleMedium?.toLight
                      .copyWith(
                        fontFamily: FontFamily.twEmoji.value,
                        fontFamilyFallback: [FontFamily.twEmoji.value],
                      ),
                )
              : Icon(
                  Icons.network_check,
                  color: context.colorScheme.onSurfaceVariant,
                ),
          const SizedBox(width: 8),
          Flexible(
            child: TooltipText(
              text: Text(
                _headerTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          _buildGlobalSpeedTestAction(context),
          const SizedBox(width: 2),
          AspectRatio(
            aspectRatio: 1,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: _showIpClickBehaviorSettings,
              icon: Icon(
                size: 16.ap,
                Icons.settings_outlined,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            // T109: detail values (location, operator) wrap to two
            // lines instead of ellipsizing the tail away.
            maxLines: 2,
            softWrap: true,
            style: context.textTheme.bodyMedium?.toLight,
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, DashboardTileSize size) {
    final isTall = size == DashboardTileSize.tall;
    return SizedBox(
      height: getWidgetHeight(context, size.rows),
      child: ValueListenableBuilder<NetworkDetectionState>(
        valueListenable: detectionState.state,
        builder: (_, state, _) {
          final ipInfo = state.ipInfo;
          final masked = detectionState.isIpMasked;
          final location = ipInfo == null
              ? ''
              : networkDetectionLocationText(ipInfo);
          final operator = ipInfo == null
              ? ''
              : networkDetectionOperatorText(ipInfo);
          final countryCode = ipInfo?.countryCode ?? '';
          final ipText = ipInfo != null
              ? Text(
                  ipInfo.ip,
                  style: context.textTheme.bodyMedium?.toLight.adjustSize(1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : state.isLoading == false
              ? Text(
                  state.errorMessage ?? 'timeout',
                  style: context.textTheme.bodyMedium
                      ?.copyWith(color: Colors.red)
                      .adjustSize(1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: 1,
                  child: SpinKitThreeBounce(
                    color: context.colorScheme.primary,
                    size: 16,
                  ),
                );
          return CommonCard(
            onPressed: ipInfo != null ? _showMoreIpInfoDialog : () {},
            child: DashboardDecor(
              mark: countryCode.length == 2
                  ? DashboardDecor.flag(countryCode, 80)
                  : DashboardDecor.icon(context, Icons.public, 80),
              angle: isTall ? 0.18 : -0.18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isTall
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeader(context, ipInfo),
                  if (isTall)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 12, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: globalState.measure.bodyMediumHeight + 2,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: ipText,
                            ),
                          ),
                          if (!masked && location.isNotEmpty)
                            _buildDetail(
                              context,
                              appLocalizations.countryOrRegion,
                              location,
                            ),
                          if (!masked && operator.isNotEmpty)
                            _buildDetail(
                              context,
                              appLocalizations.operatorOrAsn,
                              operator,
                            ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: baseInfoEdgeInsets.copyWith(top: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: globalState.measure.bodyMediumHeight + 2,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [Flexible(child: ipText)],
                            ),
                          ),
                          if (!masked && ipInfo != null) ...[
                            const SizedBox(height: 2),
                            NetworkDetectionAttribution(
                              location: location,
                              operator: operator,
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.size case final size?) return _buildTile(context, size);
    return SizedBox(
      height: getWidgetHeight(context, 1),
      child: ValueListenableBuilder<NetworkDetectionState>(
        valueListenable: detectionState.state,
        builder: (_, state, _) {
          final ipInfo = state.ipInfo;
          final isLoading = state.isLoading;
          final masked = detectionState.isIpMasked;
          final location = ipInfo == null
              ? ''
              : networkDetectionLocationText(ipInfo);
          final operator = ipInfo == null
              ? ''
              : networkDetectionOperatorText(ipInfo);
          return CommonCard(
            onPressed: ipInfo != null ? _showMoreIpInfoDialog : () {},
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  // T109: see _buildHeader — 6dp shorter so the
                  // two-line attribution fits the one-row height.
                  height: globalState.measure.titleMediumHeight + 10,
                  padding: baseInfoEdgeInsets.copyWith(bottom: 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ipInfo != null
                          ? Text(
                              _countryCodeToEmoji(ipInfo.countryCode),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.toLight
                                  .copyWith(
                                    fontFamily: FontFamily.twEmoji.value,
                                    fontFamilyFallback: [
                                      FontFamily.twEmoji.value,
                                    ],
                                  ),
                            )
                          : Icon(
                              Icons.network_check,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 1,
                        child: TooltipText(
                          text: Text(
                            _headerTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                      SizedBox(width: 2),
                      _buildGlobalSpeedTestAction(context),
                      SizedBox(width: 2),
                      AspectRatio(
                        aspectRatio: 1,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: _showIpClickBehaviorSettings,
                          icon: Icon(
                            size: 16.ap,
                            Icons.settings_outlined,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: baseInfoEdgeInsets.copyWith(top: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: globalState.measure.bodyMediumHeight + 2,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: FadeThroughBox(
                                child: ipInfo != null
                                    ? TooltipText(
                                        text: Text(
                                          ipInfo.ip,
                                          style: context
                                              .textTheme
                                              .bodyMedium
                                              ?.toLight
                                              .adjustSize(1),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    : FadeThroughBox(
                                        child:
                                            isLoading == false && ipInfo == null
                                            ? Text(
                                                state.errorMessage ?? 'timeout',
                                                style: context
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: Colors.red,
                                                    )
                                                    .adjustSize(1),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              )
                                            : Container(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                child: Center(
                                                  child: OverflowBox(
                                                    maxWidth: 30,
                                                    maxHeight: 16,
                                                    child: SpinKitThreeBounce(
                                                      color: context
                                                          .colorScheme
                                                          .primary,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!masked &&
                          (location.isNotEmpty || operator.isNotEmpty)) ...[
                        const SizedBox(height: 2),
                        NetworkDetectionAttribution(
                          location: location,
                          operator: operator,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
