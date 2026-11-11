import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

// T75 实施批：新增内核能力字段的解析与回写（持久化）回归。
// 字段名逐个对 vendored 内核 1.19.33 的 RawConfig/RawDNS/RawNTP 定义。
void main() {
  test('ClashConfig 新字段解析与回写', () {
    final config = ClashConfig.fromJson(const {
      'keep-alive-idle': 42,
      'geo-auto-update': true,
      'geo-update-interval': 12,
      'bind-address': '127.0.0.1',
      'lan-allowed-ips': ['192.168.1.0/24'],
      'lan-disallowed-ips': ['192.168.1.99'],
      'store-fake-ip': true,
      'interface-name': 'eth0',
    });
    expect(config.keepAliveIdle, 42);
    expect(config.geoAutoUpdate, isTrue);
    expect(config.geoUpdateInterval, 12);
    expect(config.bindAddress, '127.0.0.1');
    expect(config.lanAllowedIps, ['192.168.1.0/24']);
    expect(config.lanDisallowedIps, ['192.168.1.99']);
    expect(config.storeFakeIp, isTrue);
    expect(config.interfaceName, 'eth0');

    final out = config.toJson();
    expect(out['keep-alive-idle'], 42);
    expect(out['geo-auto-update'], isTrue);
    expect(out['geo-update-interval'], 12);
    expect(out['bind-address'], '127.0.0.1');
    expect(out['lan-allowed-ips'], ['192.168.1.0/24']);
    expect(out['lan-disallowed-ips'], ['192.168.1.99']);
    expect(out['store-fake-ip'], isTrue);
    expect(out['interface-name'], 'eth0');
  });

  test('ClashConfig 新字段默认值与内核默认一致', () {
    const config = ClashConfig();
    expect(config.keepAliveIdle, defaultKeepAliveIdle);
    expect(config.geoAutoUpdate, isFalse);
    expect(config.geoUpdateInterval, defaultGeoUpdateInterval);
    expect(config.bindAddress, defaultBindAddress);
    expect(config.lanAllowedIps, isEmpty);
    expect(config.lanDisallowedIps, isEmpty);
    expect(config.storeFakeIp, isFalse);
    expect(config.interfaceName, isNull);
  });

  test('Dns proxy-server-nameserver-policy 解析与回写', () {
    final dns = Dns.fromJson(const {
      'proxy-server-nameserver-policy': {'geosite:cn': '223.5.5.5'},
    });
    expect(dns.proxyServerNameserverPolicy, {'geosite:cn': '223.5.5.5'});
    expect(dns.toJson()['proxy-server-nameserver-policy'], {
      'geosite:cn': '223.5.5.5',
    });
    expect(const Dns().proxyServerNameserverPolicy, isEmpty);
  });

  test('Ntp dialer-proxy 解析与回写', () {
    final ntp = Ntp.fromJson(const {'dialer-proxy': 'PROXY'});
    expect(ntp.dialerProxy, 'PROXY');
    expect(ntp.toJson()['dialer-proxy'], 'PROXY');
    expect(const Ntp().dialerProxy, isNull);
  });

  test('RuleAction 含 DOMAIN-WILDCARD 且值与内核一致', () {
    expect(RuleAction.DOMAIN_WILDCARD.value, 'DOMAIN-WILDCARD');
    expect(
      RuleAction.values.map((item) => item.value),
      contains('DOMAIN-WILDCARD'),
    );
  });
}
