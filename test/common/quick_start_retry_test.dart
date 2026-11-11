import 'package:bett_box/common/quick_start_retry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('runQuickStartWithRetry', () {
    test('succeeds on the first attempt without sleeping', () async {
      final sleeps = <Duration>[];
      var calls = 0;
      final ok = await runQuickStartWithRetry(
        () async {
          calls++;
          return true;
        },
        sleeper: (d) async => sleeps.add(d),
      );
      expect(ok, isTrue);
      expect(calls, 1);
      expect(sleeps, isEmpty);
    });

    test('retries reported failures with growing delays, then succeeds',
        () async {
      final sleeps = <Duration>[];
      var calls = 0;
      final ok = await runQuickStartWithRetry(
        () async {
          calls++;
          return calls >= 3;
        },
        sleeper: (d) async => sleeps.add(d),
      );
      expect(ok, isTrue);
      expect(calls, 3);
      expect(sleeps, quickStartRetryDelays);
    });

    test('treats thrown errors as failures and cleans up per attempt',
        () async {
      final failures = <Object>[];
      var calls = 0;
      final ok = await runQuickStartWithRetry(
        () async {
          calls++;
          throw StateError('boom $calls');
        },
        sleeper: (d) async {},
        onFailure: (e) async => failures.add(e),
      );
      expect(ok, isFalse);
      expect(calls, quickStartRetryDelays.length + 1);
      expect(failures, hasLength(calls));
    });

    test('a throwing cleanup hook does not mask the outcome', () async {
      var calls = 0;
      final ok = await runQuickStartWithRetry(
        () async {
          calls++;
          return calls == 2;
        },
        sleeper: (d) async {},
        onFailure: (e) async => throw StateError('cleanup failed'),
      );
      expect(ok, isTrue);
      expect(calls, 2);
    });
  });

  group('QuickStartFailureMarker', () {
    test('round-trips through encode/tryParse', () {
      const marker = QuickStartFailureMarker(
        time: '2026-11-11T00:00:00.000Z',
        step: 'quickStart',
        error: 'some core message',
        attempts: 3,
      );
      final parsed = QuickStartFailureMarker.tryParse(marker.encode());
      expect(parsed, isNotNull);
      expect(parsed!.time, marker.time);
      expect(parsed.step, 'quickStart');
      expect(parsed.error, 'some core message');
      expect(parsed.attempts, 3);
      expect(parsed.toString(), contains('step=quickStart'));
    });

    test('rejects null, empty, and malformed payloads', () {
      expect(QuickStartFailureMarker.tryParse(null), isNull);
      expect(QuickStartFailureMarker.tryParse(''), isNull);
      expect(QuickStartFailureMarker.tryParse('not json'), isNull);
      expect(QuickStartFailureMarker.tryParse('[]'), isNull);
      expect(QuickStartFailureMarker.tryParse('{"time":1}'), isNull);
    });
  });
}
