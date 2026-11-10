// ignore_for_file: invalid_annotation_target
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bett_box/clash/core.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/common/import_normalize.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/core.dart';
import 'package:bett_box/state.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'clash_config.dart';

part 'generated/profile.freezed.dart';
part 'generated/profile.g.dart';

typedef SelectedMap = Map<String, String>;

@freezed
abstract class SubscriptionInfo with _$SubscriptionInfo {
  const factory SubscriptionInfo({
    @Default(0) int upload,
    @Default(0) int download,
    @Default(0) int total,
    @Default(0) int expire,
  }) = _SubscriptionInfo;

  factory SubscriptionInfo.fromJson(Map<String, Object?> json) =>
      _$SubscriptionInfoFromJson(json);

  static int? _parseValue(String? value) {
    if (value == null) return null;
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }

  factory SubscriptionInfo.formHString(String? info) {
    if (info == null) return const SubscriptionInfo();
    final list = info.split(';');
    Map<String, int?> map = {};
    for (final i in list) {
      final keyValue = i.trim().split('=');
      if (keyValue.length < 2) continue;
      map[keyValue[0]] = _parseValue(keyValue[1]);
    }
    return SubscriptionInfo(
      upload: map['upload'] ?? 0,
      download: map['download'] ?? 0,
      total: map['total'] ?? 0,
      expire: map['expire'] ?? 0,
    );
  }
}

extension SubscriptionInfoExtension on SubscriptionInfo {
  String? get expireDesc {
    if (expire > 0) {
      final expireDate = DateTime.fromMillisecondsSinceEpoch(
        expire * 1000,
      ).show;
      final isExpired = expire * 1000 < DateTime.now().millisecondsSinceEpoch;
      return isExpired
          ? '${appLocalizations.expired} · $expireDate'
          : expireDate;
    }
    return total > 0 ? appLocalizations.infiniteTime : null;
  }

  /// Whole days left before expiry (negative once expired); null
  /// when the subscription reports no expiry.
  int? get daysUntilExpire {
    if (expire <= 0) return null;
    final expireAt = DateTime.fromMillisecondsSinceEpoch(expire * 1000);
    return expireAt.difference(DateTime.now()).inDays;
  }

  /// T57: warn when expiry is a week away or already passed.
  bool get expireWarning {
    final days = daysUntilExpire;
    return days != null && days <= 7;
  }

  /// Remaining traffic share in [0, 1]; null when no total is known.
  double? get remainingTrafficRatio {
    if (total <= 0) return null;
    return ((total - upload - download) / total).clamp(0.0, 1.0);
  }

  /// T57: warn when less than a tenth of the traffic remains.
  bool get trafficWarning {
    final ratio = remainingTrafficRatio;
    return ratio != null && ratio < 0.10;
  }
}

@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    String? label,
    String? currentGroupName,
    @Default('') String url,
    DateTime? lastUpdateDate,
    required Duration autoUpdateDuration,
    SubscriptionInfo? subscriptionInfo,
    @Default(true) bool autoUpdate,
    @Default({}) SelectedMap selectedMap,
    @Default({}) Set<String> unfoldSet,
    @Default(OverrideData()) OverrideData overrideData,
    @JsonKey(includeToJson: false, includeFromJson: false)
    @Default(false)
    bool isUpdating,
    @Default(false) bool useScriptOverride,
    String? scriptId,
    String? ageSecretKey,
    @JsonKey(name: 'group-switches')
    @Default({})
    Map<String, bool> groupSwitches,
    // T76: per-group parameter overrides, keyed by group name. Stored on
    // the profile (never written into the subscription file) and applied
    // Go-side on every setup, so subscription updates cannot wash them
    // away. Only fields that differ from the subscription values are kept.
    @JsonKey(name: 'group-overrides')
    @Default({})
    Map<String, ProxyGroupOverride> groupOverrides,
  }) = _Profile;

  factory Profile.fromJson(Map<String, Object?> json) =>
      _$ProfileFromJson(json);

  factory Profile.normal({
    String? label,
    String url = '',
    String? ageSecretKey,
  }) {
    return Profile(
      label: label,
      url: url,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      autoUpdateDuration: defaultUpdateDuration,
      ageSecretKey: ageSecretKey,
    );
  }
}

@freezed
abstract class OverrideData with _$OverrideData {
  const factory OverrideData({
    @Default(false) bool enable,
    @Default(OverrideRule()) OverrideRule rule,
  }) = _OverrideData;

  factory OverrideData.fromJson(Map<String, Object?> json) =>
      _$OverrideDataFromJson(json);
}

