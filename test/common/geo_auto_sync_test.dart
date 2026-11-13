import 'package:bett_box/common/geo_auto_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isGeoAutoSyncDue', () {
    final now = DateTime(2026, 11, 13, 12);

    test('never due while disabled', () {
      expect(
        isGeoAutoSyncDue(
          enabled: false,
          period: GeoAutoSyncPeriod.daily,
          lastSync: null,
          now: now,
        ),
        isFalse,
      );
    });

    test('due immediately when enabled and never synced', () {
      expect(
        isGeoAutoSyncDue(
          enabled: true,
          period: GeoAutoSyncPeriod.weekly,
          lastSync: null,
          now: now,
        ),
        isTrue,
      );
    });

    test('not due before the period elapses', () {
      expect(
        isGeoAutoSyncDue(
          enabled: true,
          period: GeoAutoSyncPeriod.daily,
          lastSync: now.subtract(const Duration(hours: 23)),
          now: now,
        ),
        isFalse,
      );
      expect(
        isGeoAutoSyncDue(
          enabled: true,
          period: GeoAutoSyncPeriod.monthly,
          lastSync: now.subtract(const Duration(days: 29)),
          now: now,
        ),
        isFalse,
      );
    });

    test('due once the period has elapsed', () {
      expect(
        isGeoAutoSyncDue(
          enabled: true,
          period: GeoAutoSyncPeriod.daily,
          lastSync: now.subtract(const Duration(days: 1)),
          now: now,
        ),
        isTrue,
      );
      expect(
        isGeoAutoSyncDue(
          enabled: true,
          period: GeoAutoSyncPeriod.weekly,
          lastSync: now.subtract(const Duration(days: 8)),
          now: now,
        ),
        isTrue,
      );
      expect(
        isGeoAutoSyncDue(
          enabled: true,
          period: GeoAutoSyncPeriod.monthly,
          lastSync: now.subtract(const Duration(days: 31)),
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('GeoAutoSyncStore', () {
    test('defaults: disabled, weekly, never synced', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = await GeoAutoSyncStore.load();
      expect(settings.enabled, isFalse);
      expect(settings.period, GeoAutoSyncPeriod.weekly);
      expect(settings.lastSync, isNull);
    });

    test('round-trips enabled, period and last sync', () async {
      SharedPreferences.setMockInitialValues({});
      await GeoAutoSyncStore.saveEnabled(true);
      await GeoAutoSyncStore.savePeriod(GeoAutoSyncPeriod.monthly);
      final stamp = DateTime(2026, 11, 1, 8, 30);
      await GeoAutoSyncStore.saveLastSync(stamp);
      final settings = await GeoAutoSyncStore.load();
      expect(settings.enabled, isTrue);
      expect(settings.period, GeoAutoSyncPeriod.monthly);
      expect(settings.lastSync, stamp);
    });

    test('unknown stored period falls back to weekly', () async {
      SharedPreferences.setMockInitialValues({
        'geo_auto_sync_period': 'bogus',
      });
      final settings = await GeoAutoSyncStore.load();
      expect(settings.period, GeoAutoSyncPeriod.weekly);
    });
  });

  test('auto sync targets cover the downloadable GEO resources', () {
    expect(
      geoAutoSyncTargets.map((target) => target.key),
      containsAll(<String>['geosite', 'mmdb', 'asn', 'city']),
    );
  });
}
