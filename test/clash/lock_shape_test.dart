import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:synchronized/synchronized.dart';

// T127 root cause and regression coverage.
//
// The profile switch failed on some profiles with:
//   Bad state: This can happen if an inner synchronized block is spawned
//   outside the block it was started from. Make sure the inner
//   synchronized blocks are properly awaited
// That StateError comes from ReentrantLock (package:synchronized): it
// tracks nesting through Zones, so any lock-taking call that executes
// in a zone captured inside an earlier, already-exited block (a delayed
// callback, a reused captured zone) throws instead of queueing. The
// controller's _coreLifecycleLock therefore uses a plain Lock, and
// nesting is expressed by calling lock-held bodies directly. These
// tests pin both halves of that decision.
void main() {
  group('root cause: reentrant lock zone tracking', () {
    test('delayed callback created inside a block throws on re-entry',
        () async {
      final lock = Lock(reentrant: true);
      Object? callbackError;
      await lock.synchronized(() async {
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 30))
              .then((_) => lock.synchronized(() async {}))
              .then<void>(
                (_) {},
                onError: (Object e) => callbackError = e,
              ),
        );
        return 'outer';
      });
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(callbackError, isA<StateError>());
      expect(
        (callbackError as StateError).message,
        contains('spawned outside the block it was started from'),
      );
    });

    test('zone captured inside a nested block throws when reused later',
        () async {
      final lock = Lock(reentrant: true);
      late Zone captured;
      await lock.synchronized(() async {
        await lock.synchronized(() async {
          captured = Zone.current;
        });
        return 'outer';
      });
      Object? error;
      unawaited(
        captured
            .run(() => lock.synchronized(() async {}))
            .then<void>((_) {}, onError: (Object e) => error = e),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(error, isA<StateError>());
    });
  });

  group('controller pattern: plain lock with lock-held bodies', () {
    test('delayed callback created inside a block queues and runs',
        () async {
      final lock = Lock();
      var callbackRan = false;
      await lock.synchronized(() async {
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 30)).then(
            (_) => lock.synchronized(() async => callbackRan = true),
          ),
        );
        return 'outer';
      });
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(callbackRan, isTrue);
    });

    test('zone captured inside a block can re-enter afterwards', () async {
      final lock = Lock();
      late Zone captured;
      await lock.synchronized(() async {
        captured = Zone.current;
        return 'outer';
      });
      var ran = false;
      await captured.run(() => lock.synchronized(() async => ran = true));
      expect(ran, isTrue);
    });

    test('lock-held bodies compose; external calls serialize', () async {
      final lock = Lock();
      final order = <String>[];

      Future<void> body() async {
        order.add('body-start');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        order.add('body-end');
      }

      final first = lock.synchronized(() async {
        await body();
        order.add('first-done');
      });
      final second = lock.synchronized(() async {
        order.add('second');
      });
      await Future.wait([first, second]);
      expect(order, ['body-start', 'body-end', 'first-done', 'second']);
    });
  });
}