extension OverrideDataExt on OverrideData {
  List<String> get runningRule {
    if (!enable) {
      return [];
    }
    return rule.rules.map((item) => item.value).toList();
  }
}

@freezed
abstract class OverrideRule with _$OverrideRule {
  const factory OverrideRule({
    @Default(OverrideRuleType.added) OverrideRuleType type,
    @Default([]) List<Rule> overrideRules,
    @Default([]) List<Rule> addedRules,
  }) = _OverrideRule;

  factory OverrideRule.fromJson(Map<String, Object?> json) =>
      _$OverrideRuleFromJson(json);
}

/// T76: one proxy group's overridden parameters. A null field means "not
/// overridden — follow the subscription". JSON keys are the kernel's own
/// field names (GroupCommonOption & friends), so the persisted form and
/// the patch form sent to the core share one vocabulary.
@freezed
abstract class ProxyGroupOverride with _$ProxyGroupOverride {
  @JsonSerializable(includeIfNull: false)
  const factory ProxyGroupOverride({
    String? url,
    int? interval,
    bool? lazy,
    int? timeout,
    @JsonKey(name: 'max-failed-times') int? maxFailedTimes,
    String? filter,
    @JsonKey(name: 'exclude-filter') String? excludeFilter,
    @JsonKey(name: 'exclude-type') String? excludeType,
    @JsonKey(name: 'expected-status') String? expectedStatus,
    bool? hidden,
    String? icon,
    int? tolerance,
    @JsonKey(name: 'default-selected') String? defaultSelected,
    @JsonKey(name: 'empty-fallback') String? emptyFallback,
    @JsonKey(name: 'disable-udp') bool? disableUdp,
    @JsonKey(name: 'include-all') bool? includeAll,
    @JsonKey(name: 'include-all-proxies') bool? includeAllProxies,
    @JsonKey(name: 'include-all-providers') bool? includeAllProviders,
    String? strategy,
    @JsonKey(name: 'hash-key') String? hashKey,
  }) = _ProxyGroupOverride;

  factory ProxyGroupOverride.fromJson(Map<String, Object?> json) =>
      _$ProxyGroupOverrideFromJson(json);
}

extension ProxyGroupOverrideExt on ProxyGroupOverride {
  /// Kernel-keyed patch entries for the Go patch pipeline; only fields the
  /// user actually overrode are present.
  Map<String, Object?> toPatchMap() {
    return {
      if (url != null) 'url': url,
      if (interval != null) 'interval': interval,
      if (lazy != null) 'lazy': lazy,
      if (timeout != null) 'timeout': timeout,
      if (maxFailedTimes != null) 'max-failed-times': maxFailedTimes,
      if (filter != null) 'filter': filter,
      if (excludeFilter != null) 'exclude-filter': excludeFilter,
      if (excludeType != null) 'exclude-type': excludeType,
      if (expectedStatus != null) 'expected-status': expectedStatus,
      if (hidden != null) 'hidden': hidden,
      if (icon != null) 'icon': icon,
      if (tolerance != null) 'tolerance': tolerance,
      if (defaultSelected != null) 'default-selected': defaultSelected,
      if (emptyFallback != null) 'empty-fallback': emptyFallback,
      if (disableUdp != null) 'disable-udp': disableUdp,
      if (includeAll != null) 'include-all': includeAll,
      if (includeAllProxies != null)
        'include-all-proxies': includeAllProxies,
      if (includeAllProviders != null)
        'include-all-providers': includeAllProviders,
      if (strategy != null) 'strategy': strategy,
      if (hashKey != null) 'hash-key': hashKey,
    };
  }

  bool get isEmpty => toPatchMap().isEmpty;
}

/// T81 S-5: group names that carry per-group App state on [profile] —
/// a parameter override (groupOverrides) or a remembered selection
/// (selectedMap) — but are absent from [groupNames], the group set the
/// profile currently provides. Both stores are keyed by group name,
/// so a subscription-side rename (or a hand edit in the full-text
/// editor) used to orphan them silently: the override and the
/// selection simply stopped applying, with no signal anywhere. The
/// caller surfaces the returned names to the user; the state itself
/// is kept, so renaming the group back restores it. GLOBAL is exempt:
/// it is bridge-synthesized, never a stored subscription group.
List<String> orphanedGroupStateNames(Profile profile, Set<String> groupNames) {
  final orphans = <String>{
    ...profile.groupOverrides.keys,
    ...profile.selectedMap.keys,
  }..removeWhere((name) => name == 'GLOBAL' || groupNames.contains(name));
  return orphans.toList()..sort();
}

