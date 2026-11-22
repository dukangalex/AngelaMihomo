import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:angelamihomo/clash/clash.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import 'constant.dart';
import 'backup_recovery.dart';
import 'path.dart';
import 'print.dart';
import 'utils.dart';

class Preferences {
  static Preferences? _instance;
  Completer<SharedPreferences?> sharedPreferencesCompleter = Completer();

  Future<bool> get isInit async =>
      await sharedPreferencesCompleter.future != null;

  Preferences._internal() {
    if (appPath.isPortable) {
      SharedPreferencesStorePlatform.instance = _FilePreferencesStore(
        appPath.sharedPreferencesPath,
      );
    }
    SharedPreferences.getInstance()
        .then((value) => sharedPreferencesCompleter.complete(value))
        .onError((_, _) => sharedPreferencesCompleter.complete(null));
  }

  factory Preferences() {
    _instance ??= Preferences._internal();
    return _instance!;
  }

  Future<ClashConfig?> getClashConfig() async {
    final preferences = await sharedPreferencesCompleter.future;
    final clashConfigString = preferences?.getString(clashConfigKey);
    if (clashConfigString == null) return null;
    try {
      final clashConfigMap = json.decode(clashConfigString);
      return ClashConfig.fromJson(clashConfigMap);
    } catch (e, stackTrace) {
      commonPrint.error(
        'Failed to parse clash config from preferences: $e\n$stackTrace',
      );
      return null;
    }
  }

  Config? _pendingConfig;
  Config? _lastConfig;
  String? _lastSaved;
  Future<bool>? _saving;

