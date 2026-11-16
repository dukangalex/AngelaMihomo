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

  group('applyChainPolicy traffic attribute match (T85)', () {
    Map<String, dynamic> profile() => {
      'proxies': [
        {'name': 'Entry', 'type': 'ss'},
        {'name': 'NodeA', 'type': 'ss'},
        {'name': 'DirectA', 'type': 'direct'},
        {'name': 'DirectB', 'type': 'direct'},
      ],
      'proxy-groups': [
        {
          'name': 'DirectGroup',
          'type': 'select',
          'proxies': ['DirectA', 'DirectB'],
        },
        {
          'name': 'Main',
          'type': 'select',
          'proxies': ['NodeA'],
        },
        {
          'name': 'AdBlock',
          'type': 'select',
          'proxies': ['REJECT', 'REJECT-DROP', 'PASS'],
        },
        {
          'name': 'Mixed',
          'type': 'select',
          'proxies': ['DirectA', 'NodeA'],
        },
      ],
    };

    List<dynamic> membersOf(Map<String, dynamic> raw, String name) {
      final groups = raw['proxy-groups'] as List;
      final group = groups.firstWhere((g) => g['name'] == name);
      return group['proxies'] as List;
    }

    test('direct-only and action-only selectors receive no chain', () {
      final raw = profile();
      applyChainPolicy(raw, entry: 'Entry', landing: 'ProviderLanding');
      // DirectGroup sits first but is not proxy-carrying: it stays
      // untouched and does not count as the main selector, so Main
      // takes the prepend treatment instead.
      expect(membersOf(raw, 'DirectGroup'), ['DirectA', 'DirectB']);
      expect(membersOf(raw, 'Main').first, explicitChainGroup);
      expect(membersOf(raw, 'AdBlock'), ['REJECT', 'REJECT-DROP', 'PASS']);
      // A mixed group carries a proxy choice, so it receives the
      // chain as a trailing option; its direct member stays.
      expect(membersOf(raw, 'Mixed'), ['DirectA', 'NodeA', explicitChainGroup]);
    });
  });
}
