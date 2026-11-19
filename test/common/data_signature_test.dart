import 'dart:convert';

import 'package:angelamihomo/common/data_signature.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = utf8.encode(
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef  managed.js\n',
  );

  Future<(List<int> publicKey, List<int> signature)> sign(
    List<int> bytes,
  ) async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final signature = await algorithm.sign(bytes, keyPair: keyPair);
    return (publicKey.bytes, signature.bytes);
  }

  test('a valid signature verifies against the signing key', () async {
    final (publicKey, signature) = await sign(manifest);
    expect(
      await verifyManifestSignature(
        manifest,
        signature,
        publicKeyBytes: publicKey,
      ),
      isTrue,
    );
  });

  test('a tampered manifest fails verification', () async {
    final (publicKey, signature) = await sign(manifest);
    final tampered = [...manifest];
    tampered[0] = tampered[0] ^ 0xFF;
    expect(
      await verifyManifestSignature(
        tampered,
        signature,
        publicKeyBytes: publicKey,
      ),
      isFalse,
    );
  });

  test('a signature from a different key fails verification', () async {
    final (_, signature) = await sign(manifest);
    final other = await Ed25519().newKeyPair();
    final otherPublicKey = await other.extractPublicKey();
    expect(
      await verifyManifestSignature(
        manifest,
        signature,
        publicKeyBytes: otherPublicKey.bytes,
      ),
      isFalse,
    );
  });

  test('a wrong-length signature fails closed', () async {
    final (publicKey, signature) = await sign(manifest);
    expect(
      await verifyManifestSignature(
        manifest,
        signature.sublist(0, 63),
        publicKeyBytes: publicKey,
      ),
      isFalse,
    );
    expect(
      await verifyManifestSignature(manifest, [
        ...signature,
        0,
      ], publicKeyBytes: publicKey),
      isFalse,
    );
    expect(
      await verifyManifestSignature(
        manifest,
        const [],
        publicKeyBytes: publicKey,
      ),
      isFalse,
    );
  });

  test('a malformed public key fails closed', () async {
    final (_, signature) = await sign(manifest);
    expect(
      await verifyManifestSignature(
        manifest,
        signature,
        publicKeyBytes: const [1, 2, 3],
      ),
      isFalse,
    );
  });

  test('the embedded key rejects a foreign signature', () async {
    final (_, signature) = await sign(manifest);
    // No injected key: verification runs against the embedded release
    // key, which did not sign this manifest.
    expect(await verifyManifestSignature(manifest, signature), isFalse);
    expect(base64.decode(manifestSigningPublicKeyBase64), hasLength(32));
  });
}
