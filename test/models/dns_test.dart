import 'dart:convert';

import 'package:angelamihomo/models/clash_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('默认 DNS 只引用内核原生 geosite，不引用任何 rule-set（T162）', () {
    const dns = Dns();

    expect(
      dns.fakeIpFilter.any((item) => item.startsWith('rule-set:')),
      isFalse,
    );
    expect(
      dns.nameserverPolicy.keys.any((key) => key.startsWith('rule-set:')),
      isFalse,
    );
    expect(dns.fakeIpFilter, [
      '*',
      'geosite:private',
      'geosite:category-ntp',
      'geosite:geolocation-cn',
      'geosite:connectivity-check',
    ]);
    expect(dns.nameserverPolicy, {
      'geosite:cn': 'system',
      'geosite:private': 'system',
      '*': 'system',
    });
  });

  test('出厂默认 DNS 全部跟随系统，不写死任何公共解析（T232）', () {
    const dns = Dns();

    expect(dns.defaultNameserver, ['system']);
    expect(dns.nameserver, ['system']);
    expect(dns.proxyServerNameserver, ['system']);
    final allEntries = [
      ...dns.defaultNameserver,
      ...dns.nameserver,
      ...dns.proxyServerNameserver,
      ...dns.directNameserver,
      ...dns.fallback,
      ...dns.nameserverPolicy.values,
    ];
    for (final entry in allEntries) {
      expect(entry, isNot(contains('114.114')));
      expect(entry, isNot(contains('1.1.1.1')));
      expect(entry, isNot(contains('119.29')));
      expect(entry, isNot(contains('223.')));
      expect(entry, isNot(contains('doh.pub')));
      expect(entry, isNot(contains('dns-query')));
    }
  });

  test('存量 _bettbox 规则集条目迁移回 geosite 等价项，其余条目保持不变（T162）', () {
    final dns = Dns.safeDnsFromJson({
      'fake-ip-filter': [
        '*',
        'rule-set:private_bettbox',
        'rule-set:fakeip-filter_bettbox',
        'rule-set:category-ntp_bettbox',
        'rule-set:cn_bettbox',
        'rule-set:connectivity-check_bettbox',
        'geosite:apple',
        'rule-set:myown',
      ],
      'nameserver-policy': {
        '+.corp.com': '10.0.0.1',
        'rule-set:cn_bettbox': '119.29.29.29',
        'rule-set:private_bettbox': 'system',
        'geosite:google': '8.8.8.8',
      },
      'nameserver': ['1.1.1.1'],
    });

    expect(dns.fakeIpFilter, [
      '*',
      'geosite:private',
      'geosite:category-ntp',
      'geosite:geolocation-cn',
      'geosite:connectivity-check',
      'geosite:apple',
      'rule-set:myown',
    ]);
    expect(dns.nameserverPolicy, {
      '+.corp.com': '10.0.0.1',
      'geosite:cn': '119.29.29.29',
      'geosite:private': 'system',
      'geosite:google': '8.8.8.8',
    });
    expect(dns.nameserver, ['1.1.1.1']);
  });

  test('从 JSON 文本迁移时保留其他 DNS 字段（T162）', () {
    final dns = Dns.safeDnsFromJson(
      jsonDecode(
            jsonEncode({
              'listen': '0.0.0.0:1053',
              'nameserver-policy': {'rule-set:cn_bettbox': '223.5.5.5'},
            }),
          )
          as Map<String, Object?>,
    );

    expect(dns.listen, '0.0.0.0:1053');
    expect(dns.nameserverPolicy, {'geosite:cn': '223.5.5.5'});
  });

  test('fallback-filter 的 domain 字段可往返序列化（T129 恢复）', () {
    final dns = Dns.fromJson({
      'fallback-filter': {
        'geoip': true,
        'geoip-code': 'CN',
        'ipcidr': ['240.0.0.0/4'],
        'domain': ['+.google.com', '+.facebook.com'],
      },
    });

    expect(dns.fallbackFilter.domain, ['+.google.com', '+.facebook.com']);
    final json = jsonDecode(jsonEncode(dns.toJson())) as Map<String, dynamic>;
    expect(
      (json['fallback-filter'] as Map<String, dynamic>)['domain'],
      ['+.google.com', '+.facebook.com'],
    );
  });

  test('没有存量条目时原样解析', () {
    final dns = Dns.safeDnsFromJson({
      'fake-ip-filter': ['+.lan'],
      'nameserver-policy': {'geosite:google': '8.8.8.8'},
    });

    expect(dns.fakeIpFilter, ['+.lan']);
    expect(dns.nameserverPolicy, {'geosite:google': '8.8.8.8'});
  });

  test('fake-ip-range6 出厂默认显式写 2001:2::1/48（T326）', () {
    // 以前默认是空字符串，只有 effectiveFakeIpRangeV6 在 IPv6 开启
    // 时才回落到这个值；现在默认值本身就是它，行为不变、只是显式。
    expect(const Dns().fakeIpRangeV6, '2001:2::1/48');
    expect(Dns.fromJson(const {}).fakeIpRangeV6, '2001:2::1/48');
    // 序列化往返后仍是显式值，不再写回空字符串。
    final json = Dns().toJson();
    expect(json['fake-ip-range6'], '2001:2::1/48');
  });

  test('存量空 fake-ip-range6 仍按旧语义走 effective 回落（T326）', () {
    // 已存设置里的 '' 不被改写，继续由 effectiveFakeIpRangeV6 解释：
    // IPv6 开时回落 2001:2::1/48，关时为空（内核侧 parseIPV6 也会清零）。
    final stored = Dns.fromJson(const {'fake-ip-range6': ''});
    expect(stored.fakeIpRangeV6, '');
    expect(stored.effectiveFakeIpRangeV6(ipv6Enabled: true), '2001:2::1/48');
    expect(stored.effectiveFakeIpRangeV6(ipv6Enabled: false), '');
    // 显式默认值在 getter 第一分支命中，与开关无关。
    expect(
      const Dns().effectiveFakeIpRangeV6(ipv6Enabled: true),
      '2001:2::1/48',
    );
    expect(
      const Dns().effectiveFakeIpRangeV6(ipv6Enabled: false),
      '2001:2::1/48',
    );
  });
}
