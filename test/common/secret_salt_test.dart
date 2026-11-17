import 'dart:convert';

import 'package:angelamihomo/common/common.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

// T168 (chain.26): WebDAV credentials in backups are AES-256-GCM
// encrypted with a per-install key held in platform secure storage.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    utils.resetSecretKeyCache();
  });

  test('new secrets round-trip through real encryption', () async {
    final encrypted = await utils.encryptSecret('p@ssw0rd');
    expect(encrypted, startsWith('ENC2~'));
    expect(await utils.decryptSecret(encrypted), 'p@ssw0rd');
  });

  test('ciphertext cannot be recovered by base64 decoding', () async {
    final encrypted = await utils.encryptSecret('p@ssw0rd');
    final payload = encrypted.substring('ENC2~'.length);
    final decoded = base64.decode(payload);
    final asText = utf8.decode(decoded, allowMalformed: true);
    expect(asText, isNot(contains('p@ssw0rd')));
    expect(asText, isNot(contains(base64.encode(utf8.encode('p@ssw0rd')))));
    expect(encrypted, isNot(contains('p@ssw0rd')));
  });

  test('a different install key cannot decrypt (foreign backup)', () async {
    final encrypted = await utils.encryptSecret('p@ssw0rd');
    // Simulate another install: wipe the stored key so a fresh one is
    // generated on next use.
    FlutterSecureStorage.setMockInitialValues({});
    utils.resetSecretKeyCache();
    expect(await utils.decryptSecret(encrypted), isNull);
  });

  test('legacy ENC~ secrets still decrypt for migration', () async {
    // Fixtures built with the retired scheme (static salt, base64 layers).
    final step1 = base64.encode(utf8.encode('legacy-secret'));
    final legacy = 'ENC~${base64.encode(utf8.encode('AngelaMihomo:$step1'))}';
    expect(await utils.decryptSecret(legacy), 'legacy-secret');
    final step1b = base64.encode(utf8.encode('older-secret'));
    final older = 'ENC~${base64.encode(utf8.encode('Bettbox:$step1b'))}';
    expect(await utils.decryptSecret(older), 'older-secret');
  });

  test('plaintext and empty values pass through', () async {
    expect(await utils.decryptSecret('plain'), 'plain');
    expect(await utils.encryptSecret(''), '');
  });
}
