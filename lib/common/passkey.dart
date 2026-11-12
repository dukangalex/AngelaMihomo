import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

/// Passkey (WebAuthn) support for the app lock (T74, Android first).
///
/// The relying party is the project's public Pages domain; the
/// matching /.well-known/assetlinks.json on that domain carries only
/// the app package name and the release signing-certificate
/// fingerprint (both already public). The credential itself lives in
/// the user's own system provider (e.g. Google Password Manager);
/// this app stores only the credential id and the public key, and
/// verifies assertion signatures entirely on-device. The app issues
/// no network request for registration or unlock — the platform /
/// Play services checking assetlinks while a credential is used is
/// system behaviour, not app traffic. No user name, e-mail or other
/// personal identifier is ever put into a credential: the WebAuthn
/// user handle is a locally generated random id.
const passkeyRpId = 'dukangalex.github.io';

String passkeyBase64Url(Uint8List bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

Uint8List passkeyBase64UrlDecode(String value) {
  var normalized = value.replaceAll('-', '+').replaceAll('_', '/');
  while (normalized.length % 4 != 0) {
    normalized += '=';
  }
  return base64.decode(normalized);
}

Uint8List _randomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
}

/// A fresh WebAuthn challenge (32 random bytes, base64url).
String newPasskeyChallenge() => passkeyBase64Url(_randomBytes(32));

/// The WebAuthn user handle: a locally generated random id with no
/// meaning and no personal data (16 random bytes, base64url).
String newPasskeyUserHandle() => passkeyBase64Url(_randomBytes(16));

// ---------------------------------------------------------------------------
// Minimal CBOR decoder — just the major types WebAuthn payloads use
// (ints, byte/text strings, arrays, maps, simple values). Attestation
// objects and COSE keys never need more.
// ---------------------------------------------------------------------------

class CborReader {
  final Uint8List _data;
  int _offset = 0;

  CborReader(this._data);

  int get offset => _offset;
  bool get isDone => _offset >= _data.length;

  Object? read() {
    if (_offset >= _data.length) {
      throw const FormatException('CBOR: unexpected end of input');
    }
    final initial = _data[_offset++];
    final major = initial >> 5;
    final info = initial & 0x1f;
    if (major == 7) {
      return switch (info) {
        20 => false,
        21 => true,
        22 => null,
        _ => throw FormatException('CBOR: unsupported simple value $info'),
      };
    }
    final argument = _readArgument(info);
    return switch (major) {
      0 => argument,
      1 => -1 - argument,
      2 => _readBytes(argument),
      3 => utf8.decode(_readBytes(argument)),
      4 => [for (var i = 0; i < argument; i++) read()],
      5 => {for (var i = 0; i < argument; i++) read(): read()},
      _ => throw FormatException('CBOR: unsupported major type $major'),
    };
  }

  int _readArgument(int info) {
    if (info < 24) return info;
    final extra = switch (info) {
      24 => 1,
      25 => 2,
      26 => 4,
      27 => 8,
      _ => throw FormatException('CBOR: unsupported info $info'),
    };
    if (_offset + extra > _data.length) {
      throw const FormatException('CBOR: truncated argument');
    }
    var value = 0;
    for (var i = 0; i < extra; i++) {
      value = (value << 8) | _data[_offset++];
    }
    return value;
  }

  Uint8List _readBytes(int length) {
    if (_offset + length > _data.length) {
      throw const FormatException('CBOR: truncated string');
    }
    final out = Uint8List.sublistView(_data, _offset, _offset + length);
    _offset += length;
    return out;
  }
}

Object? cborDecode(Uint8List data) => CborReader(data).read();

// ---------------------------------------------------------------------------
// NIST P-256 ECDSA verification in pure Dart (BigInt arithmetic). The
// app has no ECDSA dependency; verification is a single signature per
// unlock, so clarity beats speed here.
// ---------------------------------------------------------------------------

final _p256P = BigInt.parse(
  'FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF',
  radix: 16,
);
final _p256A = _p256P - BigInt.from(3);
final _p256B = BigInt.parse(
  '5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B',
  radix: 16,
);
final _p256N = BigInt.parse(
  'FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551',
  radix: 16,
);
final _p256G = (
  x: BigInt.parse(
    '6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296',
    radix: 16,
  ),
  y: BigInt.parse(
    '4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5',
    radix: 16,
  ),
);

