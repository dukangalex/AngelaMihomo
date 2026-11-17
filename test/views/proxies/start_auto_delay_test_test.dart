import 'package:angelamihomo/clash/clash.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/proxies/common.dart';
import 'package:flutter_test/flutter_test.dart';

import 'start_auto_delay_harness.dart';

/// T155: a successful service start automatically runs the shared
/// global linked delay test exactly once, so the status light shows a
/// measured state without a manual tap; a failed start runs nothing.
///
/// The two scenarios share one file deliberately: the first completes
/// the preferences completer in its own zone (see the harness note),
/// and the second never reaches that await — its start is refused at
/// the listener, before preferences are touched.
void main() {
  testWidgets('successful start triggers exactly one global delay test', (
    tester,
  ) async {
    ensurePreferencesCompleted();
    final handler = FakeCoreHandler({'HK-02': 42, 'JP-02': -1});
    ClashCore.setHandlerForTesting(handler);
    final container = await pumpStartHarness(tester);

    final selectedBefore = Map<String, String>.from(
      container.read(selectedMapProvider),
    );

    await globalState.handleStart();
    await tester.pump();

    // The start went through, and the automatic run is the only delay
    // traffic: exactly one batch measurement, no selection write.
    expect(handler.methods.first, ActionMethod.startListener.name);
    expect(
      handler.countMethod(ActionMethod.asyncTestDelays.name),
      1,
      reason: 'one start must trigger exactly one global test',
    );
    expect(
      handler.methods,
      isNot(contains(ActionMethod.changeProxy.name)),
      reason: 'the automatic run measures only, it never selects',
    );
    expect(container.read(selectedMapProvider), selectedBefore);

    // The run completed through the shared controller the light reads,
    // and its results landed in the shared delay data source.
    expect(globalDelayTestController.phase, GlobalDelayTestPhase.done);
    expect(globalDelayTestController.total, 5);
    expect(globalDelayTestController.failed, 1);
    final delayMap = container.read(delayDataSourceProvider);
    expect(delayMap[entryTestUrl]?['HK-02'], 42);

    await shutdownAfterStart(tester);
  });

  testWidgets('failed start triggers no delay test', (tester) async {
    final handler = FakeCoreHandler(const {})..startListenerResult = false;
    ClashCore.setHandlerForTesting(handler);
    await pumpStartHarness(tester);

    await expectLater(globalState.handleStart(), throwsStateError);
    await tester.pump();

    expect(handler.countMethod(ActionMethod.asyncTestDelays.name), 0);
    expect(globalDelayTestController.isRunning, isFalse);
    expect(globalState.startTime, isNull);

    await tester.pump(const Duration(seconds: 35));
  });
}
