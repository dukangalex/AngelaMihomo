import 'package:bett_box/views/patrol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PatrolConfigCheckScheduler', () {
    test('starts when idle and reports running until finished', () {
      final scheduler = PatrolConfigCheckScheduler();
      expect(scheduler.isRunning, isFalse);
      expect(scheduler.tryStart(), isTrue);
      expect(scheduler.isRunning, isTrue);
      expect(scheduler.finish(), isFalse);
      expect(scheduler.isRunning, isFalse);
    });

    test('a request during a run collapses into one follow-up run', () {
      final scheduler = PatrolConfigCheckScheduler();
      expect(scheduler.tryStart(), isTrue);
      // No parallel re-entry while a check is running.
      expect(scheduler.tryStart(), isFalse);
      expect(scheduler.isRunning, isTrue);
      // Finishing reports exactly one requested follow-up.
      expect(scheduler.finish(), isTrue);
      expect(scheduler.tryStart(), isTrue);
      expect(scheduler.finish(), isFalse);
    });

    test('repeated requests during a run still yield a single rerun', () {
      final scheduler = PatrolConfigCheckScheduler();
      expect(scheduler.tryStart(), isTrue);
      expect(scheduler.tryStart(), isFalse);
      expect(scheduler.tryStart(), isFalse);
      expect(scheduler.tryStart(), isFalse);
      expect(scheduler.finish(), isTrue);
      // The follow-up run starts clean: no rerun is left over.
      expect(scheduler.tryStart(), isTrue);
      expect(scheduler.finish(), isFalse);
    });
  });
}
