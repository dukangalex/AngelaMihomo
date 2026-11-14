import 'dart:convert';
import 'dart:io';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/models/models.dart';
import 'package:code_forge/script.dart';
import 'package:flutter_test/flutter_test.dart';

import '../plugins/code_forge/support.dart';

/// T95: the bundled managed script is the HiClash full script carried by the
/// upstream managed-scripts mechanism. It must declare the AngelaMihomo
/// compatibility marker, point its rule providers at the official
/// MetaCubeX source, and stay off until the user enables it per profile.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled managed script is the HiClash script with our marker', () async {
    final content = await ManagedScript.readBundled();
    expect(content, contains('const Compatible_With_AngelaMihomo'));
    expect(content, contains('function main(config, context)'));
    expect(content, contains('const ruleOptionsEnable'));
    expect(ManagedScript.parseVersion(content), '2026111401');
    // Rule providers come from the official MetaCubeX source, not a mirror.
    expect(
      content,
      contains(
        'https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/geolocation-cn.mrs',
      ),
    );
    expect(content, isNot(contains('fastly.jsdelivr.net/gh/MetaCubeX')));
    expect(content, isNot(contains('cdn.jsdelivr.net/gh/MetaCubeX')));
    // GeoX defaults align with the app's own official defaults.
    expect(
      content,
      contains(
        'https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat',
      ),
    );
    // Group icons are served from this repo; kernel UA pins follow the core.
    expect(content, isNot(contains('HiClash@assets-v1')));
    expect(
      content,
      contains(
        'https://raw.githubusercontent.com/dukangalex/AngelaMihomo/main/Icons/svg/',
      ),
    );
    expect(content, contains('mihomo/1.19.34'));
    expect(content, isNot(contains('mihomo/1.19.32')));
  });

  test(
    'every icon referenced by the bundled script exists in the repo',
    () async {
      final content = await ManagedScript.readBundled();
      final pattern = RegExp(
        r'AngelaMihomo/main/Icons/svg/([A-Za-z0-9_.-]+\.svg)',
      );
      final names = {
        for (final match in pattern.allMatches(content)) match.group(1)!,
      };
      expect(names.length, greaterThanOrEqualTo(30));
      for (final name in names) {
        expect(
          File('Icons/svg/$name').existsSync(),
          isTrue,
          reason: 'Icons/svg/$name is referenced but missing',
        );
      }
    },
  );

  test(
    'bundled version is the floor and nothing is synced by default',
    () async {
      await ManagedScript.loadBundledVersion();
      expect(ManagedScript.bundledVersion, '2026111401');
      const props = ManagedProps();
      expect(props.syncedVersion, isNull);
      expect(ManagedScript.syncedVersion(props), isNull);
      expect(ManagedScript.version(props), '2026111401');
      expect(ManagedScript.isCustom(props), isFalse);
    },
  );

  test('profiles do not run the managed script unless the user enables it', () {
    const profile = Profile(id: 'fresh', autoUpdateDuration: Duration.zero);
    expect(profile.managed, isFalse);
    expect(profile.runsManagedScript, isFalse);
    final optedIn = profile.copyWith(managed: true);
    expect(optedIn.runsManagedScript, isTrue);
  });

  test('the script engine extracts the bundled script options', () async {
    await initEditorNative();
    final content = await ManagedScript.readBundled();
    final decoded =
        json.decode(await extractScriptOptions(script: content)) as Map;
    final options = decoded['options'] as Map;
    expect(options.keys, containsAll(['手动选择', '自动选择', 'AdBlock', 'GitHub']));
    final icons = decoded['icons'] as Map;
    expect(icons['GitHub'], contains('Icons/svg/GitHub.svg'));
  });

  test('the bundled script transforms a minimal profile end to end', () async {
    await initEditorNative();
    final dir = await Directory.systemTemp.createTemp('hiclash_eval_');
    addTearDown(() => dir.delete(recursive: true));
    final input = File('${dir.path}/input.json')
      ..writeAsStringSync(
        json.encode({
          'port': 7890,
          'mode': 'rule',
          'proxies': [
            {
              'name': 'HK-1',
              'type': 'ss',
              'server': '127.0.0.1',
              'port': 8388,
              'cipher': 'aes-128-gcm',
              'password': 'x',
            },
          ],
          'proxy-groups': <Object?>[],
          'rules': ['MATCH,DIRECT'],
        }),
      );
    final output = File('${dir.path}/output.json');
    await evaluateScriptFile(
      script: await ManagedScript.readBundled(),
      inputPath: input.path,
      outputPath: output.path,
      token: 7,
    );
    final result =
        json.decode(output.readAsStringSync()) as Map<String, dynamic>;
    final groups = (result['proxy-groups'] as List)
        .map((g) => (g as Map)['name'])
        .toList();
    expect(groups, containsAll(['手动选择', '自动选择', 'GitHub', 'AdBlock']));
    final providers = result['rule-providers'] as Map;
    expect(providers, isNotEmpty);
    expect(
      providers.values.map((p) => (p as Map)['url']).join(' '),
      contains('raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/'),
    );
  });
}
