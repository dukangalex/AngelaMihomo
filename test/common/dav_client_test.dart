import 'dart:convert';
import 'dart:io';

import 'package:bett_box/common/dav_client.dart';
import 'package:bett_box/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supports servers with multiple WWW-Authenticate headers', () async {
    final backupBytes = utf8.encode('backup-data');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var storedBytes = <int>[];

    final subscription = server.listen((request) async {
      final authorization = request.headers.value(
        HttpHeaders.authorizationHeader,
      );
      if (authorization == null) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.add(
          HttpHeaders.wwwAuthenticateHeader,
          'Digest realm="DUFS", nonce="test-nonce", qop="auth"',
          preserveHeaderCase: true,
        );
        request.response.headers.add(
          HttpHeaders.wwwAuthenticateHeader,
          'Basic realm="DUFS"',
          preserveHeaderCase: true,
        );
      } else if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
      } else if (request.method == 'MKCOL') {
        request.response.statusCode = HttpStatus.created;
      } else if (request.method == 'PUT') {
        storedBytes = await request.fold<List<int>>(
          <int>[],
          (bytes, chunk) => bytes..addAll(chunk),
        );
        request.response.statusCode = HttpStatus.created;
      } else if (request.method == 'GET') {
        request.response.statusCode = HttpStatus.ok;
        request.response.add(storedBytes);
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });

    try {
      final client = DAVClient(
        DAV(
          uri: 'http://${server.address.host}:${server.port}',
          user: 'test',
          password: 'password',
        ),
      );

      expect(await client.pingCompleter.future, isTrue);
      expect(await client.backup(backupBytes), isTrue);
      expect(storedBytes, backupBytes);
      expect(await client.recovery(), backupBytes);
    } finally {
      await server.close(force: true);
      await subscription.cancel();
    }
  });

  group('T108 backup file rules', () {
    test('only versioned names are offered for recovery', () {
      expect(
        isVersionedBackupFileName('backup', 'backup_20261113_01.zip'),
        isTrue,
      );
      expect(
        isVersionedBackupFileName('backup', 'BACKUP_20261113_99.ZIP'),
        isTrue,
      );
      // The legacy unversioned file is deliberately excluded.
      expect(isVersionedBackupFileName('backup', 'backup.zip'), isFalse);
      expect(
        isVersionedBackupFileName('backup', 'backup_2026113_01.zip'),
        isFalse,
      );
      expect(
        isVersionedBackupFileName('backup', 'backup_20261113_1.zip'),
        isFalse,
      );
      expect(
        isVersionedBackupFileName('backup', 'other_20261113_01.zip'),
        isFalse,
      );
    });

    test('suspicious sizes are below the restorable floor', () {
      expect(isSuspiciousBackupSize(0), isTrue);
      expect(isSuspiciousBackupSize(99), isTrue);
      expect(isSuspiciousBackupSize(100), isFalse);
      expect(isSuspiciousBackupSize(4096), isFalse);
      expect(isSuspiciousBackupSize(null), isFalse);
    });
  });

  test('removes WebDAV authorization after a cross-origin redirect', () async {
    final downloadedBytes = utf8.encode('backup-data');
    final storageServer = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final webDavServer = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    var storageReceivedAuthorization = false;

    final storageSubscription = storageServer.listen((request) async {
      storageReceivedAuthorization =
          request.headers.value(HttpHeaders.authorizationHeader) != null;
      if (storageReceivedAuthorization) {
        request.response.statusCode = HttpStatus.unauthorized;
      } else {
        request.response.statusCode = HttpStatus.ok;
        request.response.add(downloadedBytes);
      }
      await request.response.close();
    });

    final webDavSubscription = webDavServer.listen((request) async {
      final authorization = request.headers.value(
        HttpHeaders.authorizationHeader,
      );
      if (authorization == null) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.set(
          HttpHeaders.wwwAuthenticateHeader,
          'Basic realm="test"',
        );
      } else if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
      } else if (request.method == 'MKCOL') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
      } else if (request.method == 'GET') {
        request.response.statusCode = HttpStatus.found;
        request.response.headers.set(
          HttpHeaders.locationHeader,
          'http://${storageServer.address.host}:${storageServer.port}/backup.zip',
        );
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });

    try {
      final client = DAVClient(
        DAV(
          uri: 'http://${webDavServer.address.host}:${webDavServer.port}',
          user: 'user',
          password: 'password',
        ),
      );

      expect(await client.pingCompleter.future, isTrue);
      expect(await client.recovery(), downloadedBytes);
      expect(storageReceivedAuthorization, isFalse);
    } finally {
      await webDavServer.close(force: true);
      await storageServer.close(force: true);
      await webDavSubscription.cancel();
      await storageSubscription.cancel();
    }
  });

  group('T108 failure reporting', () {
    Future<HttpServer> startFakeDav(
      Future<void> Function(HttpRequest request, List<int> body) handler,
    ) async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final authorization = request.headers.value(
          HttpHeaders.authorizationHeader,
        );
        if (authorization == null) {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.headers.set(
            HttpHeaders.wwwAuthenticateHeader,
            'Basic realm="test"',
          );
          await request.response.close();
          return;
        }
        final body = await request.fold<List<int>>(
          <int>[],
          (bytes, chunk) => bytes..addAll(chunk),
        );
        await handler(request, body);
        await request.response.close();
      });
      return server;
    }

    DAVClient clientFor(HttpServer server) => DAVClient(
      DAV(
        uri: 'http://${server.address.host}:${server.port}',
        user: 'user',
        password: 'password',
      ),
    );

    test(
      'backup fails when the server stores truncated bytes',
      () async {
        var stored = <int>[];
        final server = await startFakeDav((request, body) async {
          switch (request.method) {
            case 'OPTIONS':
              request.response.statusCode = HttpStatus.ok;
            case 'MKCOL':
              request.response.statusCode = HttpStatus.created;
            case 'PUT':
              // Simulate a server that silently truncates the upload.
              stored = body.sublist(0, body.length ~/ 2);
              request.response.statusCode = HttpStatus.created;
            case 'GET':
              request.response.statusCode = HttpStatus.ok;
              request.response.add(stored);
            default:
              request.response.statusCode = HttpStatus.notFound;
          }
        });
        try {
          final client = clientFor(server);
          expect(await client.pingCompleter.future, isTrue);
          await expectLater(
            client.backup(utf8.encode('backup-data-that-is-long-enough')),
            throwsA(contains('verification failed')),
          );
        } finally {
          await server.close(force: true);
        }
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'backup names the directory when it cannot be created',
      () async {
        final server = await startFakeDav((request, body) async {
          switch (request.method) {
            case 'OPTIONS':
              request.response.statusCode = HttpStatus.ok;
            default:
              request.response.statusCode = HttpStatus.notFound;
          }
        });
        try {
          final client = clientFor(server);
          expect(await client.pingCompleter.future, isTrue);
          await expectLater(
            client.backup(utf8.encode('backup-data')),
            throwsA(contains('not writable')),
          );
        } finally {
          await server.close(force: true);
        }
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test('recovery 404 keeps the file-not-found wording', () async {
      final server = await startFakeDav((request, body) async {
        switch (request.method) {
          case 'OPTIONS':
            request.response.statusCode = HttpStatus.ok;
          case 'MKCOL':
            request.response.statusCode = HttpStatus.created;
          default:
            request.response.statusCode = HttpStatus.notFound;
        }
      });
      try {
        final client = clientFor(server);
        expect(await client.pingCompleter.future, isTrue);
        await expectLater(
          client.recovery(),
          throwsA(contains('Backup file not found on server.')),
        );
      } finally {
        await server.close(force: true);
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
