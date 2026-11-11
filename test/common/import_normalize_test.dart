import 'package:bett_box/common/import_normalize.dart';
import 'package:flutter_test/flutter_test.dart';

// T73: clipboard / scan routing relies on hasImportableContent to tell
// "node info a novice pasted" apart from "a subscription URL" and from
// unrelated text. These samples pin that distinction down.
void main() {
  group('ImportNormalize.hasImportableContent', () {
    const vmess =
        'vmess://eyJ2IjoiMiIsInBzIjoibm9kZSIsImFkZCI6ImV4YW1wbGUuY29tIiwicG9ydCI6IjQ0MyIsImlkIjoiMTExMTExMTEtMjIyMi0zMzMzLTQ0NDQtNTU1NTU1NTU1NTU1IiwibmV0IjoidGNwIiwidGxzIjoiIn0=';
    const vless =
        'vless://11111111-2222-3333-4444-555555555555@example.com:443?encryption=none&security=tls#node1';
    const ss = 'ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ=@example.com:8388#ssnode';

    test('单个节点链接可导入', () {
      expect(ImportNormalize.hasImportableContent(vmess), isTrue);
      expect(ImportNormalize.hasImportableContent(vless), isTrue);
      expect(ImportNormalize.hasImportableContent(ss), isTrue);
    });

    test('多条节点链接（换行分隔）可导入', () {
      expect(ImportNormalize.hasImportableContent('$vmess\n$vless'), isTrue);
    });

    test('base64 订阅内容可导入', () {
      const sub64 =
          'dm1lc3M6Ly9leUoySWpvaU1pSXNJbkJ6SWpvaWJtOWtaU0lzSW1Ga1pDSTZJbVY0WVcxd2JHVXVZMjl0SWl3aWNHOXlkQ0k2SWpRME15SXNJbWxrSWpvaU1URXhNVEV4TVRFdE1qSXlNaTB6TXpNekxUUTBORFF0TlRVMU5UVTFOVFUxTlRVMUlpd2libVYwSWpvaWRHTndJaXdpZEd4eklqb2lJbjA9CnZsZXNzOi8vMTExMTExMTEtMjIyMi0zMzMzLTQ0NDQtNTU1NTU1NTU1NTU1QGV4YW1wbGUuY29tOjQ0Mz9lbmNyeXB0aW9uPW5vbmUmc2VjdXJpdHk9dGxzI25vZGUx';
      expect(ImportNormalize.hasImportableContent(sub64), isTrue);
    });

    test('sing-box JSON 可导入', () {
      const json =
          '{"outbounds":[{"type":"vless","tag":"n1","server":"example.com","server_port":443,"uuid":"11111111-2222-3333-4444-555555555555"}]}';
      expect(ImportNormalize.hasImportableContent(json), isTrue);
    });

    test('粘贴的 Mihomo YAML 可导入', () {
      const yaml =
          'proxies:\n  - {name: n1, type: ss, server: example.com, port: 8388, cipher: aes-256-gcm, password: pw}';
      expect(ImportNormalize.hasImportableContent(yaml), isTrue);
    });

    test('订阅 URL 本身不是内容导入（走 URL 通道）', () {
      expect(
        ImportNormalize.hasImportableContent(
          'https://example.com/subscribe?token=abc123',
        ),
        isFalse,
      );
    });

    test('无关文本与空文本不可导入', () {
      expect(ImportNormalize.hasImportableContent('hello world'), isFalse);
      expect(
        ImportNormalize.hasImportableContent('WIFI:S:MyWiFi;T:WPA;P:123;;'),
        isFalse,
      );
      expect(ImportNormalize.hasImportableContent(''), isFalse);
      expect(ImportNormalize.hasImportableContent('   '), isFalse);
    });
  });
}
