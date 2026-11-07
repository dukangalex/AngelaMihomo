import 'package:bett_box/common/release_updates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repo = 'dukangalex/AngelaMihomo';
  Map<String, dynamic> release(List<String> names) => {
    'tag_name': 'v1.19.7-chain.15',
    'assets': [
      for (final name in names)
        {
          'name': name,
          'browser_download_url':
              'https://github.com/$repo/releases/download/v1.19.7-chain.15/$name',
        },
    ],
  };

  test('assets are taken from the list, foreign URLs rejected', () {
    final data = release(['AngelaMihomo-1.19.7-chain.15-android-arm64-v8a.apk']);
    data['assets'].add({
      'name': 'evil.apk',
      'browser_download_url': 'https://example.com/evil.apk',
    });
    final assets = releaseAssetsOf(data, repository: repo);
    expect(assets.length, 1);
    expect(assets.single.name, contains('arm64-v8a'));
  });

  test('android picks exact arch, then universal', () {
    final assets = releaseAssetsOf(
      release([
        'AngelaMihomo-1.19.7-chain.15-android-universal.apk',
        'AngelaMihomo-1.19.7-chain.15-android-arm64-v8a.apk',
        'AngelaMihomo-1.19.7-chain.15-android-x86_64.apk',
      ]),
      repository: repo,
    );
    expect(
      selectUpdateAsset(assets, platform: 'android', arch: 'arm64-v8a')?.name,
      contains('arm64-v8a'),
    );
    expect(
      selectUpdateAsset(assets, platform: 'android', arch: 'armeabi-v7a')?.name,
      contains('universal'),
    );
  });

  test('windows picks the setup exe for the arch; mac returns null', () {
    final assets = releaseAssetsOf(
      release([
        'AngelaMihomo-1.19.7-chain.15-windows-amd64-setup.exe',
        'AngelaMihomo-1.19.7-chain.15-windows-arm64-setup.exe',
        'AngelaMihomo-1.19.7-chain.15-windows-amd64-compatible-portable.zip',
        'SHA256SUMS',
      ]),
      repository: repo,
    );
    expect(
      selectUpdateAsset(assets, platform: 'windows', arch: 'amd64')?.name,
      contains('amd64-setup'),
    );
    expect(
      selectUpdateAsset(
        assets,
        platform: 'windows',
        arch: 'amd64',
        portable: true,
      )?.name,
      contains('portable'),
    );
    expect(selectUpdateAsset(assets, platform: 'macos', arch: 'arm64'), isNull);
    expect(findSumsAsset(assets)?.name, 'SHA256SUMS');
  });

  test('sha256sums parsing handles both line forms', () {
    final sums = parseSha256Sums(
      '${'a' * 64}  AngelaMihomo-x-android-universal.apk\n'
      '${'B' * 64} *AngelaMihomo-x-windows-amd64-setup.exe\n'
      'not a sum line\n',
    );
    expect(sums['AngelaMihomo-x-android-universal.apk'], 'a' * 64);
    expect(sums['AngelaMihomo-x-windows-amd64-setup.exe'], 'b' * 64);
  });
}
