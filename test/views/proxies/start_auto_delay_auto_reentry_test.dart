import 'dart:async';

import 'package:angelamihomo/clash/clash.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/proxies/common.dart';
import 'package:flutter_test/flutter_test.dart';

import 'start_auto_delay_harness.dart';

/// T155 re-entry, auto-first order: the automatic run fired by a
/// successful start is still in flight when another trigger reaches
/// the shared entry (a second start path, a programmatic equivalent of
/// the light's tap) — it must be refused, leaving exactly one round.
///
/// Lives in its own file: it drives a successful `handleStart`, whose
/// preferences await only delivers inside the zone that completed the
/// completer (see the harness note).
void main() {
  testWidgets('a trigger during the automatic run stays a single run', (
    tester,
  ) async {
    ensurePreferencesCompleted();
    final gate = Completer<void>();
    final handler = FakeCoreHandler(const {})..delaysGate = gate;
    ClashCore.setHandlerForTesting(handler);
    await pumpStartHarness(tester);

    await globalState.handleStart();
    await tester.pump();

    // The automatic run is in flight…
    expect(globalDelayTestController.isRunning, isTrue);
    expect(handler.countMethod(ActionMethod.asyncTestDelays.name), 1);

    // …and another trigger through the shared entry is refused.
    await globalDelayTest();
    await tester.pump();
    expect(handler.countMethod(ActionMethod.asyncTestDelays.name), 1);

    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(globalDelayTestController.phase, GlobalDelayTestPhase.done);
    expect(handler.countMethod(ActionMethod.asyncTestDelays.name), 1);

    await shutdownAfterStart(tester);
  });
}