/// T76: a group's effective parameter values with kernel defaults already
/// resolved (lazy defaults to true in the kernel parser; the include-all
/// family and the switch family default to false). The group-settings
/// editor works on this shape; [diffAgainst] turns an edited copy back
/// into the minimal [ProxyGroupOverride] worth persisting.
@freezed
abstract class ProxyGroupParams with _$ProxyGroupParams {
  const factory ProxyGroupParams({
    @Default('') String url,
    int? interval,
    @Default(true) bool lazy,
    int? timeout,
    int? maxFailedTimes,
    @Default('') String filter,
    @Default('') String excludeFilter,
    @Default('') String excludeType,
    @Default('') String expectedStatus,
    @Default(false) bool hidden,
    @Default('') String icon,
    int? tolerance,
    @Default('') String defaultSelected,
    @Default('') String emptyFallback,
    @Default(false) bool disableUdp,
    @Default(false) bool includeAll,
    @Default(false) bool includeAllProxies,
    @Default(false) bool includeAllProviders,
    @Default('') String strategy,
    @Default('') String hashKey,
  }) = _ProxyGroupParams;

  /// Tolerant reader for one raw `proxy-groups` entry as returned by the
  /// core's getConfig. Unlike [ProxyGroup.fromJson] this never throws on
  /// group types the Dart enum does not know (e.g. relay): the editor only
  /// needs the parameter fields, and type gating comes from runtime data.
  factory ProxyGroupParams.fromRawMap(Map<String, Object?> json) {
    int? asInt(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    bool? asBool(Object? value) {
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
      return null;
    }

    String asText(String key) => json[key]?.toString() ?? '';

    return ProxyGroupParams(
      url: asText('url'),
      interval: asInt(json['interval']),
      lazy: asBool(json['lazy']) ?? true,
      timeout: asInt(json['timeout']),
      maxFailedTimes: asInt(json['max-failed-times']),
      filter: asText('filter'),
      excludeFilter: asText('exclude-filter'),
      excludeType: asText('exclude-type'),
      expectedStatus: asText('expected-status'),
      hidden: asBool(json['hidden']) ?? false,
      icon: asText('icon'),
      tolerance: asInt(json['tolerance']),
      defaultSelected: asText('default-selected'),
      emptyFallback: asText('empty-fallback'),
      disableUdp: asBool(json['disable-udp']) ?? false,
      includeAll: asBool(json['include-all']) ?? false,
      includeAllProxies: asBool(json['include-all-proxies']) ?? false,
      includeAllProviders: asBool(json['include-all-providers']) ?? false,
      strategy: asText('strategy'),
      hashKey: asText('hash-key'),
    );
  }

  factory ProxyGroupParams.fromGroup(ProxyGroup? group) {
    if (group == null) return const ProxyGroupParams();
    return ProxyGroupParams(
      url: group.url ?? '',
      interval: group.interval,
      lazy: group.lazy ?? true,
      timeout: group.timeout,
      maxFailedTimes: group.maxFailedTimes,
      filter: group.filter ?? '',
      excludeFilter: group.excludeFilter ?? '',
      excludeType: group.excludeType ?? '',
      expectedStatus: group.expectedStatus?.toString() ?? '',
      hidden: group.hidden ?? false,
      icon: group.icon ?? '',
      tolerance: group.tolerance,
      defaultSelected: group.defaultSelected ?? '',
      emptyFallback: group.emptyFallback ?? '',
      disableUdp: group.disableUdp ?? false,
      includeAll: group.includeAll ?? false,
      includeAllProxies: group.includeAllProxies ?? false,
      includeAllProviders: group.includeAllProviders ?? false,
      strategy: group.strategy ?? '',
      hashKey: group.hashKey ?? '',
    );
  }
}

extension ProxyGroupParamsExt on ProxyGroupParams {
  /// This subscription baseline with a stored override applied on top —
  /// the values the core will effectively run with.
  ProxyGroupParams applyOverride(ProxyGroupOverride? override) {
    if (override == null) return this;
    return ProxyGroupParams(
      url: override.url ?? url,
      interval: override.interval ?? interval,
      lazy: override.lazy ?? lazy,
      timeout: override.timeout ?? timeout,
      maxFailedTimes: override.maxFailedTimes ?? maxFailedTimes,
      filter: override.filter ?? filter,
      excludeFilter: override.excludeFilter ?? excludeFilter,
      excludeType: override.excludeType ?? excludeType,
      expectedStatus: override.expectedStatus ?? expectedStatus,
      hidden: override.hidden ?? hidden,
      icon: override.icon ?? icon,
      tolerance: override.tolerance ?? tolerance,
      defaultSelected: override.defaultSelected ?? defaultSelected,
      emptyFallback: override.emptyFallback ?? emptyFallback,
      disableUdp: override.disableUdp ?? disableUdp,
      includeAll: override.includeAll ?? includeAll,
      includeAllProxies: override.includeAllProxies ?? includeAllProxies,
      includeAllProviders:
          override.includeAllProviders ?? includeAllProviders,
      strategy: override.strategy ?? strategy,
      hashKey: override.hashKey ?? hashKey,
    );
  }

