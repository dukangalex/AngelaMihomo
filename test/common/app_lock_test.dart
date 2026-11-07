import 'package:bett_box/common/app_lock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
}
