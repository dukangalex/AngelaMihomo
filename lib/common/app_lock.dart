import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App lock state (T39). The PIN is never stored: only a salted
/// SHA-256 hash in this standalone prefs store (not part of app
/// backups). Locking covers the UI only — the VPN/core service keeps
/// running exactly as before while the app is locked.
class AppLockConfig {
  final bool enabled;
  final String salt;
  final String pinHash;

  /// Background time after which the app locks again. 0 = lock as
  /// soon as the app leaves the foreground.
  final int relockSeconds;
  final bool biometricEnabled;

  /// Consecutive failed attempts and the current backoff deadline,
  /// persisted so closing the app cannot reset the penalty.
  final int failedAttempts;
  final int lockedUntilMs;

  const AppLockConfig({
    this.enabled = false,
    this.salt = '',
    this.pinHash = '',
    this.relockSeconds = 0,
    this.biometricEnabled = false,
    this.failedAttempts = 0,
    this.lockedUntilMs = 0,
  });

  bool get hasPin => salt.isNotEmpty && pinHash.isNotEmpty;

  AppLockConfig copyWith({
    bool? enabled,
    String? salt,
    String? pinHash,
    int? relockSeconds,
    bool? biometricEnabled,
    int? failedAttempts,
    int? lockedUntilMs,
  }) => AppLockConfig(
    enabled: enabled ?? this.enabled,
    salt: salt ?? this.salt,
    pinHash: pinHash ?? this.pinHash,
    relockSeconds: relockSeconds ?? this.relockSeconds,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedUntilMs: lockedUntilMs ?? this.lockedUntilMs,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'salt': salt,
    'pinHash': pinHash,
    'relockSeconds': relockSeconds,
    'biometricEnabled': biometricEnabled,
    'failedAttempts': failedAttempts,
    'lockedUntilMs': lockedUntilMs,
  };

  factory AppLockConfig.fromJson(Map<String, dynamic> json) => AppLockConfig(
    enabled: json['enabled'] == true,
    salt: json['salt']?.toString() ?? '',
    pinHash: json['pinHash']?.toString() ?? '',
    relockSeconds: (json['relockSeconds'] as num?)?.toInt() ?? 0,
    biometricEnabled: json['biometricEnabled'] == true,
    failedAttempts: (json['failedAttempts'] as num?)?.toInt() ?? 0,
    lockedUntilMs: (json['lockedUntilMs'] as num?)?.toInt() ?? 0,
  );
}

String hashAppLockPin(String salt, String pin) =>
    sha256.convert(utf8.encode('$salt:$pin')).toString();

String newAppLockSalt() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// Backoff after [failedAttempts] consecutive failures: free up to
/// 5, then 30s growing by 30s per further failure, capped at 5 min.
Duration appLockBackoff(int failedAttempts) {
  if (failedAttempts < 5) return Duration.zero;
  final seconds = 30 * (failedAttempts - 4);
  return Duration(seconds: seconds > 300 ? 300 : seconds);
}

/// Why biometrics cannot be offered on this device, if they cannot
/// (T66). The settings page shows the reason next to the disabled
/// option instead of a fake switch; the lock screen only attempts
/// biometrics when this is [available].
enum BiometricAvailability {
  available,

  /// The platform cannot run the system prompt at all (no plugin,
  /// desktop build without support).
  unsupported,

  /// Hardware exists but nothing is enrolled yet — the user can fix
  /// this in the system settings.
  notEnrolled,

  /// No biometric hardware on the device.
  noHardware,
}

/// The T66 availability/fallback decision, kept pure for unit tests:
/// biometrics are offered only when the user enabled them AND the
/// device can actually prompt. Every other combination falls back
/// to the PIN, which is always available.
BiometricAvailability resolveBiometricAvailability({
  required bool deviceSupported,
  required bool canCheckBiometrics,
  required int enrolledCount,
}) {
  if (!deviceSupported) return BiometricAvailability.unsupported;
  if (enrolledCount > 0) return BiometricAvailability.available;
  return canCheckBiometrics
      ? BiometricAvailability.notEnrolled
      : BiometricAvailability.noHardware;
}

