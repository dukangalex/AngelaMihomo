import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// T81 C-1 regression: the hot-update channel (updateParams) used to
// send the user's literal mode. With an interception option on and
// global/direct selected, setup derives the core's run mode through
// effectiveRuntimeMode (rule + synthesized MATCH tail); any later
// patchClashConfig edit then pushed the literal mode through
// updateConfig and silently disabled the interception rules until the
// next full setup. updateParams must derive the mode exactly like
// setup does. On the pre-fix code the first test fails (mode stays
// Mode.global instead of Mode.rule).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SystemExplicitStore.instance.ensureLoaded();
  });

  setUp(() {
    globalState.appState = AppState(
      brightness: Brightness.light,
      version: 0,
      viewSize: Size.zero,
      requests: FixedList(maxLength),
      logs: FixedList(maxLogLength),
      traffics: FixedList(30),
      totalTraffic: Traffic(),
      systemUiOverlayStyle: const SystemUiOverlayStyle(),
    );
  });

  tearDown(() {
    SystemExplicitStore.instance.value = SystemExplicitOptions();
  });

  ProviderContainer containerFor(Mode mode) {
    globalState.config = Config(
      themeProps: defaultThemeProps,
      patchClashConfig: defaultClashConfig.copyWith(mode: mode),
    );
    return ProviderContainer();
  }

  test('interception on + global: hot update sends derived rule mode', () {
    SystemExplicitStore.instance.value = SystemExplicitOptions(blockAds: true);
    final container = containerFor(Mode.global);
    addTearDown(container.dispose);
    expect(container.read(updateParamsProvider).mode, Mode.rule);
  });

  test('interception on + direct: hot update sends derived rule mode', () {
    SystemExplicitStore.instance.value = SystemExplicitOptions(privacy: true);
    final container = containerFor(Mode.direct);
    addTearDown(container.dispose);
    expect(container.read(updateParamsProvider).mode, Mode.rule);
  });

  test('interception off: hot update keeps the literal mode', () {
    SystemExplicitStore.instance.value = SystemExplicitOptions();
    final container = containerFor(Mode.global);
    addTearDown(container.dispose);
    expect(container.read(updateParamsProvider).mode, Mode.global);
  });

  test('rule mode stays rule regardless of interception', () {
    SystemExplicitStore.instance.value = SystemExplicitOptions(blockAds: true);
    final container = containerFor(Mode.rule);
    addTearDown(container.dispose);
    expect(container.read(updateParamsProvider).mode, Mode.rule);
  });
}
