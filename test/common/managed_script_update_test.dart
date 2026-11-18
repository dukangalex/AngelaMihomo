import 'dart:convert';
import 'dart:io';

import 'package:angelamihomo/common/managed_script_update.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = 'https://data.example.test/geo-data/';
  const channelScript = '// @version 2026111405\nconst channel = true;\n';
  final channelBytes = utf8.encode(channelScript);
  final channelDigest = sha256.convert(channelBytes).toString();
  final sumsBytes = utf8.encode('$channelDigest  managed.js\n');

  late Directory dir;
  late File channelFile;
  String? storedMeta;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('managed_script_update_');
    channelFile = File('${dir.path}/managed.channel.js');
    storedMeta = null;
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  Future<(List<int> publicKey, List<int> signature)> sign(
    List<int> bytes,
  ) async {
    final algorithm = cryptography.Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final signature = await algorithm.sign(bytes, keyPair: keyPair);
    return (publicKey.bytes, signature.bytes);
  }

  ManagedScriptUpdateService service({
    required List<int> publicKey,
    required List<int>? Function(String url) fetch,
  }) => ManagedScriptUpdateService(
    baseUrl: base,
    manifestPublicKeyBytes: publicKey,
    bytesFetcher: (url) async => fetch(url),
    metaLoader: () async => storedMeta,
    metaSaver: (raw) async => storedMeta = raw,
    channelFileResolver: () async => channelFile,
  );

  test('a verified newer script is stored and reported', () async {
    final (publicKey, signature) = await sign(sumsBytes);
    final svc = service(
      publicKey: publicKey,
      fetch: (url) => switch (url) {
        '${base}sha256sums.txt' => sumsBytes,
        '${base}sha256sums.txt.sig' => signature,
        '${base}managed.js' => channelBytes,
        _ => null,
      },
    );
    expect(await svc.checkAndUpdate(), ManagedScriptUpdateOutcome.updated);
    expect(await channelFile.readAsString(), channelScript);
    expect(await svc.readChannelCopy(), channelScript);
    final (:status, bundledVersion: _, :effectiveVersion) = await svc
        .currentStatus(bundledVersion: '2026111404');
    expect(status.channelVersion, '2026111405');
    expect(status.sha256, channelDigest);
    expect(status.lastOutcome, 'updated');
    expect(status.lastError, isNull);
    expect(status.updatedAt, isNotNull);
    expect(effectiveVersion, '2026111405');
    // A second check with the same manifest is alreadyLatest.
    expect(
      await svc.checkAndUpdate(),
      ManagedScriptUpdateOutcome.alreadyLatest,
    );
  });

  test('signature failure keeps the old copy and records the reason', () async {
    final (publicKey, signature) = await sign(sumsBytes);
    await channelFile.writeAsString('// @version 2026111401\nconst old = 1;\n');
    storedMeta = json.encode(
      ManagedScriptChannelStatus(
        sha256: sha256.convert(await channelFile.readAsBytes()).toString(),
        channelVersion: '2026111401',
        updatedAt: DateTime.utc(2026, 11, 14),
        lastOutcome: 'updated',
      ).toJson(),
    );
    final forged = [...signature];
    forged[0] = forged[0] ^ 0xFF;
    final svc = service(
      publicKey: publicKey,
      fetch: (url) => switch (url) {
        '${base}sha256sums.txt' => sumsBytes,
        '${base}sha256sums.txt.sig' => forged,
        '${base}managed.js' => channelBytes,
        _ => null,
      },
    );
    expect(await svc.checkAndUpdate(), ManagedScriptUpdateOutcome.failed);
    expect(
      await channelFile.readAsString(),
      '// @version 2026111401\nconst old = 1;\n',
    );
    final (:status, bundledVersion: _, effectiveVersion: _) = await svc
        .currentStatus();
    expect(status.lastOutcome, 'failed');
    expect(status.lastError, contains('signature'));
    expect(status.channelVersion, '2026111401');
  });

  test('a missing signature is a recorded failure, not a downgrade', () async {
    final (publicKey, _) = await sign(sumsBytes);
    final svc = service(
      publicKey: publicKey,
      fetch: (url) => switch (url) {
        '${base}sha256sums.txt' => sumsBytes,
        '${base}managed.js' => channelBytes,
        _ => null,
      },
    );
    expect(await svc.checkAndUpdate(), ManagedScriptUpdateOutcome.failed);
    expect(await channelFile.exists(), isFalse);
    final (:status, bundledVersion: _, effectiveVersion: _) = await svc
        .currentStatus();
    expect(status.lastError, contains('.sig'));
  });

  test('a hash mismatch rejects the download', () async {
    final tamperedSums = utf8.encode('${'0' * 64}  managed.js\n');
    final (publicKey, signature) = await sign(tamperedSums);
    final svc = service(
      publicKey: publicKey,
      fetch: (url) => switch (url) {
        '${base}sha256sums.txt' => tamperedSums,
        '${base}sha256sums.txt.sig' => signature,
        '${base}managed.js' => channelBytes,
        _ => null,
      },
    );
    expect(await svc.checkAndUpdate(), ManagedScriptUpdateOutcome.failed);
    expect(await channelFile.exists(), isFalse);
    final (:status, bundledVersion: _, effectiveVersion: _) = await svc
        .currentStatus();
    expect(status.lastError, contains('sha256 mismatch'));
  });

  group('effective content resolution', () {
    const bundled = '// @version 2026111404\nconst bundled = true;\n';

    test('a newer channel copy wins over the bundled asset', () {
      expect(
        ManagedScriptUpdateService.resolveEffectiveContent(
          bundledContent: bundled,
          channelContent: channelScript,
        ),
        channelScript,
      );
    });

    test('an equal-version channel copy wins over the bundled asset', () {
      const same = '// @version 2026111404\nconst refreshed = true;\n';
      expect(
        ManagedScriptUpdateService.resolveEffectiveContent(
          bundledContent: bundled,
          channelContent: same,
        ),
        same,
      );
    });

    test('an older channel copy is ignored', () {
      const older = '// @version 2026111403\nconst old = true;\n';
      expect(
        ManagedScriptUpdateService.resolveEffectiveContent(
          bundledContent: bundled,
          channelContent: older,
        ),
        bundled,
      );
    });

    test('no channel copy keeps the bundled asset', () {
      expect(
        ManagedScriptUpdateService.resolveEffectiveContent(
          bundledContent: bundled,
          channelContent: null,
        ),
        bundled,
      );
    });
  });
}