  Future<String?> _readText(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return content.isEmpty ? null : content;
    } catch (_) {
      return null;
    }
  }

  Future<Config?> _parseConfig(String? content, String source) async {
    if (content == null) return null;
    try {
      final decoded = json.decode(content);
      if (decoded is! Map<String, dynamic>) return null;
      await _unprotectConfigSecrets(decoded);
      return Config.compatibleFromJson(decoded);
    } catch (e, stackTrace) {
      commonPrint.error('Failed to parse config from $source: $e\n$stackTrace');
      return null;
    }
  }

  /// T249: the config file at rest must not be the weakest copy of
  /// the user's credentials. The backup export has always encrypted
  /// the WebDAV credentials (and the whole archive can be password
  /// protected), while config.json itself held the same secrets —
  /// plus every subscription URL — in plaintext. The sensitive
  /// fields below are now stored encrypted with the per-install key
  /// (utils.encryptSecret, AES-256-GCM, ENC2~ form), the same
  /// machinery the backup export uses:
  ///
  /// - `dav.user` / `dav.password` (mirrors the export's set)
  /// - `appSetting.backupPassword`
  /// - `profiles[].url` (subscription URLs carry access tokens)
  ///
  /// Reading is liberal: only ENC~/ENC2~ values are transformed, so
  /// config files written by older builds (all plaintext) load
  /// unchanged and are rewritten protected on the next save. A value
  /// that cannot be decrypted on this install (foreign key) is
  /// dropped to empty with a warning rather than crashing the load;
  /// a failure to encrypt on save falls back to plaintext for that
  /// field with a warning — protecting the secret never costs the
  /// user their whole configuration.
  Future<void> _protectConfigSecrets(Map<String, dynamic> json) async {
    Future<String> protect(Object? value) async {
      if (value is! String || value.isEmpty) return value is String ? value : '';
      try {
        return await utils.encryptSecret(value);
      } catch (e) {
        commonPrint.warn('Failed to encrypt a config secret: $e');
        return value;
      }
    }

    final dav = json['dav'];
    if (dav is Map<String, dynamic>) {
      if (dav['user'] is String) dav['user'] = await protect(dav['user']);
      if (dav['password'] is String) {
        dav['password'] = await protect(dav['password']);
      }
    }
    final appSetting = json['appSetting'];
    if (appSetting is Map<String, dynamic> &&
        appSetting['backupPassword'] is String) {
      appSetting['backupPassword'] = await protect(
        appSetting['backupPassword'],
      );
    }
    final profiles = json['profiles'];
    if (profiles is List) {
      for (final profile in profiles) {
        if (profile is Map<String, dynamic> && profile['url'] is String) {
          profile['url'] = await protect(profile['url']);
        }
      }
    }
  }

  Future<void> _unprotectConfigSecrets(Map<String, dynamic> json) async {
    Future<String> unprotect(Object? value, String field) async {
      if (value is! String || value.isEmpty) {
        return value is String ? value : '';
      }
      final clear = await utils.decryptSecret(value);
      if (clear == null) {
        commonPrint.warn(
          'A stored $field could not be decrypted on this install; '
          'treating it as unset.',
        );
        return '';
      }
      return clear;
    }

    final dav = json['dav'];
    if (dav is Map<String, dynamic>) {
      if (dav['user'] is String) {
        dav['user'] = await unprotect(dav['user'], 'WebDAV user');
      }
      if (dav['password'] is String) {
        dav['password'] = await unprotect(dav['password'], 'WebDAV password');
      }
    }
    final appSetting = json['appSetting'];
    if (appSetting is Map<String, dynamic> &&
        appSetting['backupPassword'] is String) {
      appSetting['backupPassword'] = await unprotect(
        appSetting['backupPassword'],
        'backup password',
      );
    }
    final profiles = json['profiles'];
    if (profiles is List) {
      for (final profile in profiles) {
        if (profile is Map<String, dynamic> && profile['url'] is String) {
          profile['url'] = await unprotect(profile['url'], 'subscription URL');
        }
      }
    }
  }

  Future<void> _writeAtomic(String path, String content) async {
    final temp = File('$path.${DateTime.now().microsecondsSinceEpoch}.tmp');
    await temp.parent.create(recursive: true);
    await temp.writeAsString(content, flush: true);
    try {
      await temp.rename(path);
    } catch (_) {
      await temp.copy(path);
      await temp.delete();
    }
  }

  Future<void> _syncFlag(
    SharedPreferences? preferences,
    String key,
    bool value,
  ) async {
    if (preferences == null || preferences.getBool(key) == value) return;
    await preferences.setBool(key, value);
  }

  Future<Config?> getConfig() async {
    final preferences = await sharedPreferencesCompleter.future;
    final path = await appPath.appConfigPath;

    // AngelaMihomo: recover an interrupted backup restore before any
    // source is parsed, including an empty/missing file's
    // shared-preferences fallback. Do not catch recovery errors as parse
    // errors.
    await recoverInterruptedBackup(await appPath.homeDirPath, (value) async {
      if (preferences == null) {
        throw StateError('Preferences unavailable during backup recovery');
      }
      final saved = value == null
          ? await preferences.remove(configKey)
          : await preferences.setString(configKey, value);
      if (!saved) {
        throw StateError('Failed to restore config preference mirror');
      }
    });

    final content = await _readText(path);
    final fileConfig = await _parseConfig(content, 'file');
    var selected = fileConfig;
    _lastConfig = null;
    _lastSaved = fileConfig != null ? content : null;
    if (fileConfig != null && content != null) {
      try {
        await _writeAtomic('$path.bak', content);
      } catch (e) {
        commonPrint.warn('Failed to back up config: $e');
      }
    } else {
      selected = await _parseConfig(await _readText('$path.bak'), 'backup');
    }

    if (selected == null || selected.profiles.isEmpty) {
      final legacy = await _parseConfig(
        preferences?.getString(configKey),
        'preferences',
      );
      if (legacy != null && (selected == null || legacy.profiles.isNotEmpty)) {
        selected = legacy;
      }
    }

    // AngelaMihomo (chain.26, T165): the IP risk alert used to default to
    // on, and while on it sends the current exit IP to a third-party
    // scoring service. Turn it off once for existing installs; the flag
    // keeps this one-time, so users may turn it back on afterwards.
    if (preferences?.getBool(ipRiskAlertOffMigratedKey) != true) {
      if (selected != null && selected.appSetting.ipRiskAlert) {
        selected = selected.copyWith(
          appSetting: selected.appSetting.copyWith(ipRiskAlert: false),
        );
      }
      await preferences?.setBool(ipRiskAlertOffMigratedKey, true);
    }

    if (selected != null && !identical(selected, fileConfig)) {
      await saveConfig(selected);
    } else if (preferences?.containsKey(configKey) == true) {
      await preferences?.remove(configKey);
    }
    if (selected != null) {
      await _syncFlag(
        preferences,
        'autoLaunch',
        selected.appSetting.autoLaunch,
      );
      if (Platform.isMacOS) {
        await _syncFlag(
          preferences,
          'keepDockIcon',
          selected.appSetting.keepDockIcon,
        );
      }
    }

    return selected;
  }

  Future<bool> saveConfig(Config config) {
    _pendingConfig = config;
    return _saving ??= _drainConfig();
  }

  Future<bool> _drainConfig() async {
    var saved = true;
    try {
      for (
        var config = _pendingConfig;
        config != null;
        config = _pendingConfig
      ) {
        _pendingConfig = null;
        saved = await _writeConfig(config);
      }
    } finally {
      _saving = null;
    }
    return saved;
  }

  Future<bool> _writeConfig(Config config) async {
    if (identical(config, _lastConfig)) return true;
    final preferences = await sharedPreferencesCompleter.future;
    await _syncFlag(preferences, 'autoLaunch', config.appSetting.autoLaunch);
    if (Platform.isMacOS) {
      await _syncFlag(
        preferences,
        'keepDockIcon',
        config.appSetting.keepDockIcon,
      );
    }

    // T249: encrypt the sensitive fields before the JSON ever
    // reaches disk (see _protectConfigSecrets). The deep map comes
    // from an encode/decode round trip — the models' toJson is
    // shallow (nested values stay model objects until the encoder
    // walks them), the same conversion backupData uses. Key work
    // cannot run in an isolate, so it happens here; the final
    // encode still runs in one.
    final configMap =
        json.decode(json.encode(config)) as Map<String, dynamic>;
    await _protectConfigSecrets(configMap);
    final jsonStr = await Isolate.run(() => json.encode(configMap));
    final path = await appPath.appConfigPath;
    if (jsonStr == _lastSaved && await File(path).exists()) {
      _lastConfig = config;
      return true;
    }

    try {
      await _writeAtomic(path, jsonStr);
      _lastSaved = jsonStr;
      _lastConfig = config;
    } catch (e, stackTrace) {
      commonPrint.error('Failed to save config to file: $e\n$stackTrace');
      return false;
    }

    if (preferences?.containsKey(configKey) == true) {
      try {
        await preferences?.remove(configKey);
      } catch (e) {
        commonPrint.warn('Failed to remove legacy config mirror: $e');
      }
    }
    return true;
  }

  Future<void> clearClashConfig() async {
    final preferences = await sharedPreferencesCompleter.future;
    preferences?.remove(clashConfigKey);
  }

  Future<void> clearPreferences() async {
    final sharedPreferencesIns = await sharedPreferencesCompleter.future;
    await sharedPreferencesIns?.clear();
    final path = await appPath.appConfigPath;
    for (final file in [File(path), File('$path.bak')]) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    _lastSaved = null;
    _lastConfig = null;
    await clashCore.storeClear(StoreSpace.ip);
  }
}

