import 'dart:io';

import 'package:angelamihomo/common/event_log.dart';
import 'package:angelamihomo/common/runtime_log_store.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('RuntimeLogStore (T263)', () {
    late Directory dir;
    var now = DateTime(2026, 11, 15, 10, 30);

    Log entry(
      String payload, {
      DateTime? time,
      LogLevel level = LogLevel.info,
      LogSource source = LogSource.core,
      String? module,
    }) => Log(
      logLevel: level,
      payload: payload,
      time: time ?? now,
      source: source,
      module: module,
    );

    RuntimeLogStore store({int? maxDailyBytes}) => RuntimeLogStore(
      directoryProvider: () async => dir,
      clock: () => now,
      eventLog: AppEventLog(
        directoryProvider: () async => dir,
        clock: () => now,
      ),
      maxDailyBytes: maxDailyBytes ?? RuntimeLogStore.defaultMaxDailyBytes,
    );

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('runtime_log_test');
      now = DateTime(2026, 11, 15, 10, 30);
    });

    tearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('append then readTail round-trips every field', () async {
      final log = store();
      final t1 = DateTime(2026, 11, 15, 10, 30, 0, 123);
      final t2 = DateTime(2026, 11, 15, 10, 30, 1, 456);
      await log.appendBatch([
        entry(
          'dns query resolved',
          time: t1,
          level: LogLevel.warning,
          module: 'DNS',
        ),
        entry('app started', time: t2, source: LogSource.app),
      ]);
      final back = await log.readTail();
      expect(back, hasLength(2));
      expect(back[0].time, t1);
      expect(back[0].logLevel, LogLevel.warning);
      expect(back[0].source, LogSource.core);
      expect(back[0].module, 'DNS');
      expect(back[0].payload, 'dns query resolved');
      expect(back[1].time, t2);
      expect(back[1].source, LogSource.app);
      expect(back[1].module, isNull);
      expect(back[1].payload, 'app started');
    });

    test(
      'black box: a fresh instance reads what a killed process wrote',
      () async {
        final writer = store();
        await writer.appendBatch([
          entry('last words before the kill', time: now),
        ]);
        // No graceful close exists or is called: the writer is simply
        // abandoned, like a process that was killed. A brand-new
        // instance must still read the batch back, because every
        // append is flushed to disk.
        final reader = store();
        final back = await reader.readTail();
        expect(back.map((log) => log.payload), [
          'last words before the kill',
        ]);
      },
    );

    test('entries land in per-day runtime- files spanning midnight', () async {
      final log = store();
      now = DateTime(2026, 11, 15, 23, 59);
      await log.appendBatch([entry('before midnight', time: now)]);
      now = DateTime(2026, 11, 16, 0, 1);
      await log.appendBatch([entry('after midnight', time: now)]);
      expect(
        await File(p.join(dir.path, 'runtime-2026-11-15.log')).exists(),
        isTrue,
      );
      expect(
        await File(p.join(dir.path, 'runtime-2026-11-16.log')).exists(),
        isTrue,
      );
      final back = await log.readTail();
      expect(back.map((log) => log.payload), [
        'before midnight',
        'after midnight',
      ]);
    });

    test('cleanup keeps three days and never touches event- files', () async {
      for (final day in [15, 14, 13, 12, 11]) {
        await File(
          p.join(dir.path, 'runtime-2026-11-$day.log'),
        ).writeAsString('line $day\n');
      }
      final eventFile = File(p.join(dir.path, 'event-2026-11-11.log'));
      await eventFile.writeAsString('event line\n');
      await RuntimeLogStore.cleanupExpired(dir, now);
      final remaining =
          (await dir.list().toList()).whereType<File>()
              .map((f) => p.basename(f.path))
              .toList()
            ..sort();
      expect(remaining, [
        'event-2026-11-11.log',
        'runtime-2026-11-12.log',
        'runtime-2026-11-13.log',
        'runtime-2026-11-14.log',
        'runtime-2026-11-15.log',
      ]);
    });

    test('readTail stays inside the retention window', () async {
      final old = RuntimeLogStore.dayFile(dir, DateTime(2026, 11, 11));
      await old.writeAsString(
        '${RuntimeLogStore.formatLine(entry('too old', time: DateTime(2026, 11, 11)))}\n',
      );
      final log = store();
      await log.appendBatch([entry('fresh', time: now)]);
      final back = await log.readTail();
      expect(back.map((log) => log.payload), ['fresh']);
    });

    test('readTail returns at most maxLines, newest kept, in order', () async {
      final log = store();
      await log.appendBatch([
        for (var i = 0; i < 10; i++)
          entry('line-$i', time: now.add(Duration(seconds: i))),
      ]);
      final back = await log.readTail(maxLines: 3);
      expect(back.map((log) => log.payload), ['line-7', 'line-8', 'line-9']);
    });

    test('payload newlines and tabs are flattened to one line', () async {
      final log = store();
      await log.appendBatch([entry('a\nb\tc', time: now)]);
      final content = await RuntimeLogStore.dayFile(dir, now).readAsString();
      expect(content.trim().split('\n'), hasLength(1));
      final back = await log.readTail();
      expect(back.single.payload, 'a b c');
    });

    test('bad lines are skipped and unknown enums fall back', () async {
      final file = RuntimeLogStore.dayFile(dir, now);
      final good = entry('good', time: now);
      final odd = entry('odd level', time: now);
      await file.writeAsString(
        'not a log line\n'
        'not-a-time\tinfo\tcore\t\tbad time\n'
        '${RuntimeLogStore.formatLine(odd).replaceFirst('\tinfo\t', '\tverbose\t')}\n'
        '${RuntimeLogStore.formatLine(good)}\n',
      );
      final back = await store().readTail();
      expect(back, hasLength(2));
      expect(back[0].payload, 'odd level');
      expect(back[0].logLevel, LogLevel.error);
      expect(back[1].payload, 'good');
    });

    test(
      'daily cap stops appending, records one event, resets next day',
      () async {
        final log = store(maxDailyBytes: 400);
        final file = RuntimeLogStore.dayFile(dir, now);
        var lastSize = -1;
        var plateaued = false;
        for (var i = 0; i < 20; i++) {
          await log.appendBatch([
            entry('padding entry number $i with some text', time: now),
          ]);
          final size = await file.length();
          if (size == lastSize) plateaued = true;
          lastSize = size;
        }
        expect(plateaued, isTrue, reason: 'appends must stop at the cap');
        expect(lastSize, lessThanOrEqualTo(400));

        // The truncation event is recorded fire-and-forget; wait for
        // it to land, then confirm it stayed exactly one.
        final eventFile = AppEventLog.dayFile(dir, now);
        var eventContent = '';
        for (var i = 0; i < 40; i++) {
          if (await eventFile.exists()) {
            eventContent = await eventFile.readAsString();
            if (eventContent.contains('daily cap')) break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        expect(eventContent, contains('[log]'));
        expect('daily cap'.allMatches(eventContent), hasLength(1));

        // Next day the store writes again, into the new day file.
        now = DateTime(2026, 11, 16, 9, 0);
        await log.appendBatch([entry('next day', time: now)]);
        final back = await log.readTail();
        expect(back.last.payload, 'next day');
      },
    );

    test('clear deletes every runtime day file', () async {
      final log = store();
      await log.appendBatch([entry('one', time: now)]);
      now = DateTime(2026, 11, 16, 9, 0);
      await log.appendBatch([entry('two', time: now)]);
      await log.clear();
      final remaining = (await dir.list().toList()).whereType<File>().toList();
      expect(remaining, isEmpty);
      expect(await log.readTail(), isEmpty);
    });

    test('readAllRetained returns every day, oldest first', () async {
      final log = store();
      await log.appendBatch([entry('day one', time: now)]);
      now = DateTime(2026, 11, 16, 9, 0);
      await log.appendBatch([entry('day two', time: now)]);
      final all = await log.readAllRetained();
      expect(all, contains('day one'));
      expect(all, contains('day two'));
      expect(all.indexOf('day one'), lessThan(all.indexOf('day two')));
      expect(all, isNot(contains('omitted')));
    });

    test('readAllRetained byte cap keeps the newest and marks it', () async {
      final log = store();
      await log.appendBatch([
        for (var i = 0; i < 20; i++) entry('line number $i', time: now),
      ]);
      final all = await log.readAllRetained(maxBytes: 200);
      expect(all, startsWith('(export size cap:'));
      expect(all, contains('line number 19'));
      expect(all, isNot(contains('\tline number 0\n')));
    });

    test('readAllRetained on a missing directory is empty', () async {
      final missing = RuntimeLogStore(
        directoryProvider: () async =>
            Directory(p.join(dir.path, 'does-not-exist')),
        clock: () => now,
        eventLog: AppEventLog(
          directoryProvider: () async => dir,
          clock: () => now,
        ),
      );
      expect(await missing.readAllRetained(), '');
    });
  });
}
