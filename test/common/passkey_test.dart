import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bett_box/common/app_lock.dart';
import 'package:bett_box/common/passkey.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'passkey_fixture.dart';

// All cryptographic material in passkey_fixture.dart was produced
// with OpenSSL, independently of the code under test: a genuine
// P-256 key pair, a genuine attestation object, and genuine ECDSA
// signatures over the fixture payloads.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PasskeyRecord fixtureRecord() => const PasskeyRecord(
    credentialId: fixtureCredentialId,
    publicKeyX: fixturePublicKeyX,
    publicKeyY: fixturePublicKeyY,
  );

  group('base64url + CBOR plumbing', () {
    test('base64url round-trips without padding', () {
      final bytes = Uint8List.fromList(List.generate(64, (i) => i * 3 % 256));
      final encoded = passkeyBase64Url(bytes);
      expect(encoded, isNot(contains('=')));
      expect(passkeyBase64UrlDecode(encoded), bytes);
    });

    test('CBOR decodes the attestation object structure', () {
      final decoded = cborDecode(
        passkeyBase64UrlDecode(fixtureAttestationObject),
      );
      expect(decoded, isA<Map>());
      final map = decoded as Map;
      expect(map['fmt'], 'none');
      expect(map['authData'], isA<Uint8List>());
    });

    test('new challenges and user handles are random', () {
      expect(newPasskeyChallenge(), isNot(newPasskeyChallenge()));
      expect(newPasskeyUserHandle(), isNot(newPasskeyUserHandle()));
      expect(passkeyBase64UrlDecode(newPasskeyChallenge()), hasLength(32));
    });
  });

  group('registration parsing', () {
    test('extracts credential id and public key from attestation', () {
      final record = parsePasskeyRegistration(
        attestationObject: passkeyBase64UrlDecode(fixtureAttestationObject),
        clientDataJson: passkeyBase64UrlDecode(fixtureCreateClientDataJson),
        expectedChallenge: fixtureChallenge,
      );
      expect(record.credentialId, fixtureCredentialId);
      expect(record.publicKeyX, fixturePublicKeyX);
      expect(record.publicKeyY, fixturePublicKeyY);
    });

    test('rejects a registration minted for another challenge', () {
      expect(
        () => parsePasskeyRegistration(
          attestationObject: passkeyBase64UrlDecode(fixtureAttestationObject),
          clientDataJson: passkeyBase64UrlDecode(fixtureCreateClientDataJson),
          expectedChallenge: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        ),
        throwsA(
          isA<PasskeyVerificationException>().having(
            (e) => e.failure,
            'failure',
            PasskeyVerifyFailure.challengeMismatch,
          ),
        ),
      );
    });
  });

  group('assertion verification (local ES256)', () {
    void verify({
      String challenge = fixtureChallenge,
      String authData = fixtureAssertionAuthData,
      String clientData = fixtureGetClientDataJson,
      String signature = fixtureSignature,
      PasskeyRecord? record,
    }) {
      verifyPasskeyAssertion(
        record: record ?? fixtureRecord(),
        expectedChallenge: challenge,
        authenticatorData: passkeyBase64UrlDecode(authData),
        clientDataJson: passkeyBase64UrlDecode(clientData),
        signatureDer: passkeyBase64UrlDecode(signature),
      );
    }

    test('accepts the genuine OpenSSL-signed assertion', () {
      expect(verify, returnsNormally);
    });

    test('rejects a signature made over a different message', () {
      expect(
        () => verify(signature: fixtureSignatureWrongMessage),
        throwsA(
          isA<PasskeyVerificationException>().having(
            (e) => e.failure,
            'failure',
            PasskeyVerifyFailure.badSignature,
          ),
        ),
      );
    });

    test('rejects a tampered signature byte', () {
      final der = passkeyBase64UrlDecode(fixtureSignature);
      der[der.length - 3] ^= 0x01;
      expect(
        () => verifyPasskeyAssertion(
          record: fixtureRecord(),
          expectedChallenge: fixtureChallenge,
          authenticatorData: passkeyBase64UrlDecode(fixtureAssertionAuthData),
          clientDataJson: passkeyBase64UrlDecode(fixtureGetClientDataJson),
          signatureDer: der,
        ),
        throwsA(isA<PasskeyVerificationException>()),
      );
    });

    test('rejects an assertion minted for a foreign relying party', () {
      expect(
        () => verify(
          authData: fixtureEvilRpAuthData,
          signature: fixtureEvilRpSignature,
        ),
        throwsA(
          isA<PasskeyVerificationException>().having(
            (e) => e.failure,
            'failure',
            PasskeyVerifyFailure.rpIdMismatch,
          ),
        ),
      );
    });

    test('rejects an assertion without user verification', () {
      expect(
        () => verify(
          authData: fixtureNoUvAuthData,
          signature: fixtureNoUvSignature,
        ),
        throwsA(
          isA<PasskeyVerificationException>().having(
            (e) => e.failure,
            'failure',
            PasskeyVerifyFailure.userVerificationMissing,
          ),
        ),
      );
    });

    test('rejects a challenge mismatch', () {
      expect(
        () => verify(challenge: 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh9'),
        throwsA(
          isA<PasskeyVerificationException>().having(
            (e) => e.failure,
            'failure',
            PasskeyVerifyFailure.challengeMismatch,
          ),
        ),
      );
    });

    test('rejects verification against the wrong stored key', () {
      const wrong = PasskeyRecord(
        credentialId: fixtureCredentialId,
        publicKeyX: fixturePublicKeyY,
        publicKeyY: fixturePublicKeyX,
      );
      expect(
        () => verify(record: wrong),
        throwsA(isA<PasskeyVerificationException>()),
      );
    });
  });

  group('PasskeyService orchestration (fake platform)', () {
    String registrationResponse() => jsonEncode({
      'id': fixtureCredentialId,
      'rawId': fixtureCredentialId,
      'type': 'public-key',
      'response': {
        'attestationObject': fixtureAttestationObject,
        'clientDataJSON': fixtureCreateClientDataJson,
      },
    });

    String assertionResponse({String signature = fixtureSignature}) =>
        jsonEncode({
          'id': fixtureCredentialId,
          'rawId': fixtureCredentialId,
          'type': 'public-key',
          'response': {
            'authenticatorData': fixtureAssertionAuthData,
            'clientDataJSON': fixtureGetClientDataJson,
            'signature': signature,
            'userHandle': '',
          },
        });

    setUp(() {
      PasskeyService.debugChallengeFactory = () => fixtureChallenge;
    });

    tearDown(() {
      PasskeyService.debugPlatformCall = null;
      PasskeyService.debugChallengeFactory = null;
    });

    test('register() binds our RP and a meaningless user handle', () async {
      String? sentRequest;
      PasskeyService.debugPlatformCall = (method, requestJson) async {
        expect(method, 'create');
        sentRequest = requestJson;
        return registrationResponse();
      };
      final record = await PasskeyService.register();
      expect(record.credentialId, fixtureCredentialId);
      final request = jsonDecode(sentRequest!) as Map<String, dynamic>;
      expect((request['rp'] as Map)['id'], 'dukangalex.github.io');
      final user = request['user'] as Map<String, dynamic>;
      // The user handle is a random local id — never an e-mail or a
      // name: it contains no '@' and equals the opaque id verbatim.
      expect(user['name'], user['id']);
      expect(user['name'], isNot(contains('@')));
    });

    test('authenticate() succeeds on a genuine assertion', () async {
      PasskeyService.debugPlatformCall = (method, requestJson) async {
        expect(method, 'get');
        final request = jsonDecode(requestJson) as Map<String, dynamic>;
        expect(request['rpId'], 'dukangalex.github.io');
        expect(
          (request['allowCredentials'] as List).single['id'],
          fixtureCredentialId,
        );
        return assertionResponse();
      };
      expect(
        await PasskeyService.authenticate(fixtureRecord()),
        PasskeyAuthOutcome.success,
      );
    });

    test('authenticate() maps a forged assertion to invalid', () async {
      PasskeyService.debugPlatformCall = (_, _) async =>
          assertionResponse(signature: fixtureSignatureWrongMessage);
      expect(
        await PasskeyService.authenticate(fixtureRecord()),
        PasskeyAuthOutcome.invalid,
      );
    });

    test('authenticate() maps user cancellation to cancelled', () async {
      PasskeyService.debugPlatformCall = (_, _) async =>
          throw const PasskeyPlatformException(PasskeyPlatformError.cancelled);
      expect(
        await PasskeyService.authenticate(fixtureRecord()),
        PasskeyAuthOutcome.cancelled,
      );
    });

    test('authenticate() maps a missing credential to unavailable', () async {
      PasskeyService.debugPlatformCall = (_, _) async =>
          throw const PasskeyPlatformException(
            PasskeyPlatformError.noCredential,
          );
      expect(
        await PasskeyService.authenticate(fixtureRecord()),
        PasskeyAuthOutcome.unavailable,
      );
    });
  });

  group('app-lock store: passkey record and accounting', () {
    late Directory tempDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('passkey_store_test');
      AppLockStore.storageDirOverride = tempDir;
    });

    tearDown(() async {
      AppLockStore.storageDirOverride = null;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('record round-trips and removal clears it', () async {
      await AppLockStore.setPin('2468');
      await AppLockStore.registerPasskey(
        credentialId: fixtureCredentialId,
        publicKeyX: fixturePublicKeyX,
        publicKeyY: fixturePublicKeyY,
      );
      var config = await AppLockStore.load();
      expect(config.hasPasskey, isTrue);
      expect(config.passkeyCredentialId, fixtureCredentialId);
      await AppLockStore.removePasskey();
      config = await AppLockStore.load();
      expect(config.hasPasskey, isFalse);
      expect(config.hasPin, isTrue);
    });

    test('legacy config JSON without passkey fields loads clean', () {
      final config = AppLockConfig.fromJson({
        'enabled': true,
        'salt': 's',
        'pinHash': 'h',
      });
      expect(config.hasPasskey, isFalse);
    });

    test('passkey failures share the PIN backoff policy', () async {
      await AppLockStore.setPin('1357');
      for (var i = 0; i < 5; i++) {
        await AppLockStore.recordPasskeyFailure();
      }
      var config = await AppLockStore.load();
      expect(config.failedAttempts, 5);
      expect(
        config.lockedUntilMs,
        greaterThan(DateTime.now().millisecondsSinceEpoch),
      );
      // During the backoff window further failures do not pile up.
      await AppLockStore.recordPasskeyFailure();
      config = await AppLockStore.load();
      expect(config.failedAttempts, 5);
    });

    test('passkey success resets the failure counters', () async {
      await AppLockStore.setPin('1357');
      await AppLockStore.recordPasskeyFailure();
      await AppLockStore.recordPasskeySuccess();
      final config = await AppLockStore.load();
      expect(config.failedAttempts, 0);
      expect(config.lockedUntilMs, 0);
    });

    test('unlock offer needs lock on, PIN set, passkey set, Android', () {
      const base = AppLockConfig(
        enabled: true,
        salt: 's',
        pinHash: 'h',
        passkeyCredentialId: 'c',
        passkeyPublicKeyX: 'x',
        passkeyPublicKeyY: 'y',
      );
      expect(passkeyUnlockAllowed(config: base, isAndroid: true), isTrue);
      expect(passkeyUnlockAllowed(config: base, isAndroid: false), isFalse);
      expect(
        passkeyUnlockAllowed(
          config: base.copyWith(passkeyCredentialId: ''),
          isAndroid: true,
        ),
        isFalse,
      );
      expect(
        passkeyUnlockAllowed(
          config: base.copyWith(enabled: false),
          isAndroid: true,
        ),
        isFalse,
      );
    });
  });
}
