import 'dart:convert';

import 'package:angelamihomo/common/update_installer.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const setupDigest =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
  const apkDigest =
      'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';
  const setupName = 'AngelaMihomo-1.19.8-test-windows-amd64-setup.exe';
  const apkName = 'AngelaMihomo-1.19.8-test-android-universal.apk';
  final manifest = utf8.encode(
    '$setupDigest  $setupName\n$apkDigest  $apkName\n',
  );

  group('sha256DigestFromManifest', () {
    test('finds the digest of a listed asset', () {
      expect(sha256DigestFromManifest(manifest, setupName), setupDigest);
      expect(sha256DigestFromManifest(manifest, apkName), apkDigest);
    });

    test('accepts the binary marker and single-space separator', () {
      final marked = utf8.encode('$setupDigest *$setupName\n');
      expect(sha256DigestFromManifest(marked, setupName), setupDigest);
      final single = utf8.encode('$setupDigest $setupName\n');
      expect(sha256DigestFromManifest(single, setupName), setupDigest);
    });

    test('returns null for an unlisted asset', () {
      expect(sha256DigestFromManifest(manifest, 'other.zip'), isNull);
    });

    test('skips malformed lines', () {
      final messy = utf8.encode(
        'not-a-digest  $setupName\n'
        'abc  too-short\n'
        '\n'
        '$setupDigest  $setupName\n',
      );
      expect(sha256DigestFromManifest(messy, setupName), setupDigest);
    });
  });

  group('UpdateInstaller.verifiedDigest', () {
    final installer = UpdateInstaller();

    Future<(List<int> publicKey, List<int> signature)> sign(
      List<int> bytes,
    ) async {
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final signature = await algorithm.sign(bytes, keyPair: keyPair);
      return (publicKey.bytes, signature.bytes);
    }

    test('returns the digest when the signature verifies', () async {
      final (publicKey, signature) = await sign(manifest);
      expect(
        await installer.verifiedDigest(
          manifestBytes: manifest,
          signatureBytes: signature,
          assetName: setupName,
          publicKeyBytes: publicKey,
        ),
        setupDigest,
      );
    });

    test('returns null when the manifest was tampered with', () async {
      final (publicKey, signature) = await sign(manifest);
      final tampered = [...manifest];
      tampered[0] = tampered[0] ^ 0xFF;
      expect(
        await installer.verifiedDigest(
          manifestBytes: tampered,
          signatureBytes: signature,
          assetName: setupName,
          publicKeyBytes: publicKey,
        ),
        isNull,
      );
    });

    test('returns null when the asset is not in a valid manifest', () async {
      final (publicKey, signature) = await sign(manifest);
      expect(
        await installer.verifiedDigest(
          manifestBytes: manifest,
          signatureBytes: signature,
          assetName: 'other.zip',
          publicKeyBytes: publicKey,
        ),
        isNull,
      );
    });

    test('returns null for a truncated signature', () async {
      final (publicKey, signature) = await sign(manifest);
      expect(
        await installer.verifiedDigest(
          manifestBytes: manifest,
          signatureBytes: signature.sublist(0, 32),
          assetName: setupName,
          publicKeyBytes: publicKey,
        ),
        isNull,
      );
    });

    // The release pipeline signs with OpenSSL (tools/release/
    // sign-release-assets.sh); this fixed vector — an OpenSSL-made
    // signature over the manifest above, throwaway key — proves the
    // in-app verifier accepts signatures made outside Dart.
    test('accepts an OpenSSL-produced signature', () async {
      final publicKey = base64.decode(
        'N6i9FPswvvlfH+XRpMjMPnfc0da6hgzwGwbKpKY1dmM=',
      );
      final signature = base64.decode(
        'K8NL/dBRIBs6Ndjd1eTNwum5AolgIGyH9bhX1qiMHm/0nTrJ3LRcL1EtrcBwZfe4ZoBx3TbSJ3n+POxSrHnrAg==',
      );
      expect(
        await installer.verifiedDigest(
          manifestBytes: manifest,
          signatureBytes: signature,
          assetName: apkName,
          publicKeyBytes: publicKey,
        ),
        apkDigest,
      );
    });
  });
}
