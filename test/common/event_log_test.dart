import 'dart:io';

import 'package:bett_box/common/event_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('AppEventLog (T148)', () {
    late Directory dir;
    var now = DateTime(2026, 11, 15, 10, 30);

    AppEventLog store() => AppEventLog(
      directoryProvider: () async => dir,
      clock: () => now,
    );

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('event_log_test');
      now = DateTime(2026, 11, 15, 10, 30);
    });

    tearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('records are appended to the per-day file', () async {
      final log = store();
      await log.recordAndFlush('service', 'started');
      await log.recordAndFlush('service', 'stopped');
      final file = AppEventLog.dayFile(dir, now);
      expect(await file.exists(), isTrue);
      final content = await file.readAsString();
      expect(content, contains('[service] started'));
      expect(content, contains('[service] stopped'));
      expect(content, contains('2026-11-15T10:30'));
    });

    test('sensitive content is redacted before it reaches disk', () async {
      final log = store();
      await log.recordAndFlush(
        'core',
        'setup failed for https://subs.example.com/api?token=abc123 '
        'password: hunter2 uuid 123e4567-e89b-12d3-a456-426614174000',
      );
      final content = await AppEventLog.dayFile(dir, now).readAsString();
      expect(content, isNot(contains('token=abc123')));
      expect(content, isNot(contains('hunter2')));
      expect(content, isNot(contains('123e4567-e89b-12d3-a456-426614174000')));
      // Diagnostic value survives: host and failure kind stay readable.
      expect(content, contains('subs.example.com'));
      expect(content, contains('setup failed'));
    });

    test('cleanup keeps three days and deletes older day files', () async {
      for (final day in [15, 14, 13, 12, 11]) {
        final file = File(p.join(dir.path, 'event-2026-11-$day.log'));
        await file.writeAsString('line $day\n');
      }
      await AppEventLog.cleanupExpired(dir, now);
      final remaining =
          (await dir.list().toList()).whereType<File>().map((f) => p.basename(f.path)).toList()
            ..sort();
      // Cutoff is 2026-11-12 (today minus three days): files strictly
      // older than the cutoff are deleted.
      expect(remaining, [
        'event-2026-11-12.log',
        'event-2026-11-13.log',
        'event-2026-11-14.log',
        'event-2026-11-15.log',
      ]);
    });

    test('readAllRetained concatenates retained days oldest first', () async {
      final log = store();
      await log.recordAndFlush('app', 'app started, version 1.19.8');
      now = DateTime(2026, 11, 16, 9, 0);
      await log.recordAndFlush(
        'profile-switch',
        'switch to profile p2 failed (full rebuild): boom',
      );
      final all = await log.readAllRetained();
      expect(all, contains('app started'));
      expect(all, contains('switch to profile p2 failed'));
      expect(
        all.indexOf('app started'),
        lessThan(all.indexOf('switch to profile p2 failed')),
      );
    });

    test('record on a fresh directory creates it', () async {
      final nested = Directory(p.join(dir.path, 'a', 'b'));
      final log = AppEventLog(
        directoryProvider: () async => nested,
        clock: () => now,
      );
      await log.recordAndFlush('service', 'started');
      expect(await AppEventLog.dayFile(nested, now).exists(), isTrue);
    });
  });
}
