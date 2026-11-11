import 'dart:convert';
import 'dart:io';

import 'package:bett_box/models/models.dart';
import 'package:yaml/yaml.dart';

import 'constant.dart';
import 'path.dart';
import 'preferences.dart';
import 'print.dart';

// T81 batch 3 (P-2) one-time inheritance migration.
//
// Before this batch, the dns / ntp / sniffer / experimental sections
// were gated: with the segment's override flag off, the subscription's
// section won and the App model section was ignored. The gates are
// gone — the App model is now the single authority for all four
// sections. To guarantee that no existing user's effective
// configuration changes silently at upgrade, the first launch after
// the upgrade seeds the App model from the current profile's
// subscription for every section the user never explicitly overrode,
// and only then does the takeover begin.
//
// Decision rule (per section, deliberately conservative):
// - Legacy gate ON  -> the App model was already authoritative; it is
//   kept exactly as-is ("already overridden -> App values unchanged").
// - Legacy gate OFF -> nothing in the App model ever took effect for
//   that section, so the subscription section (when the current
//   profile carries one) is parsed into the model and becomes the
//   seeded value ("never overridden -> inherit"). Any values sitting
//   in the model behind an off gate never took effect either, so
//   replacing them cannot change the effective configuration.
// - Legacy gate OFF and the subscription carries no such section ->
//   the model stays as-is (factory defaults for untouched users).
//
// The legacy gate values are read from the raw persisted config JSON:
// the Config model no longer declares those fields, so a parsed
// Config has already dropped them. The migration runs exactly once,
// watermarked by Config.specMigrationVersion.

const specMigrationCurrentVersion = 1;

class LegacySectionGates {
  final bool dns;
  final bool ntp;
  final bool sniffer;
  final bool experimental;

  const LegacySectionGates({
    this.dns = false,
    this.ntp = false,
    this.sniffer = false,
    this.experimental = false,
  });

  factory LegacySectionGates.fromRawConfig(Map<String, dynamic>? raw) {
    bool flag(String key) => raw?[key] == true;
    return LegacySectionGates(
      dns: flag('overrideDns'),
      ntp: flag('overrideNtp'),
      sniffer: flag('overrideSniffer'),
      experimental: flag('overrideExperimental'),
    );
  }
}

Map<String, Object?>? _asSection(Object? value) {
  if (value is Map) {
    return value.map((key, v) => MapEntry(key.toString(), v));
  }
  return null;
}

T? _tryParse<T>(
  T Function(Map<String, Object?> json) parse,
  Map<String, Object?> section,
  List<String> droppableKeys,
) {
  try {
    return parse(section);
  } catch (_) {
    if (droppableKeys.isEmpty) return null;
    final reduced = Map<String, Object?>.of(section)
      ..removeWhere((key, _) => droppableKeys.contains(key));
    try {
      return parse(reduced);
    } catch (_) {
      return null;
    }
  }
}

/// The App stores nameserver policies as comma-joined single strings
/// (see the splitByMultipleSeparators use in the patch-params
/// builder); subscriptions may write them as YAML lists. Join lists
/// before parsing so a well-formed subscription section cannot fail
/// the Dns parse on a representation difference alone.
Map<String, Object?> _normalizeDnsSection(Map<String, Object?> section) {
  final result = Map<String, Object?>.of(section);
  for (final key in const [
    'nameserver-policy',
    'proxy-server-nameserver-policy',
  ]) {
    final policy = result[key];
    if (policy is Map) {
      result[key] = policy.map((k, v) {
        final value = v is List ? v.join(',') : v?.toString() ?? '';
        return MapEntry(k.toString(), value);
      });
    }
  }
  return result;
}

