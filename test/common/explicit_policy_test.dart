import 'package:bett_box/common/explicit_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applyChainPolicy region groups (T40)', () {
    Map<String, dynamic> profile() => {
      'proxies': [
        {'name': 'Entry', 'type': 'ss'},
        {'name': 'Other', 'type': 'ss'},
      ],
      'proxy-groups': [
        {
          'name': 'Manual',
          'type': 'select',
          'proxies': ['Entry', 'Other'],
        },
        {
          'name': 'Singapore',
          'type': 'select',
          'proxies': ['Singapore-自动选择', 'Other'],
        },
        {
          'name': 'Singapore-自动选择',
          'type': 'url-test',
          'proxies': ['Other'],
        },
        {
          'name': 'Others',
          'type': 'select',
          'proxies': ['Entry', 'Other'],
        },
      ],
    };

    List<dynamic> membersOf(Map<String, dynamic> raw, String name) {
      final groups = raw['proxy-groups'] as List;
      final group = groups.firstWhere((g) => g['name'] == name);
      return group['proxies'] as List;
    }

    test('provider landing: chain relay skips region groups', () {
      final raw = profile();
      // Entry/Landing are not both inline proxies here: force the relay
      // path by naming a landing that is not an inline proxy.
      final applied = applyChainPolicy(
        raw,
        entry: 'Entry',
        landing: 'ProviderLanding',
      );
      expect(applied, isTrue);
      expect(membersOf(raw, 'Manual').first, explicitChainGroup);
      expect(membersOf(raw, 'Singapore'), ['Singapore-自动选择', 'Other']);
      expect(membersOf(raw, 'Others').last, explicitChainGroup);
    });

    test('a select group merely named like a region is not skipped', () {
      final raw = profile();
      // Remove the url-test pairing: now "Singapore" is a plain group.
      (raw['proxy-groups'] as List).removeWhere(
        (g) => g['name'] == 'Singapore-自动选择',
      );
      applyChainPolicy(raw, entry: 'Entry', landing: 'ProviderLanding');
      expect(membersOf(raw, 'Singapore').last, explicitChainGroup);
    });
  });
}