typedef _EcPoint = ({BigInt x, BigInt y});

_EcPoint? _ecAdd(_EcPoint? a, _EcPoint? b) {
  if (a == null) return b;
  if (b == null) return a;
  final BigInt slope;
  if (a.x == b.x) {
    if ((a.y + b.y) % _p256P == BigInt.zero) return null;
    // Point doubling.
    slope =
        (BigInt.from(3) * a.x * a.x + _p256A) *
        (BigInt.two * a.y).modInverse(_p256P) %
        _p256P;
  } else {
    slope = (b.y - a.y) * (b.x - a.x).modInverse(_p256P) % _p256P;
  }
  final x = (slope * slope - a.x - b.x) % _p256P;
  final y = (slope * (a.x - x) - a.y) % _p256P;
  return (x: x, y: y);
}

_EcPoint? _ecMultiply(BigInt scalar, _EcPoint point) {
  _EcPoint? result;
  _EcPoint? addend = point;
  var k = scalar;
  while (k > BigInt.zero) {
    if (k.isOdd) result = _ecAdd(result, addend);
    addend = _ecAdd(addend, addend);
    k = k >> 1;
  }
  return result;
}

BigInt _bytesToBigInt(Uint8List bytes) {
  var value = BigInt.zero;
  for (final byte in bytes) {
    value = (value << 8) | BigInt.from(byte);
  }
  return value;
}

/// Verifies an ES256 signature: ECDSA over NIST P-256 with SHA-256.
/// [digest] is the already-computed SHA-256 of the signed data.
bool p256Verify({
  required BigInt publicKeyX,
  required BigInt publicKeyY,
  required Uint8List digest,
  required BigInt r,
  required BigInt s,
}) {
  final one = BigInt.one;
  if (r < one || r >= _p256N || s < one || s >= _p256N) return false;
  // The public key must actually sit on the curve.
  final left = (publicKeyY * publicKeyY) % _p256P;
  final right =
      (publicKeyX * publicKeyX * publicKeyX + _p256A * publicKeyX + _p256B) %
      _p256P;
  if (left != right) return false;
  final z = _bytesToBigInt(digest);
  final w = s.modInverse(_p256N);
  final u1 = (z * w) % _p256N;
  final u2 = (r * w) % _p256N;
  final point = _ecAdd(
    _ecMultiply(u1, _p256G),
    _ecMultiply(u2, (x: publicKeyX, y: publicKeyY)),
  );
  if (point == null) return false;
  return point.x % _p256N == r;
}

/// Parses a DER-encoded ECDSA signature into (r, s).
(BigInt, BigInt) parseDerEcdsaSignature(Uint8List der) {
  var i = 0;
  int readByte() {
    if (i >= der.length) throw const FormatException('DER: truncated');
    return der[i++];
  }

  BigInt readInteger() {
    if (readByte() != 0x02) throw const FormatException('DER: no integer');
    final length = readByte();
    if (i + length > der.length) {
      throw const FormatException('DER: truncated integer');
    }
    final bytes = Uint8List.sublistView(der, i, i + length);
    i += length;
    return _bytesToBigInt(bytes);
  }

  if (readByte() != 0x30) throw const FormatException('DER: no sequence');
  readByte(); // sequence length (short form; P-256 signatures are < 128 B)
  final r = readInteger();
  final s = readInteger();
  return (r, s);
}

// ---------------------------------------------------------------------------
// WebAuthn payload handling.
// ---------------------------------------------------------------------------

enum PasskeyVerifyFailure {
  malformed,
  typeMismatch,
  challengeMismatch,
  rpIdMismatch,
  userPresenceMissing,
  userVerificationMissing,
  credentialMismatch,
  badSignature,
}

class PasskeyVerificationException implements Exception {
  final PasskeyVerifyFailure failure;
  const PasskeyVerificationException(this.failure);

  @override
  String toString() => 'PasskeyVerificationException(${failure.name})';
}

class PasskeyPublicKey {
  final BigInt x;
  final BigInt y;
  const PasskeyPublicKey(this.x, this.y);

