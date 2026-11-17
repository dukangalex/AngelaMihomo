import 'package:angelamihomo/clash/clash.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/dashboard/widgets/node_status_light.dart';
import 'package:angelamihomo/views/proxies/common.dart';
import 'package:flutter_test/flutter_test.dart';

import 'start_auto_delay_harness.dart';

/// T155 stop side: stopping the service triggers no delay test, and
/// with the service down the status light's state mapping falls back
/// to the grey no-data state regardless of any stale delay value.
///
/// Lives in its own file: it drives a successful `handleStart`, whose
/// preferences await only delivers inside the zone that completed the
/// completer (see the harness note).
void main() {
  testWidgets('stopping triggers no test and the light falls back to grey', (
    tester,
  ) async {
    ensurePreferencesCompleted();
    final handler = FakeCoreHandler({'HK-02': 42});
    ClashCore.setHandlerForTesting(handler);
    await pumpStartHarness(tester);

    await globalState.handleStart();
    await tester.pump();
    expect(handler.countMethod(ActionMethod.asyncTestDelays.name), 1);
    expect(globalDelayTestController.phase, GlobalDelayTestPhase.done);

    await globalState.handleStop();
    await tester.pump();

    // No further measurement was issued by the stop, and the light
    // resolves to grey while the service is down.
    expect(handler.countMethod(ActionMethod.asyncTestDelays.name), 1);
    expect(
      resolveNodeLightStatus(isRunning: false, delay: 42),
      NodeLightStatus.unknown,
    );

    await tester.pump(const Duration(seconds: 35));
  });
}
