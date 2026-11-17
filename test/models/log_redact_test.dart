import 'package:angelamihomo/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('redactSensitiveText', () {
    test('订阅 URL 的查询令牌与路径被打码，主机保留', () {
      final out = redactSensitiveText(
        'Failed to fetch https://sub.example.com/api/v1/client/subscribe?token=abcdef123456',
      );
      expect(out, contains('https://sub.example.com/***'));
      expect(out, isNot(contains('abcdef123456')));
      expect(out, isNot(contains('subscribe')));
    });

    test('令牌在路径段里的订阅 URL 同样打码', () {
      final out = redactSensitiveText(
        'GET https://cdn.example.com/link/9f8e7d6c5b4a failed',
      );
      expect(out, contains('https://cdn.example.com/***'));
      expect(out, isNot(contains('9f8e7d6c5b4a')));
    });

    test('URL 里的 userinfo 被剔除', () {
      final out = redactSensitiveText(
        'WebDAV https://user:p4ssw0rd@dav.example.com:8080/remote.php/dav unreachable',
      );
      expect(out, contains('https://dav.example.com:8080/***'));
      expect(out, isNot(contains('p4ssw0rd')));
      expect(out, isNot(contains('user:')));
    });

    test('安装链接中编码与未编码的订阅地址都打码', () {
      final encoded = redactSensitiveText(
        'onAppLink: clash://install-config?url=https%3A%2F%2Fsub.example.com%2Fs%3Ftoken%3Ddeadbeef99&name=Test',
      );
      expect(encoded, isNot(contains('deadbeef99')));
      expect(encoded, contains('url=***'));

      final plain = redactSensitiveText(
        'clash://install-config?url=https://sub.example.com/s?token=deadbeef99',
      );
      expect(plain, contains('url=https://sub.example.com/***'));
      expect(plain, isNot(contains('deadbeef99')));
    });

    test('代理分享链接整体打码（载荷即凭据）', () {
      final vmess = redactSensitiveText(
        'imported vmess://eyJ2IjoiMiIsInBzIjoiTm9kZSJ9 done',
      );
      expect(vmess, contains('vmess://***'));
      expect(vmess, isNot(contains('eyJ2IjoiMiIsInBzIjoiTm9kZSJ9')));

      final vless = redactSensitiveText(
        'vless://b831381d-6324-4d53-ad4f-8cda48b30811@node.example.com:443?security=reality#Node',
      );
      expect(vless, 'vless://***');
      expect(vless, isNot(contains('b831381d')));
      expect(vless, isNot(contains('node.example.com')));
    });

    test('独立 UUID 与 YAML/JSON 片段中的凭据字段打码', () {
      final standalone = redactSensitiveText(
        'proxy id b831381d-6324-4d53-ad4f-8cda48b30811 rejected',
      );
      expect(standalone, isNot(contains('b831381d')));
      expect(standalone, contains('rejected'));

      final yaml = redactSensitiveText(
        '{name: HK-01, server: hk.example.com, port: 443, uuid: b831381d-6324-4d53-ad4f-8cda48b30811, password: p@ssw0rd}',
      );
      expect(yaml, isNot(contains('p@ssw0rd')));
      expect(yaml, isNot(contains('b831381d')));
      expect(yaml, contains('hk.example.com'));
      expect(yaml, contains('port: 443'));

      final json = redactSensitiveText(
        '{"password": "hunter2", "token": "tok12345"}',
      );
      expect(json, isNot(contains('hunter2')));
      expect(json, isNot(contains('tok12345')));
    });

    test('Authorization 凭据打码', () {
      final bearer = redactSensitiveText(
        'header Authorization: Bearer abcdef0123456789 sent',
      );
      expect(bearer, contains('Bearer ***'));
      expect(bearer, isNot(contains('abcdef0123456789')));

      final basic = redactSensitiveText('Proxy-Authorization: Basic dXNlcjpwYXNz');
      expect(basic, contains('Basic ***'));
      expect(basic, isNot(contains('dXNlcjpwYXNz')));
    });

    test('Dio 风格错误里的订阅 URL 打码', () {
      final out = redactSensitiveText(
        'DioException [connection error]: uri: https://sub.example.com/get?token=zzz999 failed',
      );
      expect(out, isNot(contains('zzz999')));
      expect(out, contains('https://sub.example.com/***'));
    });

    test('诊断必需信息保持原样', () {
      const dial =
          '[TCP] dial DIRECT mihomo --> 223.5.5.5:853 error: dial tcp 223.5.5.5:853: tun lifecycle is transitioning';
      expect(redactSensitiveText(dial), dial);
      expect(
        redactSensitiveText('Start initial provider bilibili'),
        'Start initial provider bilibili',
      );
      expect(redactSensitiveText(''), '');
    });

    test('DoH 查询 URL 保留端点主机、去掉查询载荷', () {
      final out = redactSensitiveText(
        '[DNS] https://doh.pub:443/dns-query?dns=AAABAAABAAAAAAAAA3d3 failed',
      );
      expect(out, contains('https://doh.pub:443/***'));
      expect(out, isNot(contains('AAABAAAB')));
    });

    test('幂等：二次脱敏结果不变', () {
      const raw =
          'fetch https://sub.example.com/s?token=tok999 via vmess://eyJ2IjoiMiJ9 uuid b831381d-6324-4d53-ad4f-8cda48b30811';
      final once = redactSensitiveText(raw);
      expect(redactSensitiveText(once), once);
    });
  });

  group('Log 工厂统一脱敏', () {
    test('Log.app 打码订阅令牌', () {
      final log = Log.app(
        'update failed: https://sub.example.com/s?token=t0ken123',
      );
      expect(log.payload, isNot(contains('t0ken123')));
      expect(log.payload, contains('https://sub.example.com/***'));
    });

    test('Log.core 打码且保留模块拆分', () {
      final log = Log.core({
        'LogLevel': 'error',
        'Payload':
            '[Profile] fetch https://sub.example.com/x?token=t0ken123 failed',
        'time': 1760000000123,
      });
      expect(log.module, 'Profile');
      expect(log.payload, isNot(contains('t0ken123')));
      expect(log.payload, contains('https://sub.example.com/***'));
      expect(log.payload, startsWith('fetch'));
    });
  });
}
