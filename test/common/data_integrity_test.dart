import 'dart:convert';
import 'dart:io';

import 'package:angelamihomo/common/constant.dart';
import 'package:angelamihomo/common/data_integrity.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:flutter_test/flutter_test.dart';

// T228/T233: the runtime integrity anchors verify the bundled
// core-bundle assets and the downloaded .mrs rule files against
// the data repository's signed manifests, fail-closed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bundleBytes = utf8.encode('fake bundle mrs payload');
  final zashBytes = utf8.encode('fake zash payload');
  final goodRule = utf8.encode('good rule bytes');
  final badRule = utf8.encode('tampered rule bytes');
  final customRule = utf8.encode('user provider bytes');

  String sumsFor(Map<String, List<int>> files) => files.entries
      .map((e) => '${sha256.convert(e.value)}  ${e.key}\n')
      .join();

  late Directory home;
  late List<int> publicKey;
  late Map<String, List<int>> signedManifests;

  Future<List<int>> sign(String sumsText) async {
    final algorithm = cryptography.Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(
      List.generate(32, (i) => i + 7),
    );
    final signature = await algorithm.sign(
      utf8.encode(sumsText),
      keyPair: keyPair,
    );
    return signature.bytes;
  }

  DataIntegrityService service({
    Map<String, List<int>>? assets,
    bool signBundle = true,
    bool signGeo = true,
  }) {
    final bundleSums = sumsFor({
      'BundleMRS.7z': bundleBytes,
      'zash.zip': zashBytes,
    });
    final geoSums = sumsFor({'geosite-cn.mrs': goodRule, 'geoip-cn.mrs': goodRule});
    return DataIntegrityService(
      bytesFetcher: (url) async {
        final isBundle = url.startsWith(coreBundleRawUrl);
        final sums = isBundle ? bundleSums : geoSums;
        if (url.endsWith('sha256sums.txt')) return utf8.encode(sums);
        if (url.endsWith('sha256sums.txt.sig')) {
          final shouldSign = isBundle ? signBundle : signGeo;
          return shouldSign ? signedManifests[sums] : null;
        }
        return null;
      },
      bundledAssetLoader: (name) async {
        final map = assets ??
            {'BundleMRS.7z': bundleBytes, 'zash.zip': zashBytes};
        final bytes = map[name];
        if (bytes == null) throw StateError('missing');
        return bytes;
      },
      homeDirResolver: () async => home.path,
      metaLoader: () async => null,
      metaSaver: (_) async {},
      manifestPublicKeyBytes: publicKey,
    );
  }

  setUpAll(() async {
    final algorithm = cryptography.Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(
      List.generate(32, (i) => i + 7),
    );
    publicKey = (await keyPair.extractPublicKey()).bytes;
    signedManifests = {};
    for (final sums in [
      sumsFor({'BundleMRS.7z': bundleBytes, 'zash.zip': zashBytes}),
      sumsFor({'geosite-cn.mrs': goodRule, 'geoip-cn.mrs': goodRule}),
    ]) {
      signedManifests[sums] = await sign(sums);
    }
  });

  setUp(() async {
    home = await Directory.systemTemp.createTemp('data_integrity_test_');
    final ruleset = Directory('${home.path}/ruleset');
    await ruleset.create();
    await File('${ruleset.path}/geosite-cn.mrs').writeAsBytes(goodRule);
    await File('${ruleset.path}/geoip-cn.mrs').writeAsBytes(badRule);
    await File('${ruleset.path}/custom.mrs').writeAsBytes(customRule);
  });

  tearDown(() => home.delete(recursive: true));

  test('all verified: bundle ok, tampered rule removed, custom kept', () async {
    final status = await service().runChecks();
    expect(status.bundleOk, isTrue);
    expect(status.bundleError, isNull);
    expect(status.rulesetChecked, 2);
    expect(status.rulesetRemoved, 1);
    expect(status.rulesetError, isNull);
    expect(await File('${home.path}/ruleset/geosite-cn.mrs').exists(), isTrue);
    expect(await File('${home.path}/ruleset/geoip-cn.mrs').exists(), isFalse);
    expect(await File('${home.path}/ruleset/custom.mrs').exists(), isTrue);
  });

  test('tampered bundled asset fails the bundle check by name', () async {
    final status = await service(
      assets: {
        'BundleMRS.7z': bundleBytes,
        'zash.zip': utf8.encode('swapped panel'),
      },
    ).runChecks();
    expect(status.bundleOk, isFalse);
    expect(status.bundleError, contains('zash.zip'));
  });

  test('missing geo signature: no deletions, reason recorded', () async {
    final status = await service(signGeo: false).runChecks();
    expect(status.bundleOk, isTrue);
    expect(status.rulesetRemoved, 0);
    expect(status.rulesetError, contains('sig'));
    expect(await File('${home.path}/ruleset/geoip-cn.mrs').exists(), isTrue);
  });

  test('missing bundle signature fails the bundle check closed', () async {
    final status = await service(signBundle: false).runChecks();
    expect(status.bundleOk, isFalse);
    expect(status.bundleError, contains('sig'));
  });

  test('status json round trip', () {
    final status = DataIntegrityStatus(
      checkedAt: DateTime.utc(2026, 11, 22),
      bundleOk: false,
      bundleError: 'zash.zip digest mismatch',
      rulesetChecked: 40,
      rulesetRemoved: 1,
    );
    final back = DataIntegrityStatus.fromJson(status.toJson());
    expect(back?.bundleOk, isFalse);
    expect(back?.bundleError, 'zash.zip digest mismatch');
    expect(back?.rulesetChecked, 40);
    expect(back?.rulesetRemoved, 1);
  });
}
