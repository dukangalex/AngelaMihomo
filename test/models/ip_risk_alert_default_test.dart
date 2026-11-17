import 'package:angelamihomo/models/config.dart';
import 'package:flutter_test/flutter_test.dart';

// T165 (chain.26): the IP risk alert sends the current exit IP to a
// third-party scoring service, so it must default to off. Existing
// installs are migrated off once in Preferences.getConfig; a stored
// value still wins here so users may turn it back on afterwards.
void main() {
  group('ipRiskAlert default', () {
    test('defaults to off when absent from stored json', () {
      final props = AppSettingProps.fromJson(const <String, Object?>{});
      expect(props.ipRiskAlert, isFalse);
    });

    test('safeFromJson(null) defaults to off', () {
      final props = AppSettingProps.safeFromJson(null);
      expect(props.ipRiskAlert, isFalse);
    });

    test('stored true is respected (migration is one-time, elsewhere)', () {
      final props = AppSettingProps.fromJson(const <String, Object?>{
        'ipRiskAlert': true,
      });
      expect(props.ipRiskAlert, isTrue);
    });
  });
}
