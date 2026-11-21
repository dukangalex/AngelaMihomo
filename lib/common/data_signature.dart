import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// AngelaMihomo (chain.28, T220): Ed25519 manifest signing for the
/// project's own data repository (dukangalex/angelamihomo-geo).
///
/// Every data release ships a `sha256sums.txt` manifest next to a
/// detached signature `sha256sums.txt.sig`: the raw 64-byte Ed25519
/// signature over the exact manifest bytes, made with the project's
/// release signing key. Only the public half is embedded here; the
/// private key never leaves the release machine. A payload is only
/// trusted once the manifest that carries its SHA-256 digest has
/// passed [verifyManifestSignature].
const String manifestSigningPublicKeyBase64 =
    'L3lU2XPCir+gbj4wvHllAUiRta2YIsGznvIoUmMPzFA=';

/// AngelaMihomo (T273): the separate signing key for app release
/// artifacts. Every app release ships a `sha256sums.txt` covering its
/// assets next to a detached `sha256sums.txt.sig`, signed with this
/// key; the in-app updater only installs a package whose digest comes
/// from a manifest that verifies against this public key (see
/// UpdateInstaller.verifiedDigest). Kept separate from the data
/// manifest key above so the two trust domains can rotate
/// independently. The private half never leaves the release machine.
const String updateSigningPublicKeyBase64 =
    '1G9pV+rGbniklK890UnYbHaEkf+aWdoQ0pqfewge7ko=';

/// Verify the detached Ed25519 [signatureBytes] over [manifestBytes].
///
/// [publicKeyBytes] is the raw 32-byte public key to verify against;
/// it exists so tests can inject a throwaway keypair, and defaults to
/// the embedded release key ([manifestSigningPublicKeyBase64]).
///
/// Fail closed: a malformed key, a signature that is not exactly 64
/// bytes, or any error during verification returns false.
Future<bool> verifyManifestSignature(
  List<int> manifestBytes,
  List<int> signatureBytes, {
  List<int>? publicKeyBytes,
}) async {
  try {
    if (signatureBytes.length != 64) return false;
    final keyBytes =
        publicKeyBytes ?? base64.decode(manifestSigningPublicKeyBase64);
    if (keyBytes.length != 32) return false;
    final algorithm = Ed25519();
    final publicKey = SimplePublicKey(keyBytes, type: KeyPairType.ed25519);
    return await algorithm.verify(
      manifestBytes,
      signature: Signature(signatureBytes, publicKey: publicKey),
    );
  } catch (_) {
    return false;
  }
}
