// ignore_for_file: invalid_annotation_target
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bett_box/clash/core.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/common/import_normalize.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/state.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'clash_config.dart';
import 'core.dart';

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
  bool get hasUsage => upload + download + total > 0;

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
    @Default({}) Map<String, SubscriptionInfo> providerSubscriptions,
    @Default(true) bool autoUpdate,
    @Default({}) SelectedMap selectedMap,
    @Default({}) Set<String> unfoldSet,
    @Default(OverrideData()) OverrideData overrideData,
    @JsonKey(includeToJson: false, includeFromJson: false)
    @Default(false)
    bool isUpdating,
    @Default(false) bool useScriptOverride,
    String? scriptId,
    @Default(false) bool managed,
    @Default(false) bool managedStyleApplied,
    String? ageSecretKey,
    @JsonKey(name: 'group-switches')
    @Default({})
    Map<String, bool> groupSwitches,
    @Default(ProfileUsageStyle.bar) ProfileUsageStyle usageStyle,
    ProfileBundle? bundle,
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
      // T95: every fresh profile starts on the bundled HiClash script;
      // the binding is a plain per-profile choice the user can change
      // or drop in the profile's script settings.
      useScriptOverride: true,
      scriptId: BuiltinScript.id,
    );
  }
}

@freezed
abstract class BundleMember with _$BundleMember {
  const factory BundleMember({required String id, String? prefix}) =
      _BundleMember;

  factory BundleMember.fromJson(Map<String, Object?> json) =>
      _$BundleMemberFromJson(json);
}

@freezed
abstract class BundleReport with _$BundleReport {
  const factory BundleReport({
    @Default(0) int proxies,
    @Default(0) int duplicates,
    @Default(0) int groups,
  }) = _BundleReport;

  factory BundleReport.fromJson(Map<String, Object?> json) =>
      _$BundleReportFromJson(json);
}

@freezed
abstract class ProfileBundle with _$ProfileBundle {
  const factory ProfileBundle({
    @Default([]) List<BundleMember> members,
    @Default(BundleReport()) BundleReport report,
    @Default({}) Map<String, String> failures,
    @Default(false) bool collapsed,
  }) = _ProfileBundle;

  factory ProfileBundle.fromJson(Map<String, Object?> json) =>
      _$ProfileBundleFromJson(json);
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
  const factory OverrideRule({@Default([]) List<Rule> addedRules}) =
      _OverrideRule;

  factory OverrideRule.fromJson(Map<String, Object?> json) =>
      _$OverrideRuleFromJson(json);
}

extension OverrideRuleExt on OverrideRule {
  List<Rule> get rules => addedRules;

  OverrideRule updateRules(List<Rule> Function(List<Rule> rules) builder) {
    return copyWith(addedRules: builder(addedRules));
  }
}

extension ProfilesExt on List<Profile> {
  Profile? getProfile(String? profileId) {
    final index = indexWhere((profile) => profile.id == profileId);
    return index == -1 ? null : this[index];
  }

  Set<String> get collapsedMemberIds => {
    for (final profile in this)
      if (profile.bundle case final bundle? when bundle.collapsed)
        for (final member in bundle.members) member.id,
  };

  List<Profile> bundlesOf(String memberId) => [
    for (final profile in this)
      if (profile.bundle?.members.any((member) => member.id == memberId) ??
          false)
        profile,
  ];

  bool hasAddedOrChanged(List<Profile> previous) {
    return any((profile) {
      final old = previous.getProfile(profile.id);
      return old == null || old.backupView != profile.backupView;
    });
  }
}

extension SubscriptionUsagesExtension
    on List<MapEntry<String, SubscriptionInfo>> {
  List<MapEntry<String, SubscriptionInfo>> topByUsage(int count) {
    int used(SubscriptionInfo info) => info.upload + info.download;
    final sorted = [...this]
      ..sort((a, b) {
        final compare = used(b.value).compareTo(used(a.value));
        return compare != 0 ? compare : a.key.compareTo(b.key);
      });
    return sorted.take(count).toList()..sort((a, b) => a.key.compareTo(b.key));
  }
}

extension ProfileExtension on Profile {
  ProfileType get type => bundle != null
      ? ProfileType.bundle
      : url.isEmpty
      ? ProfileType.file
      : ProfileType.url;

  bool get realAutoUpdate => url.isEmpty == true ? false : autoUpdate;

  bool get isManaged => bundle != null || managed;

  bool get runsManagedScript => bundle == null && managed;

