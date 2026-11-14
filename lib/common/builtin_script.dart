import 'package:bett_box/common/string.dart';
import 'package:bett_box/models/models.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The bundled HiClash script (T95): seeded from the app asset into the
/// script library on first launch and refreshed across app updates only
/// while the user has not edited it. It is never bound to a profile on
/// its own — it takes effect only where the user picks it per profile.
abstract final class BuiltinScript {
  static const id = 'builtin-hiclash';
  static const label = 'HiClash 内置脚本';
  static const assetPath = 'assets/data/hiclash.js';

  /// Digest of the bundled content as last seeded/refreshed by the app.
  /// When the stored script's digest still equals this value the copy is
  /// factory-fresh and may be auto-refreshed; any other digest means the
  /// user edited it and their copy wins.
  static const factoryDigestPrefKey = 'builtin_hiclash_factory_digest_v1';
}

enum BuiltinSeedAction {
  /// No script with the bundled id yet: create it from the asset.
  create,

  /// The stored copy is untouched since seeding and the bundle moved on:
  /// replace it with the new bundled content.
  refresh,

  /// User-edited copy, or already current: leave it alone.
  keep,
}

BuiltinSeedAction resolveBuiltinSeedAction({
  required String? existingDigest,
  required String? factoryDigest,
  required String bundledDigest,
}) {
  if (existingDigest == null) return BuiltinSeedAction.create;
  if (existingDigest == bundledDigest) return BuiltinSeedAction.keep;
  if (factoryDigest != null && existingDigest == factoryDigest) {
    return BuiltinSeedAction.refresh;
  }
  return BuiltinSeedAction.keep;
}

bool builtinUpdateAvailable({
  required String? existingDigest,
  required String? factoryDigest,
  required String bundledDigest,
}) {
  return existingDigest != null &&
      factoryDigest != null &&
      existingDigest != bundledDigest &&
      existingDigest != factoryDigest;
}

/// Seeds (or refreshes) the bundled script in the script library.
/// Best-effort glue around [resolveBuiltinSeedAction]; failures are the
/// caller's to log. This only maintains the library copy — it never
/// binds the script to any profile and never touches a binding the
/// user already made.
Future<void> seedBuiltinScript({
  required List<Script> scripts,
  required void Function(Script script) saveScript,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final content = await rootBundle.loadString(BuiltinScript.assetPath);
  final bundledDigest = content.toMd5();
  final existing = scripts.where((s) => s.id == BuiltinScript.id).firstOrNull;
  final factoryDigest = prefs.getString(BuiltinScript.factoryDigestPrefKey);
  switch (resolveBuiltinSeedAction(
    existingDigest: existing?.digest,
    factoryDigest: factoryDigest,
    bundledDigest: bundledDigest,
  )) {
    case BuiltinSeedAction.create:
      final seeded = await Script(
        id: BuiltinScript.id,
        label: BuiltinScript.label,
      ).writeContent(content);
      saveScript(seeded);
      await prefs.setString(BuiltinScript.factoryDigestPrefKey, bundledDigest);
    case BuiltinSeedAction.refresh:
      final refreshed = await existing!.writeContent(content);
      saveScript(refreshed.copyWith(label: existing.label));
      await prefs.setString(BuiltinScript.factoryDigestPrefKey, bundledDigest);
    case BuiltinSeedAction.keep:
      // First launch after the digest bookkeeping was introduced: if the
      // stored copy already matches the bundle, adopt it as factory state.
      if (factoryDigest == null && existing?.digest == bundledDigest) {
        await prefs.setString(
          BuiltinScript.factoryDigestPrefKey,
          bundledDigest,
        );
      }
  }
}

/// Restores the bundled script to the shipped version, discarding user
/// edits (the scripts page's "restore bundled version" action).
Future<void> restoreBuiltinScript({
  required List<Script> scripts,
  required void Function(Script script) saveScript,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final content = await rootBundle.loadString(BuiltinScript.assetPath);
  final existing = scripts.where((s) => s.id == BuiltinScript.id).firstOrNull;
  final base =
      existing ??
      Script(id: BuiltinScript.id, label: BuiltinScript.label);
  final restored = await base.writeContent(content);
  saveScript(
    restored.copyWith(label: existing?.label ?? BuiltinScript.label),
  );
  await prefs.setString(
    BuiltinScript.factoryDigestPrefKey,
    content.toMd5(),
  );
}

/// Whether the scripts page should hint that a newer bundled version is
/// available for a user-edited copy.
Future<bool> hasBuiltinScriptUpdate(List<Script> scripts) async {
  final existing = scripts.where((s) => s.id == BuiltinScript.id).firstOrNull;
  if (existing == null) return false;
  final prefs = await SharedPreferences.getInstance();
  final content = await rootBundle.loadString(BuiltinScript.assetPath);
  return builtinUpdateAvailable(
    existingDigest: existing.digest,
    factoryDigest: prefs.getString(BuiltinScript.factoryDigestPrefKey),
    bundledDigest: content.toMd5(),
  );
}