  /// The minimal override that turns [subscription] into this value set:
  /// fields equal to the subscription baseline are left out entirely, so
  /// untouched parameters keep following subscription updates.
  ProxyGroupOverride diffAgainst(ProxyGroupParams subscription) {
    return ProxyGroupOverride(
      url: url != subscription.url ? url : null,
      interval: interval != subscription.interval ? interval : null,
      lazy: lazy != subscription.lazy ? lazy : null,
      timeout: timeout != subscription.timeout ? timeout : null,
      maxFailedTimes: maxFailedTimes != subscription.maxFailedTimes
          ? maxFailedTimes
          : null,
      filter: filter != subscription.filter ? filter : null,
      excludeFilter: excludeFilter != subscription.excludeFilter
          ? excludeFilter
          : null,
      excludeType: excludeType != subscription.excludeType
          ? excludeType
          : null,
      expectedStatus: expectedStatus != subscription.expectedStatus
          ? expectedStatus
          : null,
      hidden: hidden != subscription.hidden ? hidden : null,
      icon: icon != subscription.icon ? icon : null,
      tolerance: tolerance != subscription.tolerance ? tolerance : null,
      defaultSelected: defaultSelected != subscription.defaultSelected
          ? defaultSelected
          : null,
      emptyFallback: emptyFallback != subscription.emptyFallback
          ? emptyFallback
          : null,
      disableUdp: disableUdp != subscription.disableUdp ? disableUdp : null,
      includeAll: includeAll != subscription.includeAll ? includeAll : null,
      includeAllProxies: includeAllProxies != subscription.includeAllProxies
          ? includeAllProxies
          : null,
      includeAllProviders:
          includeAllProviders != subscription.includeAllProviders
          ? includeAllProviders
          : null,
      strategy: strategy != subscription.strategy ? strategy : null,
      hashKey: hashKey != subscription.hashKey ? hashKey : null,
    );
  }
}

extension OverrideRuleExt on OverrideRule {
  List<Rule> get rules => switch (type == OverrideRuleType.override) {
    true => overrideRules,
    false => addedRules,
  };

  OverrideRule updateRules(List<Rule> Function(List<Rule> rules) builder) {
    if (type == OverrideRuleType.added) {
      return copyWith(addedRules: builder(addedRules));
    }
    return copyWith(overrideRules: builder(overrideRules));
  }
}

extension ProfilesExt on List<Profile> {
  Profile? getProfile(String? profileId) {
    final index = indexWhere((profile) => profile.id == profileId);
    return index == -1 ? null : this[index];
  }

  bool hasAddedOrChanged(List<Profile> previous) {
    return any((profile) {
      final old = previous.getProfile(profile.id);
      return old == null || old.backupView != profile.backupView;
    });
  }
}

extension ProfileExtension on Profile {
  ProfileType get type =>
      url.isEmpty == true ? ProfileType.file : ProfileType.url;

  bool get realAutoUpdate => url.isEmpty == true ? false : autoUpdate;

  Profile get backupView => copyWith(
    currentGroupName: null,
    subscriptionInfo: null,
    selectedMap: const {},
    unfoldSet: const {},
    isUpdating: false,
  );

  Future<void> checkAndUpdate() async {
    final isExists = await check();
    if (!isExists) {
      if (url.isNotEmpty) {
        await update();
      }
    }
  }

  Future<bool> check() async {
    final profilePath = await appPath.getProfilePath(id);
    return await File(profilePath).exists();
  }

  Future<File> getFile() async {
    final path = await appPath.getProfilePath(id);
    final file = File(path);
    final isExists = await file.exists();
    if (!isExists) {
      await file.create(recursive: true);
    }
    return file;
  }

