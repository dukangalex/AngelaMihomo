import 'package:shared_preferences/shared_preferences.dart';

import 'constant.dart';
import 'print.dart';

/// Cadence choices for the GEO auto sync (T107).
enum GeoAutoSyncPeriod {
  daily(Duration(days: 1)),
  weekly(Duration(days: 7)),
  monthly(Duration(days: 30));

  final Duration duration;

  const GeoAutoSyncPeriod(this.duration);
}

/// One downloadable GEO resource the auto sync maintains: the same
/// set the Resources page offers through its per-item sync and its
/// "sync all" action (everything `updateGeoData` can fetch). MRS is
/// not part of the set: it ships inside the app bundle and has no
/// per-item download path.
class GeoAutoSyncTarget {
  final String key;
  final String label;
  final String fileName;

  const GeoAutoSyncTarget({
    required this.key,
    required this.label,
    required this.fileName,
  });
}

const geoAutoSyncTargets = <GeoAutoSyncTarget>[
  GeoAutoSyncTarget(key: 'geosite', label: 'GeoSite', fileName: geoSiteFileName),
  GeoAutoSyncTarget(key: 'mmdb', label: 'MMDB', fileName: mmdbFileName),
  GeoAutoSyncTarget(key: 'asn', label: 'ASN', fileName: asnFileName),
  GeoAutoSyncTarget(key: 'city', label: 'CITY', fileName: cityFileName),
];

/// Pure due-check for the GEO auto sync, kept separate from storage
/// so the scheduling rule is unit-testable.
bool isGeoAutoSyncDue({
  required bool enabled,
  required GeoAutoSyncPeriod period,
  required DateTime? lastSync,
  required DateTime now,
}) {
  if (!enabled) return false;
  if (lastSync == null) return true;
  return !now.isBefore(lastSync.add(period.duration));
}

/// Dedicated SharedPreferences storage for the GEO auto sync
/// settings (T107). Kept out of AppSettingProps on purpose: these
/// three values are a self-contained feature store, and adding a
/// field to the freezed config model would force a regeneration
/// for no functional gain.
///
/// The switch defaults to OFF: automatic network activity is opt-in
/// under the app's privacy baseline.
abstract final class GeoAutoSyncStore {
  static const _enabledKey = 'geo_auto_sync_enabled';
  static const _periodKey = 'geo_auto_sync_period';
  static const _lastSyncKey = 'geo_auto_sync_last_sync_ms';

  static Future<({bool enabled, GeoAutoSyncPeriod period, DateTime? lastSync})>
  load() async {
    final prefs = await SharedPreferences.getInstance();
    final periodName = prefs.getString(_periodKey);
    final period = GeoAutoSyncPeriod.values
        .where((value) => value.name == periodName)
        .firstOrNull;
    final lastSyncMs = prefs.getInt(_lastSyncKey);
    return (
      enabled: prefs.getBool(_enabledKey) ?? false,
      period: period ?? GeoAutoSyncPeriod.weekly,
      lastSync: lastSyncMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastSyncMs),
    );
  }

  static Future<void> saveEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    commonPrint.log('GEO auto sync ${enabled ? 'enabled' : 'disabled'}');
  }

  static Future<void> savePeriod(GeoAutoSyncPeriod period) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_periodKey, period.name);
  }

  static Future<void> saveLastSync(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
  }
}
