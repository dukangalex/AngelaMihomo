import 'dart:convert';
import 'dart:typed_data';

import 'package:angelamihomo/common/constant.dart';
import 'package:angelamihomo/common/release_updates.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class StubAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) respond;
  StubAdapter(this.respond);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

void main() {
  const repo = 'dukangalex/AngelaMihomo';
  const tag = 'v1.19.6-chain.2';
  const page = 'https://github.com/$repo/releases/tag/$tag';
  const suffix = 'linux-amd64-compatible.tar.gz';
  late Dio dio;
  late ReleaseUpdates updates;
  setUp(() {
    dio = Dio();
    updates = ReleaseUpdates(repository: repo, client: dio);
  });

  Map<String, dynamic> release({
    String name = 'AngelaBettbox-1.19.6-chain.2-$suffix',
  }) => {
    'tag_name': tag,
    'assets': [
      {
        'name': name,
        'browser_download_url':
            'https://github.com/$repo/releases/download/$tag/$name',
      },
    ],
  };

  test('latestWithAsset skips a newer release without the asset', () async {
    const geoRepo = 'dukangalex/angelamihomo-geo';
    final geo = ReleaseUpdates(repository: geoRepo, client: dio);
    Map<String, dynamic> rel(String tag, List<String> names) => {
      'tag_name': tag,
      'assets': [
        for (final n in names)
          {
            'name': n,
            'browser_download_url':
                'https://github.com/$geoRepo/releases/download/$tag/$n',
          },
      ],
    };
    dio.httpClientAdapter = StubAdapter((options) async {
      expect(
        options.uri.toString(),
        'https://api.github.com/repos/$geoRepo/releases?per_page=20',
      );
      return ResponseBody.fromString(
        jsonEncode([
          rel('core-bundle-2026.11', ['BundleMRS.7z', 'zash.zip']),
          rel('v2026.11.1', ['amcity.bin.gz', 'sha256sums.txt']),
        ]),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final data = (await geo.latestWithAsset(name: 'amcity.bin.gz'))!;
    expect(data['tag_name'], 'v2026.11.1');
    expect(
      geo.assetByName(data, name: 'amcity.bin.gz')?.url,
      'https://github.com/$geoRepo/releases/download/v2026.11.1/amcity.bin.gz',
    );
  });

  test('latestWithAsset returns null when no release ships the asset',
      () async {
    const geoRepo = 'dukangalex/angelamihomo-geo';
    final geo = ReleaseUpdates(repository: geoRepo, client: dio);
    dio.httpClientAdapter = StubAdapter((options) async {
      return ResponseBody.fromString(
        jsonEncode([
          {
            'tag_name': 'core-bundle-2026.11',
            'assets': [
              {
                'name': 'BundleMRS.7z',
                'browser_download_url':
                    'https://github.com/$geoRepo/releases/download/core-bundle-2026.11/BundleMRS.7z',
              },
            ],
          },
        ]),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    expect(await geo.latestWithAsset(name: 'amcity.bin.gz'), isNull);
  });

  test('fork checks its own repository rather than upstream', () {
    expect(repository, repo);
  });
  test(
    'reads stable metadata including real asset names and release notes',
    () async {
      dio.httpClientAdapter = StubAdapter((options) async {
        expect(
          options.uri.toString(),
          'https://api.github.com/repos/$repo/releases/latest',
        );
        return ResponseBody.fromString(
          jsonEncode({
            ...release(),
            'body': '- Fixed update checks',
            'html_url': 'https://unrelated.example',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      final data = (await updates.latest())!;
      expect(data['html_url'], page);
      expect(data['body'], '- Fixed update checks');
      expect(
        updates.downloadUrl(data, assetSuffix: suffix),
        contains('/AngelaBettbox-1.19.6-chain.2-$suffix'),
      );
    },
  );
  for (final invalid in [
    <String, dynamic>{'draft': true, 'tag_name': tag},
    {'prerelease': true, 'tag_name': tag},
    {'tag_name': ''},
    {'tag_name': 123},
  ]) {
    test('rejects invalid or non-stable metadata $invalid', () async {
      dio.httpClientAdapter = StubAdapter(
        (_) async => ResponseBody.fromString(
          jsonEncode(invalid),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
      expect(await updates.latest(), isNull);
    });
  }
  for (final location in [page, '/$repo/releases/tag/$tag']) {
    test('API rate limit falls back to stable redirect: $location', () async {
      var calls = 0;
      dio.httpClientAdapter = StubAdapter((options) async {
        calls++;
        if (calls == 1) return ResponseBody.fromString('rate limited', 403);
        expect(options.followRedirects, isFalse);
        expect(
          options.uri.toString(),
          'https://github.com/$repo/releases/latest',
        );
        return ResponseBody.fromString(
          '',
          302,
          headers: {
            'location': [location],
          },
        );
      });
      final data = (await updates.latest())!;
      expect(calls, 2);
      expect(data['tag_name'], tag);
      expect(updates.downloadUrl(data, assetSuffix: suffix), page);
    });
  }
  for (final location in [
    'https://example.com/$repo/releases/tag/$tag',
    'https://github.com/other/repo/releases/tag/$tag',
    '/$repo/releases',
    '/$repo/releases/tag/',
    'http://github.com/$repo/releases/tag/$tag',
  ]) {
    test(
      'rejects unrelated or malformed fallback location $location',
      () async {
        var calls = 0;
        dio.httpClientAdapter = StubAdapter(
          (_) async => ++calls == 1
              ? ResponseBody.fromString('', 403)
              : ResponseBody.fromString(
                  '',
                  302,
                  headers: {
                    'location': [location],
                  },
                ),
        );
        expect(await updates.latest(), isNull);
      },
    );
  }
  test('accepts existing Bettbox build names without renaming them', () {
    final data = release(name: 'Bettbox-1.19.6-chain.2-$suffix');
    expect(
      updates.downloadUrl(data, assetSuffix: suffix),
      endsWith('/Bettbox-1.19.6-chain.2-$suffix'),
    );
  });
  test('accepts current AngelaMihomo build names', () {
    final data = release(name: 'AngelaMihomo-1.19.6-chain.2-$suffix');
    expect(
      updates.downloadUrl(data, assetSuffix: suffix),
      endsWith('/AngelaMihomo-1.19.6-chain.2-$suffix'),
    );
  });
  test(
    'missing platform, missing assets or empty suffix opens exact release page',
    () {
      expect(
        updates.downloadUrl(release(), assetSuffix: 'android-arm64.apk'),
        page,
      );
      expect(updates.downloadUrl({'tag_name': tag}, assetSuffix: suffix), page);
      expect(updates.downloadUrl(release()), page);
    },
  );
  test('never picks debug preview or another architecture as a substitute', () {
    expect(
      updates.downloadUrl(
        release(
          name:
              'AngelaBettbox-1.19.6-chain.2-android-universal-debug-preview.apk',
        ),
        assetSuffix: 'android-universal.apk',
      ),
      page,
    );
    expect(
      updates.downloadUrl(
        release(
          name: 'AngelaBettbox-1.19.6-chain.2-linux-arm64-compatible.tar.gz',
        ),
        assetSuffix: suffix,
      ),
      page,
    );
  });
  test(
    'ambiguous assets use release page rather than selecting arbitrarily',
    () {
      final data = release();
      (data['assets'] as List).add(
        (release(name: 'Bettbox-1.19.6-chain.2-$suffix')['assets'] as List)
            .single,
      );
      expect(updates.downloadUrl(data, assetSuffix: suffix), page);
    },
  );
  for (final bad in [
    'https://example.com/download.apk',
    'https://github.com/$repo/releases/download/old/file.apk',
    'http://github.com/$repo/releases/download/$tag/AngelaBettbox-1.19.6-chain.2-$suffix',
  ]) {
    test('rejects asset URL outside exact release: $bad', () {
      final data = release();
      (data['assets'] as List).single['browser_download_url'] = bad;
      expect(updates.downloadUrl(data, assetSuffix: suffix), page);
    });
  }
  group('assetFor (T179 in-app update)', () {
    test('returns validated metadata including the API digest', () {
      final data = release();
      final asset = Map<String, dynamic>.from(
        (data['assets'] as List).single as Map,
      );
      asset['size'] = 12345;
      asset['digest'] = 'sha256:abcdef0123';
      data['assets'] = [asset];
      final found = updates.assetFor(data, assetSuffix: suffix);
      expect(found, isNotNull);
      expect(found!.name, 'AngelaBettbox-1.19.6-chain.2-$suffix');
      expect(found.size, 12345);
      expect(found.sha256, 'abcdef0123');
      expect(
        found.url,
        'https://github.com/$repo/releases/download/$tag/AngelaBettbox-1.19.6-chain.2-$suffix',
      );
    });
    test('digest absent or malformed yields null sha256', () {
      final data = release();
      expect(updates.assetFor(data, assetSuffix: suffix)!.sha256, isNull);
      ((data['assets'] as List).single as Map)['digest'] = 'md5:xyz';
      expect(updates.assetFor(data, assetSuffix: suffix)!.sha256, isNull);
    });
    test('no unique match yields null', () {
      expect(updates.assetFor(release(), assetSuffix: 'nope.zip'), isNull);
      expect(updates.assetFor(release()), isNull);
    });
  });

  group('assetByName (T194 geo data)', () {
    const geoRepo = 'dukangalex/angelamihomo-geo';
    const geoTag = 'v2026.11.1';
    late ReleaseUpdates geoUpdates;
    setUp(() {
      geoUpdates = ReleaseUpdates(repository: geoRepo, client: Dio());
    });

    Map<String, dynamic> geoRelease({
      String name = 'amcity.bin.gz',
      String? url,
      Object? digest = 'sha256:abc123',
    }) => {
      'tag_name': geoTag,
      'assets': [
        {
          'name': name,
          'browser_download_url':
              url ??
              'https://github.com/$geoRepo/releases/download/$geoTag/$name',
          'digest': ?digest,
          'size': 42,
        },
      ],
    };

    test('returns the exact-name asset with its digest', () {
      final asset = geoUpdates.assetByName(geoRelease(), name: 'amcity.bin.gz');
      expect(asset, isNotNull);
      expect(asset!.name, 'amcity.bin.gz');
      expect(asset.sha256, 'abc123');
      expect(asset.size, 42);
    });

    test('rejects a download URL outside this repo and tag', () {
      final asset = geoUpdates.assetByName(
        geoRelease(
          url:
              'https://github.com/other/repo/releases/download/$geoTag/amcity.bin.gz',
        ),
        name: 'amcity.bin.gz',
      );
      expect(asset, isNull);
    });

    test('returns null when the asset is absent or duplicated', () {
      expect(
        geoUpdates.assetByName(
          geoRelease(name: 'other.bin'),
          name: 'amcity.bin.gz',
        ),
        isNull,
      );
      final dup = geoRelease();
      (dup['assets'] as List).add({
        'name': 'amcity.bin.gz',
        'browser_download_url':
            'https://github.com/$geoRepo/releases/download/$geoTag/amcity.bin.gz',
      });
      expect(geoUpdates.assetByName(dup, name: 'amcity.bin.gz'), isNull);
    });

    test('asset without a digest still resolves, sha256 null', () {
      final asset = geoUpdates.assetByName(
        geoRelease(digest: null),
        name: 'amcity.bin.gz',
      );
      expect(asset, isNotNull);
      expect(asset!.sha256, isNull);
    });
  });
}