final preferences = Preferences();

class _FilePreferencesStore extends SharedPreferencesStorePlatform {
  _FilePreferencesStore(this._path);

  static const _defaultPrefix = 'flutter.';

  final Future<String> _path;
  Map<String, Object>? _cache;

  Future<Map<String, Object>> _read() async {
    final cached = _cache;
    if (cached != null) return cached;
    final file = File(await _path);
    var data = <String, Object>{};
    if (file.existsSync()) {
      final content = file.readAsStringSync();
      if (content.isNotEmpty) {
        final decoded = json.decode(content);
        if (decoded is Map) {
          data = decoded.cast<String, Object>();
        }
      }
    }
    return _cache ??= data;
  }

  Future<bool> _write(Map<String, Object> data) async {
    try {
      final file = File(await _path);
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      file.writeAsStringSync(json.encode(data), flush: true);
      return true;
    } catch (e) {
      commonPrint.warn('Failed to write preferences: $e');
      return false;
    }
  }

  bool _matches(String key, PreferencesFilter filter) =>
      key.startsWith(filter.prefix) &&
      (filter.allowList?.contains(key) ?? true);

  @override
  Future<bool> remove(String key) async {
    final data = await _read();
    data.remove(key);
    return _write(data);
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final data = await _read();
    data[key] = value;
    return _write(data);
  }

  @override
  Future<bool> clear() => clearWithParameters(
    ClearParameters(filter: PreferencesFilter(prefix: _defaultPrefix)),
  );

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) async {
    final data = await _read();
    data.removeWhere((key, _) => _matches(key, parameters.filter));
    return _write(data);
  }

  @override
  Future<Map<String, Object>> getAll() => getAllWithParameters(
    GetAllParameters(filter: PreferencesFilter(prefix: _defaultPrefix)),
  );

  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async {
    final data = Map<String, Object>.from(await _read());
    data.removeWhere((key, _) => !_matches(key, parameters.filter));
    return data;
  }
}