  List<MapEntry<String, SubscriptionInfo>> get subscriptionUsages {
    final info = subscriptionInfo;
    if (info != null && info.hasUsage) return [MapEntry(label ?? id, info)];
    final seen = <SubscriptionInfo>{};
    return [
      for (final entry in providerSubscriptions.entries)
        if (entry.value.hasUsage && seen.add(entry.value)) entry,
    ];
  }

  Profile get backupView => copyWith(
    currentGroupName: null,
    subscriptionInfo: null,
    providerSubscriptions: const {},
    selectedMap: const {},
    unfoldSet: const {},
    isUpdating: false,
    usageStyle: ProfileUsageStyle.bar,
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

  Future<int> get profileLastModified async {
    final file = await getFile();
    return (await file.stat()).modified.microsecondsSinceEpoch;
  }

  String _stagingPath(String profilePath, String suffix) =>
      '$profilePath.${DateTime.now().microsecondsSinceEpoch}.$suffix';

  Future<void> _deleteStaging(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  // Fork capability preserved on the core-import path: sing-box /
  // Xray / share-link sources are converted to Mihomo YAML before the
  // core importer sees them, and empty content never reaches the
  // import (an empty download must not replace a working profile).
  Future<void> _normalizeImportSource(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      return; // Not text: let the core importer judge it.
    }
    final normalized = ImportNormalize.toMihomo(content);
    if (normalized.replaceFirst('\uFEFF', '').trim().isEmpty) {
      throw const FormatException(
        'Configuration is empty. The existing profile was kept.',
      );
    }
    if (normalized != content) {
      await file.writeAsString(normalized, flush: true);
    }
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
          throw message;
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

  Future<void> _import(
    String source, {
    required bool validate,
    List<String>? encodings,
  }) async {
    await _normalizeImportSource(source);
    // The finish is Dart-side (the fork's shipped pipeline): age
    // decryption, YAML patching, core validation, atomic write. The
    // Go-side importer is not used: it bypasses this pipeline and has
    // no test seam. Downloads arrive already decompressed from
    // fetchProfileSource, so [encodings] needs no handling here.
    var content = utf8.decode(await File(source).readAsBytes());
    final key = ageSecretKey;
    if (key != null && key.isNotEmpty) {
      try {
        final decrypted = await clashCore.decryptAgeConfig(content, key);
        if (decrypted.isNotEmpty) {
          content = decrypted;
        }
      } catch (_) {}
    }
    content = utils.patchYamlConfig(content);
    _requireProfileContent(content);
    final setup = validate ? await globalState.buildValidateParams(this) : null;
    if (setup != null) {
      await _writeFile(content, setup: setup);
      return;
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
            throw message;
          }
        } else {
          throw message;
        }
      }
    }
    await _writeFile(content);
  }

  Future<Profile> _importContent(
    Future<void> Function(File file) write, {
    required bool validate,
  }) async {
    final staging = File(_stagingPath(await appPath.getProfilePath(id), 'src'));
    try {
      await staging.parent.create(recursive: true);
      await write(staging);
      await _import(staging.path, validate: validate);
    } finally {
      await _deleteStaging(staging.path);
    }
    return copyWith(lastUpdateDate: DateTime.now());
  }

  Future<Profile> update({bool validate = true}) async {
    final downloadPath = _stagingPath(
      await appPath.getProfilePath(id),
      'download',
    );
    try {
      await File(downloadPath).parent.create(recursive: true);
      final source = await request.fetchProfileSource(url, downloadPath);
      final headers = source.headers;
      final disposition = headers?['content-disposition']?.firstOrNull;
      final userinfo = headers?['subscription-userinfo']?.firstOrNull;
      final profile = copyWith(
        label: label ?? utils.getFileNameForDisposition(disposition) ?? id,
        subscriptionInfo: SubscriptionInfo.formHString(userinfo),
      );
      final encodings = headers?['content-encoding'] ?? const <String>[];
      await profile._import(
        source.path,
        validate: validate,
        encodings: source.remote ? encodings : null,
      );
      return profile.copyWith(lastUpdateDate: DateTime.now());
    } finally {
      await _deleteStaging(downloadPath);
    }
  }

  Future<Profile> saveFile(Uint8List bytes, {bool validate = true}) {
    return _importContent(
      (file) => file.writeAsBytes(bytes),
      validate: validate,
    );
  }

  Future<Profile> saveFileWithString(String value) {
    return _importContent((file) => file.writeAsString(value), validate: true);
  }
}
