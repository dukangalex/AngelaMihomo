import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
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

class AppLockStore {
  static const _key = 'app_lock.v1';

  static Future<AppLockConfig> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null || raw.isEmpty) return const AppLockConfig();
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? AppLockConfig.fromJson(decoded)
          : const AppLockConfig();
    } catch (_) {
      return const AppLockConfig();
    }
  }

  static Future<void> save(AppLockConfig config) async {
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode(config.toJson()),
    );
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
