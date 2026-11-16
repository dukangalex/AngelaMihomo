import 'dart:async';

import 'package:bett_box/clash/clash.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/proxies/common.dart';
import 'package:flutter_test/flutter_test.dart';

import 'start_auto_delay_harness.dart';

/// T155 re-entry, tap-first order: a global delay test triggered by
/// tapping the status light is already in flight when the service
/// starts — the start's automatic trigger must not launch a parallel
/// round through the shared entry.
///
/// Lives in its own file: it drives a successful `handleStart`, whose
/// preferences await only delivers inside the zone that completed the
/// completer (see the harness note).
void main() {
  testWidgets('a start during a tapped run does not start a second run', (
    tester,
  ) async {
    ensurePreferencesCompleted();
    final gate = Completer<void>();
    final handler = FakeCoreHandler(const {})..delaysGate = gate;
    ClashCore.setHandlerForTesting(handler);
    await pumpStartHarness(tester);

    // The light's tap path: one run goes in flight and stays there.
    final tappedRun = globalDelayTest();
    await tester.pump();
    expect(globalDelayTestController.isRunning, isTrue);
    expect(handler.countMethod(ActionMethod.asyncTestDelays.name), 1);

    // Starting the service now must not launch a parallel round: the
    // shared entry refuses while a run is in flight.
    await globalState.handleStart();
    await tester.pump();
    expect(handler.countMethod(ActionMethod.asyncTestDelays.name), 1);

    gate.complete();
    await tappedRun;
    await tester.pump();
    expect(globalDelayTestController.phase, GlobalDelayTestPhase.done);
    expect(handler.countMethod(ActionMethod.asyncTestDelays.name), 1);

    await shutdownAfterStart(tester);
  });
}
