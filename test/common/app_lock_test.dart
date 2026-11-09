import 'dart:io';

import 'package:bett_box/common/app_lock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('app_lock_test');
    AppLockStore.storageDirOverride = tempDir;
  });

  tearDown(() async {
    AppLockStore.storageDirOverride = null;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('PIN is stored only as a salted hash and verifies', () async {
    final config = await AppLockStore.setPin('2468');
    expect(config.hasPin, isTrue);
    expect(config.pinHash, isNot(contains('2468')));
    expect(config.salt.length, 32);
    final ok = await AppLockStore.verify('2468');
    expect(ok.ok, isTrue);
    final bad = await AppLockStore.verify('0000');
    expect(bad.ok, isFalse);
  });

  test('backoff grows after five failures and persists', () async {
    await AppLockStore.setPin('1357');
    for (var i = 0; i < 5; i++) {
      await AppLockStore.verify('9999');
    }
    final config = await AppLockStore.load();
    expect(config.failedAttempts, 5);
    expect(config.lockedUntilMs, greaterThan(DateTime.now().millisecondsSinceEpoch));
    // Even the right PIN is refused during the backoff window.
    final during = await AppLockStore.verify('1357');
    expect(during.ok, isFalse);
    expect(appLockBackoff(5), const Duration(seconds: 30));
    expect(appLockBackoff(4), Duration.zero);
    expect(appLockBackoff(99), const Duration(seconds: 300));
  });

  test('config persists to the store file and survives a reload', () async {
    await AppLockStore.setPin('1357');
    final file = File('${tempDir.path}/app_lock_v1.json');
    expect(await file.exists(), isTrue);
    // The PIN hash is on disk synchronously after save (flush), not
    // merely queued in a platform preferences cache.
    expect(await file.readAsString(), contains('pinHash'));
    final loaded = await AppLockStore.load();
    expect(loaded.enabled, isTrue);
    expect(loaded.hasPin, isTrue);
  });

  group('appLockShouldLock', () {
    final t0 = DateTime(2026, 11, 7, 12, 0, 0);
    AppLockConfig config({bool enabled = true, int relockSeconds = 0}) =>
        AppLockConfig(
          enabled: enabled,
          salt: 's',
          pinHash: 'h',
          relockSeconds: relockSeconds,
        );

    test('cold start locks when enabled with a PIN', () {
      expect(
        appLockShouldLock(
          config: config(),
          coldStart: true,
          backgroundedAt: null,
          now: t0,
        ),
        isTrue,
      );
    });

    test('never locks when disabled or PIN-less', () {
      expect(
        appLockShouldLock(
          config: config(enabled: false),
          coldStart: true,
          backgroundedAt: null,
          now: t0,
        ),
        isFalse,
      );
      expect(
        appLockShouldLock(
          config: const AppLockConfig(enabled: true),
          coldStart: true,
          backgroundedAt: null,
          now: t0,
        ),
        isFalse,
      );
    });

    test('immediate relock locks on any return from background', () {
      expect(
        appLockShouldLock(
          config: config(relockSeconds: 0),
          coldStart: false,
          backgroundedAt: t0,
          now: t0.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });

    test('timed relock waits for the interval', () {
      expect(
        appLockShouldLock(
          config: config(relockSeconds: 30),
          coldStart: false,
          backgroundedAt: t0,
          now: t0.add(const Duration(seconds: 29)),
        ),
        isFalse,
      );
      expect(
        appLockShouldLock(
          config: config(relockSeconds: 30),
          coldStart: false,
          backgroundedAt: t0,
          now: t0.add(const Duration(seconds: 30)),
        ),
        isTrue,
      );
    });

    test('no background stint means no lock', () {
      expect(
        appLockShouldLock(
          config: config(relockSeconds: 0),
          coldStart: false,
          backgroundedAt: null,
          now: t0,
        ),
        isFalse,
      );
    });
  });

  group('T66 biometric availability and fallback', () {
    test('resolution distinguishes the three failure shapes', () {
      expect(
        resolveBiometricAvailability(
          deviceSupported: false,
          canCheckBiometrics: false,
          enrolledCount: 0,
        ),
        BiometricAvailability.unsupported,
      );
      expect(
        resolveBiometricAvailability(
          deviceSupported: true,
          canCheckBiometrics: true,
          enrolledCount: 0,
        ),
        BiometricAvailability.notEnrolled,
      );
      expect(
        resolveBiometricAvailability(
          deviceSupported: true,
          canCheckBiometrics: false,
          enrolledCount: 0,
        ),
        BiometricAvailability.noHardware,
      );
      expect(
        resolveBiometricAvailability(
          deviceSupported: true,
          canCheckBiometrics: true,
          enrolledCount: 1,
        ),
        BiometricAvailability.available,
      );
    });

    test('unlock is offered only when opted in AND available', () {
      const on = AppLockConfig(
        enabled: true,
        salt: 's',
        pinHash: 'h',
        biometricEnabled: true,
      );
      expect(
        biometricUnlockAllowed(
          config: on,
          availability: BiometricAvailability.available,
        ),
        isTrue,
      );
      // Any shortfall falls back to the PIN: not enrolled, no
      // hardware, unsupported platform, or the user never opted in.
      for (final availability in [
        BiometricAvailability.notEnrolled,
        BiometricAvailability.noHardware,
        BiometricAvailability.unsupported,
      ]) {
        expect(
          biometricUnlockAllowed(config: on, availability: availability),
          isFalse,
        );
      }
      expect(
        biometricUnlockAllowed(
          config: on.copyWith(biometricEnabled: false),
          availability: BiometricAvailability.available,
        ),
        isFalse,
      );
      expect(
        biometricUnlockAllowed(
          config: on.copyWith(enabled: false),
          availability: BiometricAvailability.available,
        ),
        isFalse,
      );
    });

    test('biometricEnabled round-trips through the store file', () async {
      await AppLockStore.setPin('1234');
      final before = await AppLockStore.load();
      await AppLockStore.save(before.copyWith(biometricEnabled: true));
      final after = await AppLockStore.load();
      expect(after.biometricEnabled, isTrue);
      expect(after.hasPin, isTrue);
    });
  });
}