/// Pure seeding decision: returns the ClashConfig to persist, with
/// each un-gated section replaced by the subscription's section when
/// one is present. Unparseable sections keep the model value (for an
/// untouched user that equals the factory default, so the effective
/// configuration is unchanged either way).
ClashConfig seedSectionsFromSubscription({
  required ClashConfig model,
  required LegacySectionGates gates,
  required Map<String, dynamic>? subscription,
}) {
  if (subscription == null) return model;
  var result = model;

  if (!gates.dns) {
    final section = _asSection(subscription['dns']);
    if (section != null) {
      final parsed = _tryParse(
        Dns.fromJson,
        _normalizeDnsSection(section),
        const [
          'enhanced-mode',
          'cache-algorithm',
          'fake-ip-filter-mode',
          'fallback-filter',
        ],
      );
      if (parsed != null) result = result.copyWith(dns: parsed);
    }
  }
  if (!gates.ntp) {
    final section = _asSection(subscription['ntp']);
    if (section != null) {
      final parsed = _tryParse(Ntp.fromJson, section, const []);
      if (parsed != null) result = result.copyWith(ntp: parsed);
    }
  }
  if (!gates.sniffer) {
    final section = _asSection(subscription['sniffer']);
    if (section != null) {
      final parsed = _tryParse(Sniffer.fromJson, section, const ['sniff']);
      if (parsed != null) result = result.copyWith(sniffer: parsed);
    }
  }
  if (!gates.experimental) {
    final section = _asSection(subscription['experimental']);
    if (section != null) {
      final parsed = _tryParse(Experimental.fromJson, section, const []);
      if (parsed != null) result = result.copyWith(experimental: parsed);
    }
  }
  return result;
}

Object? _yamlToPlain(Object? value) {
  if (value is YamlMap) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): _yamlToPlain(entry.value),
    };
  }
  if (value is YamlList) {
    return [for (final item in value) _yamlToPlain(item)];
  }
  return value;
}

Future<Map<String, dynamic>?> _readRawPersistedConfig() async {
  try {
    final configFile = File(await appPath.appConfigPath);
    if (await configFile.exists()) {
      final content = await configFile.readAsString();
      if (content.isNotEmpty) {
        final decoded = json.decode(content);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      }
    }
  } catch (_) {}
  try {
    final prefs = await preferences.sharedPreferencesCompleter.future;
    final configString = prefs?.getString(configKey);
    if (configString != null && configString.isNotEmpty) {
      final decoded = json.decode(configString);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    }
  } catch (_) {}
  return null;
}

Future<Map<String, dynamic>?> _readProfileSubscription(
  Profile profile,
) async {
  // Age-encrypted profiles cannot be read here; their sections simply
  // get no inheritance (the model defaults apply, as documented).
  if (profile.ageSecretKey != null) return null;
  try {
    final file = File(await appPath.getProfilePath(profile.id));
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    if (content.trim().isEmpty) return null;
    final plain = _yamlToPlain(loadYaml(content));
    if (plain is Map<String, dynamic>) return plain;
    if (plain is Map) return plain.cast<String, dynamic>();
    return null;
  } catch (_) {
    return null;
  }
}

/// Runs the one-time migration for [config] and returns the config to
/// persist (watermark advanced, sections possibly seeded). Returns
/// [config] unchanged when the migration already ran. Never throws:
/// any failure leaves the watermark untouched by the caller only when
/// the evaluation itself could not run — in practice every failure
/// mode here (missing files, unparseable YAML) is a legitimate
/// "nothing to inherit" outcome, so the watermark still advances.
Future<Config> runSectionTakeoverMigration(Config config) async {
  if (config.specMigrationVersion >= specMigrationCurrentVersion) {
    return config;
  }
  try {
    final gates = LegacySectionGates.fromRawConfig(
      await _readRawPersistedConfig(),
    );
    Map<String, dynamic>? subscription;
    final profile = config.currentProfileId == null
        ? null
        : config.profiles.getProfile(config.currentProfileId);
    if (profile != null) {
      subscription = await _readProfileSubscription(profile);
    }
    final seeded = seedSectionsFromSubscription(
      model: config.patchClashConfig,
      gates: gates,
      subscription: subscription,
    );
    commonPrint.log(
      '[spec-migration] section takeover seeded '
      '(dns: ${!gates.dns && subscription?['dns'] != null}, '
      'ntp: ${!gates.ntp && subscription?['ntp'] != null}, '
      'sniffer: ${!gates.sniffer && subscription?['sniffer'] != null}, '
      'experimental: '
      '${!gates.experimental && subscription?['experimental'] != null})',
    );
    return config.copyWith(
      patchClashConfig: seeded,
      specMigrationVersion: specMigrationCurrentVersion,
    );
  } catch (e) {
    commonPrint.error('[spec-migration] failed, keeping model as-is: $e');
    return config.copyWith(
      specMigrationVersion: specMigrationCurrentVersion,
    );
  }
}