/// Whether the lock screen may offer/attempt a biometric unlock:
/// the user opted in AND the live availability check passed.
bool biometricUnlockAllowed({
  required AppLockConfig config,
  required BiometricAvailability availability,
}) =>
    config.enabled &&
    config.hasPin &&
    config.biometricEnabled &&
    availability == BiometricAvailability.available;

/// The gate's lock decision, kept pure so every entry path is unit
/// tested: a cold start always locks when a PIN is set; a return
/// from the background locks once the configured interval has
/// elapsed (an interval of 0 therefore locks on any return).
bool appLockShouldLock({
  required AppLockConfig config,
  required bool coldStart,
  required DateTime? backgroundedAt,
  required DateTime now,
}) {
  if (!config.enabled || !config.hasPin) return false;
  if (coldStart) return true;
  final since = backgroundedAt;
  if (since == null) return false;
  return now.difference(since).inSeconds >= config.relockSeconds;
}

class AppLockStore {
  static const _legacyPrefsKey = 'app_lock.v1';
  static const _fileName = 'app_lock_v1.json';

  /// Bumped on every save so the mounted gate reloads its config
  /// immediately — settings changes take effect in the same process,
  /// without waiting for a restart or a lifecycle event.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  /// Test seam: when set, the config file lives in this directory
  /// instead of the application support directory.
  @visibleForTesting
  static Directory? storageDirOverride;

  static Future<File> _file() async {
    final dir =
        storageDirOverride ?? await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  static AppLockConfig? _tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? AppLockConfig.fromJson(decoded)
          : null;
    } catch (_) {
      return null;
    }
  }

  static Future<AppLockConfig> load() async {
    // Primary storage is a small JSON file written with flush: the
    // previous SharedPreferences copy could silently lose a just-set
    // PIN when the process was killed before the platform side got
    // around to persisting it (apply() is fire-and-forget), which
    // left the gate reading "no PIN set" on the next cold start.
    try {
      final file = await _file();
      if (await file.exists()) {
        final parsed = _tryParse(await file.readAsString());
        if (parsed != null) return parsed;
      }
    } catch (_) {
      // Fall through to the legacy copy.
    }
    final raw = (await SharedPreferences.getInstance()).getString(
      _legacyPrefsKey,
    );
    if (raw == null || raw.isEmpty) return const AppLockConfig();
    return _tryParse(raw) ?? const AppLockConfig();
  }

  static Future<void> save(AppLockConfig config) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(config.toJson()), flush: true);
    revision.value++;
  }

  static Future<AppLockConfig> setPin(String pin) async {
    final salt = newAppLockSalt();
    final config = (await load()).copyWith(
      salt: salt,
      pinHash: hashAppLockPin(salt, pin),
      enabled: true,
      failedAttempts: 0,
      lockedUntilMs: 0,
    );
    await save(config);
    return config;
  }

  static Future<void> disable() async {
    final config = (await load()).copyWith(
      enabled: false,
      failedAttempts: 0,
      lockedUntilMs: 0,
    );
    await save(config);
  }

  /// Verifies a PIN attempt, applying the failure backoff. Returns
  /// the outcome plus the (possibly updated) config.
  static Future<({bool ok, AppLockConfig config})> verify(String pin) async {
    var config = await load();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (config.lockedUntilMs > now) {
      return (ok: false, config: config);
    }
    final ok =
        config.hasPin && hashAppLockPin(config.salt, pin) == config.pinHash;
    if (ok) {
      config = config.copyWith(failedAttempts: 0, lockedUntilMs: 0);
    } else {
      final attempts = config.failedAttempts + 1;
      final backoff = appLockBackoff(attempts);
      config = config.copyWith(
        failedAttempts: attempts,
        lockedUntilMs: backoff == Duration.zero
            ? 0
            : now + backoff.inMilliseconds,
      );
    }
    await save(config);
    return (ok: ok, config: config);
  }
}
