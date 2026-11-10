import 'dart:convert';

import 'package:bett_box/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

// T76: proxy-group parameter overrides. The model must carry every
// GroupCommonOption / SelectorOption / LoadBalanceOption field the kernel
// parses, the editor's diff must stay minimal (untouched fields keep
// following the subscription), and a profile must round-trip its stored
// overrides with kernel field names intact.
void main() {
  test('ProxyGroup 解析并回写组参数全集', () {
    final group = ProxyGroup.fromJson(const {
      'name': 'Main',
      'type': 'load-balance',
      'proxies': ['A', 'B'],
      'url': 'https://example.com/check',
      'interval': 120,
      'lazy': false,
      'timeout': 3000,
      'max-failed-times': 3,
      'filter': 'HK',
      'exclude-filter': '过期',
      'exclude-type': 'Shadowsocks|Vmess',
      'expected-status': '200-299',
      'hidden': true,
      'icon': 'https://example.com/icon.png',
      'tolerance': 80,
      'default-selected': 'B',
      'empty-fallback': 'DIRECT',
      'disable-udp': true,
      'include-all': false,
      'include-all-proxies': true,
      'include-all-providers': true,
      'strategy': 'round-robin',
    });
    expect(group.defaultSelected, 'B');
    expect(group.emptyFallback, 'DIRECT');
    expect(group.disableUdp, isTrue);
    expect(group.includeAll, isFalse);
    expect(group.includeAllProxies, isTrue);
    expect(group.includeAllProviders, isTrue);
    expect(group.strategy, 'round-robin');
    final out = group.toJson();
    expect(out['default-selected'], 'B');
    expect(out['empty-fallback'], 'DIRECT');
    expect(out['disable-udp'], isTrue);
    expect(out['include-all-proxies'], isTrue);
    expect(out['include-all-providers'], isTrue);
    expect(out['strategy'], 'round-robin');
  });

  test('fromRawMap 容错读未知 type 的组参数（relay 不炸）', () {
    final params = ProxyGroupParams.fromRawMap(const {
      'name': 'Chain',
      'type': 'relay',
      'interval': 60.0,
      'lazy': 'false',
      'disable-udp': true,
      'expected-status': 200,
    });
    expect(params.interval, 60);
    expect(params.lazy, isFalse);
    expect(params.disableUdp, isTrue);
    expect(params.expectedStatus, '200');
    // Kernel defaults resolved: lazy absent would be true, switches false.
    final empty = ProxyGroupParams.fromRawMap(const {'name': 'X'});
    expect(empty.lazy, isTrue);
    expect(empty.disableUdp, isFalse);
    expect(empty.includeAll, isFalse);
  });

  test('diff 只留改过的字段，apply 后与编辑值一致（保存往返）', () {
    final subscription = ProxyGroupParams.fromRawMap(const {
      'name': 'Main',
      'type': 'select',
      'url': 'https://example.com/check',
      'interval': 300,
      'lazy': true,
    });
    final edited = subscription.copyWith(
      interval: 60,
      disableUdp: true,
      defaultSelected: 'B',
    );
    final override = edited.diffAgainst(subscription);
    expect(override.isEmpty, isFalse);
    expect(override.toPatchMap(), {
      'interval': 60,
      'disable-udp': true,
      'default-selected': 'B',
    });
    // The Go pipeline merges exactly this patch map into the raw group;
    // re-reading the merged values through applyOverride must reproduce
    // the editor's value set.
    final effective = subscription.applyOverride(override);
    expect(effective, edited);
    // No edits -> no override at all, so the group keeps following the
    // subscription wholesale.
    expect(subscription.diffAgainst(subscription).isEmpty, isTrue);
    // Editing a field back to the subscription value drops the override.
    final reverted = edited.copyWith(interval: 300);
    expect(reverted.diffAgainst(subscription).toPatchMap(), {
      'disable-udp': true,
      'default-selected': 'B',
    });
  });

  test('Profile JSON 往返保留 group-overrides（内核字段名）', () {
    final profile = Profile(
      id: 'p1',
      autoUpdateDuration: const Duration(hours: 1),
      groupOverrides: const {
        'Main': ProxyGroupOverride(
          interval: 60,
          disableUdp: true,
          excludeFilter: '过期',
          strategy: 'sticky-sessions',
        ),
      },
    );
    // The persistence path encodes the whole config (json.encode expands
    // nested objects through their toJson), so round-trip through text.
    final json = jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>;
    final overrides = json['group-overrides'] as Map<String, dynamic>;
    final main = overrides['Main'] as Map<String, dynamic>;
    expect(main['interval'], 60);
    expect(main['disable-udp'], isTrue);
    expect(main['exclude-filter'], '过期');
    expect(main['strategy'], 'sticky-sessions');
    expect(main.containsKey('lazy'), isFalse);
    final restored = Profile.fromJson(json);
    expect(restored.groupOverrides['Main'], profile.groupOverrides['Main']);
  });

  test('ProxyGroupParams.fromGroup 与 fromRawMap 结果一致', () {
    const raw = {
      'name': 'Auto',
      'type': 'url-test',
      'url': 'https://example.com/check',
      'interval': 90,
      'lazy': false,
      'tolerance': 50,
      'empty-fallback': 'A',
    };
    final fromGroup = ProxyGroupParams.fromGroup(ProxyGroup.fromJson(raw));
    final fromRaw = ProxyGroupParams.fromRawMap(raw);
    expect(fromGroup, fromRaw);
  });
}
