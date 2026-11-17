import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bett_box/common/geo_data.dart';
import 'package:bett_box/common/release_updates.dart';
import 'package:bett_box/common/update_installer.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  const repo = 'dukangalex/angelamihomo-geo';
  const tag = 'v2026.11.1';
  final raw = <int>[...utf8.encode('AMCITY01'), ...List.filled(64, 7)];
  final gzBytes = gzip.encode(raw);
  final gzDigest = sha256.convert(gzBytes).toString();

  late Directory home;
  late Dio dio;
  var downloadCount = 0;

  setUpAll(() async {
    home = await Directory.systemTemp.createTemp('geo_data_test_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => home.path);
  });

  tearDownAll(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await home.delete(recursive: true);
  });

  setUp(() async {
    downloadCount = 0;
    for (final name in [
      GeoDataService.dataFileName,
      GeoDataService.metaFileName,
    ]) {
      final f = File('${home.path}/$name');
      if (await f.exists()) await f.delete();
    }
    dio = Dio();
    dio.httpClientAdapter = StubAdapter((options) async {
      final url = options.uri.toString();
      if (url == 'https://api.github.com/repos/$repo/releases/latest') {
        return ResponseBody.fromString(
          jsonEncode({
            'tag_name': tag,
            'assets': [
              {
                'name': GeoDataService.assetName,
                'browser_download_url':
                    'https://github.com/$repo/releases/download/$tag/${GeoDataService.assetName}',
                'size': gzBytes.length,
                'digest': 'sha256:$gzDigest',
              },
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      }
      if (url ==
          'https://github.com/$repo/releases/download/$tag/${GeoDataService.assetName}') {
        downloadCount++;
        return ResponseBody.fromBytes(gzBytes, 200);
      }
      return ResponseBody.fromString('not found', 404);
    });
  });

  GeoDataService service() => GeoDataService(
    updates: ReleaseUpdates(repository: repo, client: dio),
    installer: UpdateInstaller(dio: dio),
  );

  test('updateNow downloads, verifies, unpacks and records meta', () async {
    final svc = service();
    expect(await svc.currentMeta(), isNull);
    expect(await svc.updateNow(), GeoUpdateOutcome.updated);
    final dataFile = File('${home.path}/${GeoDataService.dataFileName}');
    expect(await dataFile.readAsBytes(), raw);
    final meta = await svc.currentMeta();
    expect(meta?.tag, tag);
    expect(downloadCount, 1);
  });

  test('updateNow is alreadyLatest when the tag matches', () async {
    final svc = service();
    expect(await svc.updateNow(), GeoUpdateOutcome.updated);
    expect(await svc.updateNow(), GeoUpdateOutcome.alreadyLatest);
    expect(downloadCount, 1);
  });

  test('ensureData downloads only when missing', () async {
    final svc = service();
    await svc.ensureData();
    expect(await svc.currentMeta(), isNotNull);
    expect(downloadCount, 1);
    await svc.ensureData();
    expect(downloadCount, 1);
  });

  test('a data file without meta counts as absent', () async {
    final svc = service();
    await File('${home.path}/${GeoDataService.dataFileName}').writeAsBytes(raw);
    expect(await svc.currentMeta(), isNull);
  });

  test('meta json round trip and garbage rejection', () {
    final meta = GeoDataMeta(
      tag: tag,
      downloadedAt: DateTime.utc(2026, 11, 17, 9, 30),
    );
    final back = GeoDataMeta.fromJson(meta.toJson());
    expect(back?.tag, tag);
    expect(back?.downloadedAt, meta.downloadedAt);
    expect(GeoDataMeta.fromJson(null), isNull);
    expect(GeoDataMeta.fromJson('nope'), isNull);
    expect(GeoDataMeta.fromJson({'tag': ''}), isNull);
    expect(GeoDataMeta.fromJson({'tag': tag, 'downloadedAt': 'junk'}), isNull);
  });
}