  /// Extracts the EC2 public key from its COSE encoding (the form the
  /// authenticator embeds in the attestation's authData).
  factory PasskeyPublicKey.fromCose(Uint8List coseBytes) {
    final decoded = cborDecode(coseBytes);
    if (decoded is! Map) {
      throw const PasskeyVerificationException(PasskeyVerifyFailure.malformed);
    }
    final kty = decoded[1];
    final alg = decoded[3];
    final crv = decoded[-1];
    final xBytes = decoded[-2];
    final yBytes = decoded[-3];
    if (kty != 2 ||
        alg != -7 ||
        crv != 1 ||
        xBytes is! Uint8List ||
        yBytes is! Uint8List ||
        xBytes.length != 32 ||
        yBytes.length != 32) {
      throw const PasskeyVerificationException(PasskeyVerifyFailure.malformed);
    }
    return PasskeyPublicKey(_bytesToBigInt(xBytes), _bytesToBigInt(yBytes));
  }
}

class _AuthData {
  final Uint8List rpIdHash;
  final int flags;
  final int signCount;
  final int headerLength;
  const _AuthData(this.rpIdHash, this.flags, this.signCount, this.headerLength);

  bool get userPresent => flags & 0x01 != 0;
  bool get userVerified => flags & 0x04 != 0;
  bool get hasAttestedCredentialData => flags & 0x40 != 0;
}

_AuthData _parseAuthDataHeader(Uint8List authData) {
  if (authData.length < 37) {
    throw const PasskeyVerificationException(PasskeyVerifyFailure.malformed);
  }
  final rpIdHash = Uint8List.sublistView(authData, 0, 32);
  final flags = authData[32];
  final signCount = ByteData.sublistView(authData, 33, 37).getUint32(0);
  return _AuthData(rpIdHash, flags, signCount, 37);
}

