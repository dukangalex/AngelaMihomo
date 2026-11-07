import 'package:bett_box/common/log_redaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('redactLogText (T36)', () {
    test('masks subscription URL path and token, keeps host', () {
      const line =
          'GET https://sub.example.com/api/v1/client/subscribe?token=abc123def456 failed';
      final out = redactLogText(line);
      expect(out, isNot(contains('abc123def456')));
      expect(out, isNot(contains('/api/v1/client/subscribe')));
      expect(out, contains('https://sub.example.com/•••'));
      expect(out, contains('failed'));
    });

    test('masks userinfo credentials in URLs (WebDAV shape)', () {
      const line = 'upload to https://davuser:davpass@dav.example.com:8080/f';
      final out = redactLogText(line);
      expect(out, isNot(contains('davuser')));
      expect(out, isNot(contains('davpass')));
      expect(out, contains('dav.example.com:8080'));
    });

    test('masks node UUIDs and passwords', () {
      const line =
          'dial vless 24e6b7d0-9a8b-4c5d-8e7f-0123456789ab password=hunter2 done';
      final out = redactLogText(line);
      expect(out, isNot(contains('24e6b7d0')));
      expect(out, isNot(contains('hunter2')));
      expect(out, contains('dial vless'));
    });

    test('masks whole proxy share links', () {
      const line = 'proxy: vmess://eyJ2IjoiMiIsInBzIjoibm9kZSJ9 trailing';
      final out = redactLogText(line);
      expect(out, isNot(contains('eyJ2IjoiMiIsInBzIjoibm9kZSJ9')));
      expect(out, contains('vmess://•••'));
    });

    test('masks bearer tokens and token key-values', () {
      const line = 'Authorization: Bearer abcdef0123456789abcdef01 token: xyz';
      final out = redactLogText(line);
      expect(out, isNot(contains('abcdef0123456789abcdef01')));
      expect(out.toLowerCase(), isNot(contains('token: xyz')));
    });

    test('keeps ordinary diagnostic content intact', () {
      const line =
          '[TCP] 192.168.1.2:51000 --> www.google.com:443 match GeoIP(cn) using DIRECT';
      expect(redactLogText(line), line);
      const line2 = 'dial tcp 1.2.3.4:443: i/o timeout';
      expect(redactLogText(line2), line2);
    });

    test('keeps bare host URLs without tail unchanged', () {
      const line = 'check https://cp.cloudflare.com ok';
      expect(redactLogText(line), line);
    });
  });
}
