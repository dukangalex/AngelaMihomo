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
      'geosite:cn': '119.29.29.29',
      'geosite:private': 'system',
      '*': 'system',
    });
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
}