Map<String, dynamic> _parseClientData(
  Uint8List clientDataJson, {
  required String expectedType,
  required String expectedChallenge,
}) {
  final Map<String, dynamic> data;
  try {
    data = jsonDecode(utf8.decode(clientDataJson)) as Map<String, dynamic>;
  } catch (_) {
    throw const PasskeyVerificationException(PasskeyVerifyFailure.malformed);
  }
  if (data['type'] != expectedType) {
    throw const PasskeyVerificationException(PasskeyVerifyFailure.typeMismatch);
  }
  if (data['challenge'] != expectedChallenge) {
    throw const PasskeyVerificationException(
      PasskeyVerifyFailure.challengeMismatch,
    );
  }
  return data;
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

Uint8List _rpIdHash(String rpId) =>
    Uint8List.fromList(sha256.convert(utf8.encode(rpId)).bytes);

/// A registered passkey as the app keeps it locally: the credential
/// id and its public key coordinates (base64url, no padding). Nothing
/// here is secret — the private key never leaves the system provider.
class PasskeyRecord {
  final String credentialId;
  final String publicKeyX;
  final String publicKeyY;
  const PasskeyRecord({
    required this.credentialId,
    required this.publicKeyX,
    required this.publicKeyY,
  });

  PasskeyPublicKey get publicKey => PasskeyPublicKey(
    _bytesToBigInt(passkeyBase64UrlDecode(publicKeyX)),
    _bytesToBigInt(passkeyBase64UrlDecode(publicKeyY)),
  );
}

/// Validates a registration response (the pieces Credential Manager
/// returns) and extracts what the app stores. Checks the ceremony
/// type, our challenge, and that the attested credential was minted
/// for our relying party. Attestation is 'none' by design: for a
/// local unlock there is no server-side trust decision to make, the
/// freshly created key pair simply becomes the unlock key.
PasskeyRecord parsePasskeyRegistration({
  required Uint8List attestationObject,
  required Uint8List clientDataJson,
  required String expectedChallenge,
  String rpId = passkeyRpId,
}) {
  _parseClientData(
    clientDataJson,
    expectedType: 'webauthn.create',
    expectedChallenge: expectedChallenge,
  );
  final attestation = cborDecode(attestationObject);
  if (attestation is! Map || attestation['authData'] is! Uint8List) {
    throw const PasskeyVerificationException(PasskeyVerifyFailure.malformed);
  }
  final authData = attestation['authData'] as Uint8List;
  final header = _parseAuthDataHeader(authData);
  if (!_bytesEqual(header.rpIdHash, _rpIdHash(rpId))) {
    throw const PasskeyVerificationException(PasskeyVerifyFailure.rpIdMismatch);
  }
  if (!header.userPresent || !header.hasAttestedCredentialData) {
    throw const PasskeyVerificationException(PasskeyVerifyFailure.malformed);
  }
  var offset = header.headerLength + 16; // skip the AAGUID
  if (authData.length < offset + 2) {
    throw const PasskeyVerificationException(PasskeyVerifyFailure.malformed);
  }
  final credentialIdLength = ByteData.sublistView(
    authData,
    offset,
    offset + 2,
  ).getUint16(0);
  offset += 2;
  if (authData.length < offset + credentialIdLength) {
    throw const PasskeyVerificationException(PasskeyVerifyFailure.malformed);
  }
  final credentialId = Uint8List.sublistView(
    authData,
    offset,
    offset + credentialIdLength,
  );
  offset += credentialIdLength;
  final reader = CborReader(Uint8List.sublistView(authData, offset));
  final cose = reader.read();
  if (cose is! Map) {
    throw const PasskeyVerificationException(PasskeyVerifyFailure.malformed);
  }
  final coseBytes = Uint8List.sublistView(
    authData,
    offset,
    offset + reader.offset,
  );
  final publicKey = PasskeyPublicKey.fromCose(coseBytes);
  Uint8List coord(BigInt value) {
    final hex = value.toRadixString(16).padLeft(64, '0');
    return Uint8List.fromList([
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ]);
  }

  return PasskeyRecord(
    credentialId: passkeyBase64Url(credentialId),
    publicKeyX: passkeyBase64Url(coord(publicKey.x)),
    publicKeyY: passkeyBase64Url(coord(publicKey.y)),
  );
}

/// Verifies an assertion response against the stored [record],
/// entirely on-device. Throws [PasskeyVerificationException] with the
/// precise reason on any mismatch — a forged or tampered assertion
/// is always rejected, never waved through.
void verifyPasskeyAssertion({
  required PasskeyRecord record,
  required String expectedChallenge,
  required Uint8List authenticatorData,
  required Uint8List clientDataJson,
  required Uint8List signatureDer,
  String rpId = passkeyRpId,
}) {
  _parseClientData(
    clientDataJson,
    expectedType: 'webauthn.get',
    expectedChallenge: expectedChallenge,
  );
  final header = _parseAuthDataHeader(authenticatorData);
  if (!_bytesEqual(header.rpIdHash, _rpIdHash(rpId))) {
    throw const PasskeyVerificationException(PasskeyVerifyFailure.rpIdMismatch);
  }
  if (!header.userPresent) {
    throw const PasskeyVerificationException(
      PasskeyVerifyFailure.userPresenceMissing,
    );
  }
  if (!header.userVerified) {
    throw const PasskeyVerificationException(
      PasskeyVerifyFailure.userVerificationMissing,
    );
  }
  final clientDataHash = sha256.convert(clientDataJson).bytes;
  final signedBytes = Uint8List.fromList([
    ...authenticatorData,
    ...clientDataHash,
  ]);
  final digest = Uint8List.fromList(sha256.convert(signedBytes).bytes);
  final (r, s) = parseDerEcdsaSignature(signatureDer);
  final key = record.publicKey;
  if (!p256Verify(
    publicKeyX: key.x,
    publicKeyY: key.y,
    digest: digest,
    r: r,
    s: s,
  )) {
    throw const PasskeyVerificationException(PasskeyVerifyFailure.badSignature);
  }
}

// ---------------------------------------------------------------------------
// Platform side: Android Credential Manager through a method channel
// (implemented in MainActivity). Only the request/response JSON
// crosses the channel; every check above runs on the Dart side.
// ---------------------------------------------------------------------------

enum PasskeyPlatformError { cancelled, unsupported, noCredential, failed }

class PasskeyPlatformException implements Exception {
  final PasskeyPlatformError error;
  final String? detail;
  const PasskeyPlatformException(this.error, [this.detail]);

  @override
  String toString() => 'PasskeyPlatformException(${error.name})';
}

enum PasskeyAuthOutcome {
  /// Signature verified locally — unlock.
  success,

  /// The assertion came back but failed local verification. Counts
  /// toward the app-lock failure backoff like a wrong PIN.
  invalid,

  /// The user dismissed the system prompt. Not a failure.
  cancelled,

  /// No provider / no credential / platform error: the passkey path
  /// is simply unavailable right now; the PIN remains.
  unavailable,
}

class PasskeyService {
  static const _channelName = 'app.angelabettbox/passkey';
  static const _channel = MethodChannel(_channelName);

  /// Test seam: replaces the platform channel round-trip.
  static Future<String> Function(String method, String requestJson)?
  debugPlatformCall;

  /// Test seam: fixes the generated challenge so fixture responses
  /// can be verified deterministically.
  static String Function()? debugChallengeFactory;

  static String _newChallenge() =>
      debugChallengeFactory?.call() ?? newPasskeyChallenge();

  static Future<String> _callPlatform(String method, String requestJson) async {
    final debug = debugPlatformCall;
    if (debug != null) return debug(method, requestJson);
    try {
      final result = await _channel.invokeMethod<String>(method, {
        'requestJson': requestJson,
      });
      if (result == null) {
        throw const PasskeyPlatformException(PasskeyPlatformError.failed);
      }
      return result;
    } on PlatformException catch (e) {
      throw PasskeyPlatformException(switch (e.code) {
        'cancelled' => PasskeyPlatformError.cancelled,
        'unsupported' => PasskeyPlatformError.unsupported,
        'no_credential' => PasskeyPlatformError.noCredential,
        _ => PasskeyPlatformError.failed,
      }, e.message);
    }
  }

  static String _registrationRequestJson({
    required String challenge,
    required String userHandle,
  }) => jsonEncode({
    'challenge': challenge,
    'rp': {'id': passkeyRpId, 'name': 'AngelaMihomo'},
    'user': {'id': userHandle, 'name': userHandle, 'displayName': userHandle},
    'pubKeyCredParams': [
      {'type': 'public-key', 'alg': -7},
    ],
    'authenticatorSelection': {
      'userVerification': 'preferred',
      'residentKey': 'required',
    },
    'timeout': 60000,
    'attestation': 'none',
  });

  static String _assertionRequestJson({
    required String challenge,
    required String credentialId,
  }) => jsonEncode({
    'challenge': challenge,
    'rpId': passkeyRpId,
    'allowCredentials': [
      {'type': 'public-key', 'id': credentialId},
    ],
    'userVerification': 'preferred',
    'timeout': 60000,
  });

  /// Runs the system registration ceremony and returns the record to
  /// store locally. Throws [PasskeyPlatformException] for platform
  /// outcomes and [PasskeyVerificationException] if the returned
  /// credential does not check out.
  static Future<PasskeyRecord> register() async {
    final challenge = _newChallenge();
    final responseJson = await _callPlatform(
      'create',
      _registrationRequestJson(
        challenge: challenge,
        userHandle: newPasskeyUserHandle(),
      ),
    );
    final decoded = jsonDecode(responseJson) as Map<String, dynamic>;
    final response = decoded['response'] as Map<String, dynamic>;
    return parsePasskeyRegistration(
      attestationObject: passkeyBase64UrlDecode(
        response['attestationObject'] as String,
      ),
      clientDataJson: passkeyBase64UrlDecode(
        response['clientDataJSON'] as String,
      ),
      expectedChallenge: challenge,
    );
  }

  /// Runs the system assertion ceremony for [record] and verifies
  /// the signature locally. Never throws for expected outcomes; the
  /// caller maps the outcome onto the lock screen.
  static Future<PasskeyAuthOutcome> authenticate(PasskeyRecord record) async {
    final challenge = _newChallenge();
    final String responseJson;
    try {
      responseJson = await _callPlatform(
        'get',
        _assertionRequestJson(
          challenge: challenge,
          credentialId: record.credentialId,
        ),
      );
    } on PasskeyPlatformException catch (e) {
      return e.error == PasskeyPlatformError.cancelled
          ? PasskeyAuthOutcome.cancelled
          : PasskeyAuthOutcome.unavailable;
    }
    try {
      final decoded = jsonDecode(responseJson) as Map<String, dynamic>;
      if (decoded['id'] != record.credentialId) {
        throw const PasskeyVerificationException(
          PasskeyVerifyFailure.credentialMismatch,
        );
      }
      final response = decoded['response'] as Map<String, dynamic>;
      verifyPasskeyAssertion(
        record: record,
        expectedChallenge: challenge,
        authenticatorData: passkeyBase64UrlDecode(
          response['authenticatorData'] as String,
        ),
        clientDataJson: passkeyBase64UrlDecode(
          response['clientDataJSON'] as String,
        ),
        signatureDer: passkeyBase64UrlDecode(response['signature'] as String),
      );
      return PasskeyAuthOutcome.success;
    } catch (_) {
      return PasskeyAuthOutcome.invalid;
    }
  }
}
