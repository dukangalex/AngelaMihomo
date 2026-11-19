import 'dart:io';

import 'package:angelamihomo/clash/clash.dart';
import 'package:angelamihomo/common/geo_data.dart';
import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/providers/app.dart';
import 'package:angelamihomo/providers/config.dart';
import 'package:angelamihomo/views/proxies/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart' hide context;

final geoUpdatingKeysProvider = StateProvider.autoDispose<Set<String>>(
  (ref) => {},
);

@immutable
class GeoItem {
  final String label;
  final String key;
  final String fileName;

  const GeoItem({
    required this.label,
    required this.key,
    required this.fileName,
  });
}

class ResourcesView extends ConsumerStatefulWidget {
  const ResourcesView({super.key});

  @override
  ConsumerState<ResourcesView> createState() => _ResourcesViewState();
}

class _ResourcesViewState extends ConsumerState<ResourcesView> {
  bool? _showProviders;

  static const geoItems = <GeoItem>[
    GeoItem(label: 'GeoSite', fileName: geoSiteFileName, key: 'geosite'),
    GeoItem(label: 'MMDB', fileName: mmdbFileName, key: 'mmdb'),
    GeoItem(label: 'ASN', fileName: asnFileName, key: 'asn'),
    GeoItem(label: 'MRS', fileName: bundleMRSFileName, key: 'mrs'),
  ];

  Future<void> _handleSyncAll() async {
    final updatingKeysNotifier = ref.read(geoUpdatingKeysProvider.notifier);
    if (updatingKeysNotifier.state.isNotEmpty) return;

    final syncItems = geoItems
        .where((geoItem) => geoItem.key != 'mrs')
        .toList();
    updatingKeysNotifier.state = {...syncItems.map((e) => e.key), 'city'};

    final errors = <String>[];
    try {
      await Future.wait(
        syncItems.map((geoItem) async {
          try {
            final message = await clashCore.updateGeoData(
              UpdateGeoDataParams(
                geoName: geoItem.fileName,
                geoType: geoItem.label,
              ),
            );
            if (message.isNotEmpty) {
              errors.add('${geoItem.label}: $message');
            }
          } catch (e) {
            errors.add('${geoItem.label}: $e');
          } finally {
            if (mounted) {
              updatingKeysNotifier.update(
                (s) => Set.of(s)..remove(geoItem.key),
              );
            }
          }
        }),
      );
      try {
        final outcome = await globalState.appController.updateGeoData();
        if (outcome == GeoUpdateOutcome.failed ||
            outcome == GeoUpdateOutcome.verifyFailed) {
          errors.add(
            '${appLocalizations.geoData}: ${appLocalizations.geoDataUpdateFailed}',
          );
        }
      } catch (e) {
        errors.add('${appLocalizations.geoData}: $e');
      } finally {
        if (mounted) {
          updatingKeysNotifier.update((s) => Set.of(s)..remove('city'));
        }
      }
      if (errors.isNotEmpty) {
        globalState.showMessage(
          title: appLocalizations.syncFailed,
          message: TextSpan(text: errors.join('\n')),
          cancelable: false,
        );
      }
    } finally {
      if (mounted) {
        updatingKeysNotifier.state = {};
      }
    }
  }

  Future<void> _handleResetAll() async {
    final res = await globalState.showMessage(
      title: appLocalizations.reset,
      message: TextSpan(text: appLocalizations.resetTip),
    );
    if (res != true) {
      return;
    }
    ref.read(patchClashConfigProvider.notifier).updateState((state) {
      return state.copyWith(geoXUrl: defaultGeoXUrl);
    });
    await globalState.appController.setupClashConfig();
  }