  Future<void> _writeFile(String content, {SetupParams? setup}) async {
    final path = await appPath.getProfilePath(id);
    if (setup == null && await _hasContent(path, content)) return;
    final tempFile = File('$path.${DateTime.now().microsecondsSinceEpoch}.tmp');
    await tempFile.parent.create(recursive: true);
    try {
      await tempFile.writeAsString(content, flush: true);
      if (setup != null) {
        final message = await clashCore.validateConfig(
          '',
          setup: setup.copyWith(profilePath: tempFile.path),
        );
        if (message.isNotEmpty) {
          throw ProfileImportFailure(message);
        }
      }
      try {
        await tempFile.rename(path);
      } catch (_) {
        await tempFile.copy(path);
      }
    } finally {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  void _requireProfileContent(String content) {
    if (content.replaceFirst('\uFEFF', '').trim().isEmpty) {
      throw const FormatException(
        'Configuration is empty. The existing profile was kept.',
      );
    }
  }

  Future<bool> _hasContent(String path, String content) async {
    final file = File(path);
    if (!await file.exists()) return false;
    try {
      return await file.readAsString() == content;
    } catch (_) {
      return false;
    }
  }

  Future<int> get profileLastModified async {
    final file = await getFile();
    return (await file.stat()).modified.microsecondsSinceEpoch;
  }

  Future<Profile> update({bool validate = true}) async {
    final response = await request.getFileResponseForUrl(url);
    final disposition = response.headers['content-disposition']?.firstOrNull;
    final userinfo = response.headers['subscription-userinfo']?.firstOrNull;
    // T50: a subscription may suggest its own refresh interval via the
    // `profile-update-interval` header (in hours). Adopt it only on the
    // first successful fetch, so a provider can seed the default without
    // ever overriding an interval the user picked later.
    final suggestedHours = int.tryParse(
      response.headers['profile-update-interval']?.firstOrNull ?? '',
    );
    final adoptSuggested =
        lastUpdateDate == null && suggestedHours != null && suggestedHours > 0;
    return await copyWith(
      label: label ?? utils.getFileNameForDisposition(disposition) ?? id,
      subscriptionInfo: SubscriptionInfo.formHString(userinfo),
      autoUpdateDuration: adoptSuggested
          ? Duration(hours: suggestedHours)
          : autoUpdateDuration,
    ).saveFile(response.data, validate: validate);
  }

  Future<Profile> saveFile(Uint8List bytes, {bool validate = true}) async {
    String content = utf8.decode(bytes);
    _requireProfileContent(content);
    final key = ageSecretKey;
    if (key != null && key.isNotEmpty) {
      try {
        final decrypted = await clashCore.decryptAgeConfig(content, key);
        if (decrypted.isNotEmpty) {
          content = decrypted;
        }
      } catch (_) {}
    }
    content = ImportNormalize.toMihomo(content);
    content = utils.patchYamlConfig(content);
    _requireProfileContent(content);
    final setup = validate ? await globalState.buildValidateParams(this) : null;
    if (setup != null) {
      await _writeFile(content, setup: setup);
      return copyWith(lastUpdateDate: DateTime.now());
    }
    if (validate) {
      final message = await clashCore.validateConfig(
        content,
        ageSecretKey: ageSecretKey,
      );
      if (message.isNotEmpty) {
        final patched = utils.patchValidateConfig(content);
        if (patched != content) {
          final patchedMessage = await clashCore.validateConfig(
            patched,
            ageSecretKey: ageSecretKey,
          );
          if (patchedMessage.isEmpty) {
            content = patched;
          } else {
            throw ProfileImportFailure(message);
          }
        } else {
          throw ProfileImportFailure(message);
        }
      }
    }
    await _writeFile(content);
    return copyWith(lastUpdateDate: DateTime.now());
  }

  Future<Profile> saveFileWithString(String value) async {
    String content = value;
    _requireProfileContent(content);
    final key = ageSecretKey;
    if (key != null && key.isNotEmpty) {
      try {
        final decrypted = await clashCore.decryptAgeConfig(content, key);
        if (decrypted.isNotEmpty) {
          content = decrypted;
        }
      } catch (_) {}
    }
    content = ImportNormalize.toMihomo(content);
    content = utils.patchYamlConfig(content);
    _requireProfileContent(content);
    final setup = await globalState.buildValidateParams(this);
    if (setup != null) {
      await _writeFile(content, setup: setup);
      return copyWith(lastUpdateDate: DateTime.now());
    }
    final message = await clashCore.validateConfig(
      content,
      ageSecretKey: ageSecretKey,
    );
    if (message.isNotEmpty) {
      final patched = utils.patchValidateConfig(content);
      if (patched != content) {
        final patchedMessage = await clashCore.validateConfig(
          patched,
          ageSecretKey: ageSecretKey,
        );
        if (patchedMessage.isEmpty) {
          content = patched;
        } else {
          throw ProfileImportFailure(message);
        }
      } else {
        throw ProfileImportFailure(message);
      }
    }
    await _writeFile(content);
    return copyWith(lastUpdateDate: DateTime.now());
  }
}
