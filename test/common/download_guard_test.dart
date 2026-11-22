import 'dart:io';

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('DownloadTargetGuard.blockFor', () {
    final blocked = <String, DownloadTargetBlock>{
      // Cloud metadata over the link-local address.
      'http://169.254.169.254/latest/meta-data':
          DownloadTargetBlock.linkLocalAddress,
      'http://169.254.0.1/': DownloadTargetBlock.linkLocalAddress,
      'http://169.254.255.255/': DownloadTargetBlock.linkLocalAddress,
      'https://[fe80::1]/': DownloadTargetBlock.linkLocalAddress,
      'https://[fe80::a9fe:a9fe]/': DownloadTargetBlock.linkLocalAddress,
      'https://[fe90::1]/': DownloadTargetBlock.linkLocalAddress,
      'https://[febf:ffff::1]/': DownloadTargetBlock.linkLocalAddress,
      'https://[fe80::1%25eth0]/': DownloadTargetBlock.linkLocalAddress,
      // Cloud metadata hostnames.
      'http://metadata.google.internal/':
          DownloadTargetBlock.cloudMetadataHost,
      'http://metadata.google.internal./':
          DownloadTargetBlock.cloudMetadataHost,
      'http://metadata.google/': DownloadTargetBlock.cloudMetadataHost,
      'http://metadata/': DownloadTargetBlock.cloudMetadataHost,
    };
    blocked.forEach((url, reason) {
      test('blocks $url', () {
        expect(DownloadTargetGuard.blockFor(Uri.parse(url)), reason);
        expect(DownloadTargetGuard.isBlocked(Uri.parse(url)), isTrue);
      });
    });

    final allowed = <String>[
      // Loopback stays allowed: the on-device subscription converter
      // is a legitimate feature.
      'http://127.0.0.1:25500/sub',
      'http://localhost:8080/sub',
      'https://[::1]/sub',
      // RFC1918 stays allowed: LAN-hosted subscriptions are a
      // legitimate feature.
      'http://192.168.1.10/sub',
      'http://10.0.0.2/sub',
      'http://172.16.0.9/sub',
      'http://172.31.255.255/sub',
      // Public destinations, including addresses just outside the
      // blocked link-local ranges.
      'https://example.com/sub',
      'http://169.253.0.1/',
      'http://169.255.0.1/',
      'https://[fe70::1]/',
      'https://[fec0::1]/',
      'https://[fd00::1]/',
      'https://[2001:db8::1]/',
      // Non-http(s) schemes are not classified by this guard.
      'file:///sdcard/config.yaml',
    ];
    for (final url in allowed) {
      test('allows $url', () {
        expect(DownloadTargetGuard.blockFor(Uri.parse(url)), isNull);
        expect(DownloadTargetGuard.isBlocked(Uri.parse(url)), isFalse);
      });
    }

    test('ensureAllowed throws for blocked targets only', () {
      expect(
        () => DownloadTargetGuard.ensureAllowed(
          Uri.parse('http://169.254.169.254/'),
        ),
        throwsA(isA<BlockedDownloadTargetException>()),
      );
      DownloadTargetGuard.ensureAllowed(Uri.parse('http://127.0.0.1/'));
    });
  });

  group('subscription download chain enforcement', () {
    late HttpServer server;
    late Directory home;
    late String base;

    setUpAll(() async {
      globalState.packageInfo = PackageInfo(
        appName: 'AngelaMihomo',
        packageName: 'app.angelamihomo',
        version: '1.0.0',
        buildNumber: '1',
      );
      home = await Directory.systemTemp.createTemp('angelamihomo_guard_');
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      base = 'http://127.0.0.1:${server.port}';
      server.listen((request) async {
        final response = request.response;
        switch (request.uri.path) {
          case '/final':
            response.write('mixed-port: 7890\n');
          case '/hop':
            await response.redirect(Uri.parse('$base/final'));
            return;
          case '/to-metadata-ip':
            await response.redirect(
              Uri.parse('http://169.254.169.254/latest/meta-data'),
            );
            return;
          case '/to-metadata-host':
            await response.redirect(
              Uri.parse('http://metadata.google.internal/'),
            );
            return;
          default:
            response.statusCode = HttpStatus.notFound;
        }
        await response.close();
      });
    });

    tearDownAll(() async {
      await server.close(force: true);
      await home.delete(recursive: true);
    });

    test('initial request to a metadata address is blocked', () async {
      final path = '${home.path}/blocked.download';
      await expectLater(
        request.fetchProfileSource('http://169.254.169.254/x', path),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<BlockedDownloadTargetException>(),
          ),
        ),
      );
    });

    test('redirect hop to a link-local address is blocked', () async {
      final path = '${home.path}/hop-blocked.download';
      await expectLater(
        request.fetchProfileSource('$base/to-metadata-ip', path),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<BlockedDownloadTargetException>(),
          ),
        ),
      );
    });

    test('redirect hop to a metadata hostname is blocked', () async {
      final path = '${home.path}/hop-host-blocked.download';
      await expectLater(
        request.fetchProfileSource('$base/to-metadata-host', path),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<BlockedDownloadTargetException>(),
          ),
        ),
      );
    });

    test('redirect to an allowed loopback target still downloads', () async {
      final path = '${home.path}/hop-ok.download';
      final source = await request.fetchProfileSource('$base/hop', path);
      expect(source.remote, isTrue);
      expect(await File(path).readAsString(), 'mixed-port: 7890\n');
    });

    test('text fetch follows an allowed redirect', () async {
      final response = await request.getTextResponseForUrl('$base/hop');
      expect(response.data, 'mixed-port: 7890\n');
      expect(response.redirects, hasLength(1));
    });
  });
}