  Widget _buildTitleItem(String label, bool showProviders) {
    final isCurrent = _showProviders == showProviders;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isCurrent
          ? null
          : () {
              setState(() {
                _showProviders = showProviders;
              });
            },
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isCurrent
            ? null
            : TextStyle(
                color: context.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: _buildTitleItem(appLocalizations.providers, true)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '|',
            style: TextStyle(
              color: context.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.5,
              ),
            ),
          ),
        ),
        Flexible(child: _buildTitleItem(appLocalizations.resources, false)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUpdating = ref.watch(
      geoUpdatingKeysProvider.select((keys) => keys.isNotEmpty),
    );
    final hasProviders = ref.watch(
      providersProvider.select((state) => state.isNotEmpty),
    );
    final showProviders = hasProviders && (_showProviders ??= true);

    if (showProviders) {
      return CommonScaffold(
        titleWidget: _buildTitle(),
        actions: [
          IconButton(
            onPressed: () => updateExternalProviders(ref, context),
            tooltip: appLocalizations.update,
            icon: const Icon(Icons.sync),
          ),
        ],
        body: const ProvidersBody(),
      );
    }

    return CommonScaffold(
      title: hasProviders ? null : appLocalizations.resources,
      titleWidget: hasProviders ? _buildTitle() : null,
      actions: hasProviders
          ? [
              CommonPopupBox(
                targetBuilder: (open) {
                  return IconButton(
                    onPressed: () {
                      open(offset: const Offset(0, 20));
                    },
                    tooltip: appLocalizations.more,
                    icon: isUpdating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: SyncedLoading(
                              size: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.more_vert),
                  );
                },
                popup: CommonPopupMenu(
                  items: [
                    PopupMenuItemData(
                      icon: Icons.sync,
                      label: appLocalizations.syncAll,
                      onPressed: isUpdating ? null : _handleSyncAll,
                    ),
                    PopupMenuItemData(
                      icon: Icons.replay,
                      label: appLocalizations.reset,
                      onPressed: _handleResetAll,
                    ),
                  ],
                ),
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.replay),
                onPressed: _handleResetAll,
                tooltip: appLocalizations.reset,
              ),
              IconButton(
                icon: isUpdating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: SyncedLoading(
                          size: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.sync),
                onPressed: isUpdating ? null : _handleSyncAll,
                tooltip: appLocalizations.syncAll,
              ),
            ],
      body: ScrollEdgeRise(
        builder: (context, rise) => ListView(
          padding: EdgeInsets.only(
            bottom: 16.0 + MediaQuery.paddingOf(context).bottom,
            top: 8 + rise,
          ),
          children: [
            ListHeader(
              title: appLocalizations.geoBuiltInResources,
              padding: const EdgeInsets.only(
                left: 16,
                right: 8,
                top: 4,
                bottom: 8,
              ),
              actions: [
                if (Theme.of(context).materialTapTargetSize ==
                    MaterialTapTargetSize.padded)
                  const SizedBox(height: kMinInteractiveDimension),
              ],
            ),
            ...generateSection(
              items: [
                ...geoItems.map((geoItem) => GeoDataListItem(geoItem: geoItem)),
                const CityDataListItem(),
              ],
            ),
            ...generateSection(
              items: const [
                DataAutoUpdateListItem(),
                ManagedScriptChannelListItem(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GeoDataListItem extends ConsumerStatefulWidget {
  final GeoItem geoItem;

  const GeoDataListItem({super.key, required this.geoItem});

  @override
  ConsumerState<GeoDataListItem> createState() => _GeoDataListItemState();
}

class _GeoDataListItemState extends ConsumerState<GeoDataListItem> {
  GeoItem get geoItem => widget.geoItem;

  Future<void> _updateUrl(String url) async {
    final defaultValue = switch (geoItem.key) {
      'mmdb' => defaultGeoXUrl.mmdb,
      'asn' => defaultGeoXUrl.asn,
      'geosite' => defaultGeoXUrl.geosite,
      _ => null,
    };
    final newUrl = await globalState.showCommonDialog<String>(
      child: UpdateGeoUrlFormDialog(
        title: geoItem.label,
        url: url,
        defaultValue: defaultValue,
      ),
    );
    if (newUrl != null && newUrl != url && mounted) {
      try {
        if (!newUrl.isHttpUrl) {
          throw 'Invalid url';
        }
        ref.read(patchClashConfigProvider.notifier).updateState((state) {
          final geoXUrl = switch (geoItem.key) {
            'mmdb' => state.geoXUrl.copyWith(mmdb: newUrl),
            'asn' => state.geoXUrl.copyWith(asn: newUrl),
            'geosite' => state.geoXUrl.copyWith(geosite: newUrl),
            _ => state.geoXUrl,
          };
          return state.copyWith(geoXUrl: geoXUrl);
        });
        await globalState.appController.setupClashConfig();
      } catch (e) {
        globalState.showMessage(
          title: geoItem.label,
          message: TextSpan(text: e.toString()),
          cancelable: false,
        );
      }
    }
  }

  Future<FileInfo> _getGeoFileLastModified(String fileName) async {
    final homePath = await appPath.homeDirPath;
    final file = File(join(homePath, fileName));
    final lastModified = await file.lastModified();
    final size = await file.length();
    return FileInfo(size: size, lastModified: lastModified);
  }

  Future<void> _handleUpdateGeoDataItem() async {
    final updatingKeysNotifier = ref.read(geoUpdatingKeysProvider.notifier);
    if (ref.read(geoUpdatingKeysProvider).contains(geoItem.key)) return;

    await globalState.appController.safeRun<void>(
      () async {
        updatingKeysNotifier.update((s) => Set.of(s)..add(geoItem.key));
        try {
          final message = await clashCore.updateGeoData(
            UpdateGeoDataParams(
              geoName: geoItem.fileName,
              geoType: geoItem.label,
            ),
          );
          if (message.isNotEmpty) throw message;
        } finally {
          if (mounted) {
            updatingKeysNotifier.update((s) => Set.of(s)..remove(geoItem.key));
          }
        }
      },
      silence: false,
      needLoading: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(geoUpdatingKeysProvider.select((s) => s.contains(geoItem.key)), (
      prev,
      next,
    ) {
      if (prev == true && next == false && mounted) {
        setState(() {});
      }
    });

    final url = ref.watch(
      patchClashConfigProvider.select(
        (state) => switch (geoItem.key) {
          'mmdb' => state.geoXUrl.mmdb,
          'asn' => state.geoXUrl.asn,
          'geosite' => state.geoXUrl.geosite,
          _ => null,
        },
      ),
    );
    final isSyncing = ref.watch(
      geoUpdatingKeysProvider.select((s) => s.contains(geoItem.key)),
    );
    final isBundleMRS = geoItem.key == 'mrs';

    return ListItem(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(geoItem.label),
      subtitle: (url == null && !isBundleMRS)
          ? const SizedBox()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                FutureBuilder<FileInfo>(
                  future: _getGeoFileLastModified(geoItem.fileName),
                  builder: (_, snapshot) {
                    final height = globalState.measure.bodyMediumHeight;
                    return SizedBox(
                      height: height,
                      child: snapshot.data == null
                          ? SizedBox(width: height, height: height)
                          : Text(
                              isBundleMRS
                                  ? '${TrafficValue(value: snapshot.data!.size).show}  ·  Bundled'
                                  : snapshot.data!.desc,
                              style: context.textTheme.bodyMedium,
                            ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  isBundleMRS
                      ? 'https://github.com/dukangalex/angelamihomo-geo/releases/download/core-bundle-2026.11/BundleMRS.7z'
                      : url!,
                  style: context.textTheme.bodyMedium?.toLight,
                ),
                if (!isBundleMRS) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    runSpacing: 6,
                    spacing: 12,
                    runAlignment: WrapAlignment.center,
                    children: [
                      CommonChip(
                        avatar: const Icon(Icons.edit),
                        label: appLocalizations.edit,
                        onPressed: isSyncing || url == null
                            ? null
                            : () => _updateUrl(url),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          isSyncing
                              ? const SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: Padding(
                                    padding: EdgeInsets.all(2),
                                    child: SyncedLoading(
                                      size: 26,
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                )
                              : CommonChip(
                                  avatar: const Icon(Icons.sync),
                                  label: appLocalizations.sync,
                                  onPressed: _handleUpdateGeoDataItem,
                                ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

/// T194: the city-level geolocation database, listed with the other
/// GEO resources at the user's direction. Unlike the core-managed
/// files above it is pulled by the app itself (see GeoDataService),
/// by default from the project's own data repository. The row
/// mirrors the sibling rows (size · age, source URL, edit and sync
/// chips): the source is editable like theirs (T201, the user's
/// call — users decide their own data source), with the project
/// repository as the default the edit dialog resets to.
class CityDataListItem extends ConsumerStatefulWidget {
  const CityDataListItem({super.key});

  @override
  ConsumerState<CityDataListItem> createState() => _CityDataListItemState();
}

class _CityDataListItemState extends ConsumerState<CityDataListItem> {
  static const _releasesUrl =
      'https://github.com/$geoDataRepository/releases';

  String _repoAssetUrl(String tag) =>
      'https://github.com/$geoDataRepository/releases/download/$tag/${GeoDataService.assetName}';

  Future<(GeoDataMeta?, FileInfo?, String?, String?)> _load() async {
    final service = GeoDataService();
    final custom = await service.customSourceUrl();
    final meta = await service.currentMeta();
    // Before the first download the row used to show the releases
    // page URL while every sibling row shows its file URL — and the
    // same app in a downloaded state showed the file URL, which read
    // as a platform difference (T216). Resolve the address the pull
    // will actually use, the same way the pull resolves it.
    final latestUrl = meta == null && custom == null
        ? await service.latestDataAssetUrl()
        : null;
    if (meta == null) return (null, null, custom, latestUrl);
    try {
      final homePath = await appPath.homeDirPath;
      final file = File(join(homePath, GeoDataService.dataFileName));
      final info = FileInfo(
        size: await file.length(),
        lastModified: await file.lastModified(),
      );
      return (meta, info, custom, latestUrl);
    } catch (_) {
      return (meta, null, custom, latestUrl);
    }
  }

  /// T201: edit the city database source, mirroring the sibling GEO
  /// rows. The dialog's reset target is the project repository's
  /// releases page; submitting it (or the URL already in effect)
  /// restores the default channel. Any other URL becomes the source
  /// and is synced from immediately, on this page.
  Future<void> _updateUrl() async {
    final service = GeoDataService();
    final custom = await service.customSourceUrl();
    final meta = await service.currentMeta();
    final current =
        custom ??
        meta?.sourceUrl ??
        (meta == null ? _releasesUrl : _repoAssetUrl(meta.tag));
    final newUrl = await globalState.showCommonDialog<String>(
      child: UpdateGeoUrlFormDialog(
        title: appLocalizations.geoData,
        url: current,
        defaultValue: _releasesUrl,
      ),
    );
    if (newUrl == null || !mounted) return;
    try {
      if (newUrl == _releasesUrl || newUrl == current) {
        if (custom != null) {
          await service.setCustomSourceUrl(null);
          if (mounted) await _handleSync();
        }
        return;
      }
      if (!newUrl.isHttpUrl) {
        throw 'Invalid url';
      }
      await service.setCustomSourceUrl(newUrl);
      if (mounted) await _handleSync();
    } catch (e) {
      globalState.showMessage(
        title: appLocalizations.geoData,
        message: TextSpan(text: e.toString()),
        cancelable: false,
      );
    }
  }

  Future<void> _handleSync() async {
    final updatingKeysNotifier = ref.read(geoUpdatingKeysProvider.notifier);
    if (ref.read(geoUpdatingKeysProvider).contains('city')) return;
    updatingKeysNotifier.update((s) => Set.of(s)..add('city'));
    try {
      final outcome = await globalState.appController.updateGeoData();
      if (!mounted) return;
      final message = switch (outcome) {
        GeoUpdateOutcome.updated => appLocalizations.geoDataUpdated,
        GeoUpdateOutcome.alreadyLatest => appLocalizations.geoDataUpToDate,
        GeoUpdateOutcome.verifyFailed => appLocalizations.geoDataVerifyFailed,
        GeoUpdateOutcome.failed => appLocalizations.geoDataUpdateFailed,
      };
      context.showNotifier(message);
    } finally {
      if (mounted) {
        updatingKeysNotifier.update((s) => Set.of(s)..remove('city'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(geoUpdatingKeysProvider.select((s) => s.contains('city')), (
      prev,
      next,
    ) {
      if (prev == true && next == false && mounted) {
        setState(() {});
      }
    });
    final isSyncing = ref.watch(
      geoUpdatingKeysProvider.select((s) => s.contains('city')),
    );
    return ListItem(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(appLocalizations.geoData),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          FutureBuilder<(GeoDataMeta?, FileInfo?, String?, String?)>(
            future: _load(),
            builder: (_, snapshot) {
              final height = globalState.measure.bodyMediumHeight;
              final data = snapshot.data;
              if (snapshot.connectionState != ConnectionState.done ||
                  data == null) {
                return SizedBox(width: height, height: height);
              }
              final (meta, info, custom, latestUrl) = data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: height,
                    child: Text(
                      meta == null
                          ? appLocalizations.geoDataNotDownloaded
                          : info?.desc ?? meta.tag,
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    custom ??
                        (meta == null
                            ? (latestUrl ?? _releasesUrl)
                            : _repoAssetUrl(meta.tag)),
                    style: context.textTheme.bodyMedium?.toLight,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            runSpacing: 6,
            spacing: 12,
            runAlignment: WrapAlignment.center,
            children: [
              CommonChip(
                avatar: const Icon(Icons.edit),
                label: appLocalizations.edit,
                onPressed: isSyncing ? null : _updateUrl,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isSyncing
                      ? const SizedBox(
                          height: 30,
                          width: 30,
                          child: Padding(
                            padding: EdgeInsets.all(2),
                            child: SyncedLoading(
                              size: 26,
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        )
                      : CommonChip(
                          avatar: const Icon(Icons.sync),
                          label: appLocalizations.sync,
                          onPressed: _handleSync,
                        ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UpdateGeoUrlFormDialog extends StatefulWidget {
  final String title;
  final String url;
  final String? defaultValue;

  const UpdateGeoUrlFormDialog({
    super.key,
    required this.title,
    required this.url,
    this.defaultValue,
  });

  @override
  State<UpdateGeoUrlFormDialog> createState() => _UpdateGeoUrlFormDialogState();
}

class _UpdateGeoUrlFormDialogState extends State<UpdateGeoUrlFormDialog> {
  late TextEditingController urlController;

  @override
  void initState() {
    super.initState();
    urlController = TextEditingController(text: widget.url);
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (widget.defaultValue == null) {
      return;
    }
    Navigator.of(context).pop<String>(widget.defaultValue);
  }

  Future<void> _handleUpdate() async {
    final url = urlController.value.text;
    if (url.isEmpty) return;
    Navigator.of(context).pop<String>(url);
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: widget.title,
      actions: [
        if (widget.defaultValue != null &&
            urlController.value.text != widget.defaultValue) ...[
          TextButton(
            onPressed: _handleReset,
            child: Text(appLocalizations.reset),
          ),
          const SizedBox(width: 4),
        ],
        TextButton(
          onPressed: _handleUpdate,
          child: Text(appLocalizations.submit),
        ),
      ],
      child: Wrap(
        runSpacing: 16,
        children: [
          TextField(
            maxLines: 5,
            minLines: 1,
            controller: urlController,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}

/// chain.28 (T199): the single switch for every data-channel auto
/// update — the city database above and the managed script below,
/// plus the core-side geo update interval. Mirrors the
/// AutoCheckUpdateItem pattern from the application settings page.
class DataAutoUpdateListItem extends ConsumerWidget {
  const DataAutoUpdateListItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAutoUpdate = ref.watch(
      appSettingProvider.select((state) => state.dataAutoUpdate),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.dataAutoUpdate),
      subtitle: Text(appLocalizations.dataAutoUpdateDesc),
      delegate: SwitchDelegate(
        value: dataAutoUpdate,
        onChanged: (bool value) {
          ref
              .read(appSettingProvider.notifier)
              .updateState((state) => state.copyWith(dataAutoUpdate: value));
        },
      ),
    );
  }
}

/// chain.28 (T199/T220): the managed script's data-channel status,
/// listed with the other external resources. Shows the script
/// version actually in effect (the channel copy when it is at least
/// the bundled one, otherwise the bundled asset), when the channel
/// copy last landed, and the last check's outcome — a failure is
/// shown with its recorded reason, never hidden.
class ManagedScriptChannelListItem extends StatelessWidget {
  const ManagedScriptChannelListItem({super.key});

  Future<
    ({
      ManagedScriptChannelStatus status,
      String? bundledVersion,
      String? effectiveVersion,
    })
  >
  _load() {
    final bundled = ManagedScript.bundledVersion;
    return ManagedScriptUpdateService().currentStatus(
      bundledVersion: bundled.isEmpty ? null : bundled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListItem(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: const Text('managed.js'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          FutureBuilder<
            ({
              ManagedScriptChannelStatus status,
              String? bundledVersion,
              String? effectiveVersion,
            })
          >(
            future: _load(),
            builder: (_, snapshot) {
              final height = globalState.measure.bodyMediumHeight;
              final data = snapshot.data;
              if (snapshot.connectionState != ConnectionState.done ||
                  data == null) {
                return SizedBox(width: height, height: height);
              }
              final status = data.status;
              final effective = data.effectiveVersion;
              final fromChannel =
                  status.channelVersion != null &&
                  effective == status.channelVersion;
              final failed =
                  status.lastOutcome == 'failed' && status.lastError != null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: height,
                    child: Text(
                      [
                        if (effective != null) 'v$effective',
                        fromChannel ? 'Channel' : 'Bundled',
                        if (status.updatedAt != null)
                          status.updatedAt!.lastUpdateTimeDesc,
                      ].join('  ·  '),
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bundleMRSRawUrl}managed.js',
                    style: context.textTheme.bodyMedium?.toLight,
                  ),
                  if (failed) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${appLocalizations.geoDataUpdateFailed}: ${status.lastError}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
