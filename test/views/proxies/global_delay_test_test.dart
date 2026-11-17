import 'dart:async';
import 'dart:convert';

import 'package:angelamihomo/clash/clash.dart';
import 'package:angelamihomo/clash/interface.dart';
import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/controller.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/l10n/l10n.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/proxies/common.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake core transport: records every invoked method and answers the
/// batch delay request with canned values. Any selection write would
/// show up in [methods] as a `changeProxy` invocation.
class _FakeHandler extends ClashHandlerInterface {
  Object? channel = Object();
  final List<String> methods = [];
  final List<({String name, String url})> testedTargets = [];
  final Map<String, int> cannedDelays;

  _FakeHandler(this.cannedDelays);

  @override
  Future<Object?> sendMessage(String message) async {
    final decoded = json.decode(message) as Map<String, dynamic>;
    final id = decoded['id'] as String;
    final method = decoded['method']?.toString() ?? '';
    methods.add(method);
    if (method == ActionMethod.asyncTestDelays.name) {
      final params = json.decode(decoded['data'] as String) as Map;
      final targets = (params['targets'] as List).cast<Map>();
      final reply = <Map<String, Object?>>[];
      for (final target in targets) {
        final name = target['name'] as String;
        final url = target['url'] as String;
        testedTargets.add((name: name, url: url));
        reply.add({
          'name': name,
          'url': url,
          'value': cannedDelays[name] ?? 100,
        });
      }
      Future.microtask(() {
        handleResult(
          ActionResult(
            method: ActionMethod.asyncTestDelays,
            data: json.encode(reply),
            id: id,
          ),
        );
      });
    }
    return channel;
  }

  @override
  Future<bool> preload() async => true;

  @override
  FutureOr<void> reStart() {}

  @override
  FutureOr<bool> destroy() => true;
}

const _entryTestUrl = 'https://example.com/204';

List<Group> _fixtureGroups() {
  return const [
    Group(
      type: GroupType.Selector,
      name: '入口组',
      testUrl: _entryTestUrl,
      now: 'HK-02',
      all: [
        Proxy(name: 'HK-01', type: 'Trojan'),
        Proxy(name: 'HK-02', type: 'Trojan'),
      ],
    ),
    Group(
      type: GroupType.Selector,
      name: '出口组',
      now: 'US-01',
      all: [
        Proxy(name: 'US-01', type: 'Shadowsocks'),
        Proxy(name: '入口组', type: 'Selector'),
      ],
    ),
    Group(
      type: GroupType.URLTest,
      name: '自动组',
      now: 'JP-01',
      all: [
        Proxy(name: 'JP-01', type: 'Vless'),
        Proxy(name: 'JP-02', type: 'Vless'),
        Proxy(name: 'REJECT', type: 'Reject'),
      ],
    ),
  ];
}

Future<ProviderContainer> _pumpHarness(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  globalState.appState = AppState(
    brightness: Brightness.light,
    version: 0,
    viewSize: const Size(400, 800),
    requests: FixedList(maxLength),
    logs: FixedList(maxLogLength),
    traffics: FixedList(30),
    totalTraffic: Traffic(),
    systemUiOverlayStyle: const SystemUiOverlayStyle(),
    groups: _fixtureGroups(),
  );
  globalState.config = Config(
    themeProps: defaultThemeProps,
    currentProfileId: 'p',
    profiles: const [
      Profile(
        id: 'p',
        label: 'p',
        autoUpdateDuration: Duration(days: 1),
        selectedMap: {'入口组': 'HK-02', '出口组': 'US-01'},
      ),
    ],
    proxiesStyle: defaultProxiesStyle,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              globalState.appController = AppController(context, ref);
              globalState.measure = Measure.of(context, 1);
              ref.watch(groupsProvider);
              ref.watch(selectedMapProvider);
              ref.watch(delayDataSourceProvider);
              return const SizedBox();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

Map<String, String> _groupNows(ProviderContainer container) {
  return {
    for (final group in container.read(groupsProvider))
      group.name: group.now ?? '',
  };
}

void main() {
  testWidgets('global run measures everything and never writes a selection', (
    tester,
  ) async {
    final handler = _FakeHandler({
      'HK-01': 41,
      'HK-02': 42,
      'US-01': 120,
      'JP-01': 60,
      'JP-02': -1,
    });
    ClashCore.setHandlerForTesting(handler);
    final container = await _pumpHarness(tester);

    final selectedBefore = Map<String, String>.from(
      container.read(selectedMapProvider),
    );
    final nowsBefore = _groupNows(container);
    expect(selectedBefore, {'入口组': 'HK-02', '出口组': 'US-01'});

    final controller = GlobalDelayTestController();
    await globalDelayTest(controller: controller);
    await tester.pump();

    // The only bridge traffic is the batch measurement itself: no
    // changeProxy (selection write) and no other method at all.
    expect(handler.methods, [ActionMethod.asyncTestDelays.name]);

    // Every testable proxy was measured exactly once, resolved per group:
    // the nested 入口组 member of 出口组 collapses to its selected leaf
    // HK-02 under the entry group's test URL.
    expect(handler.testedTargets.toSet(), {
      (name: 'HK-01', url: _entryTestUrl),
      (name: 'HK-02', url: _entryTestUrl),
      (name: 'US-01', url: defaultTestUrl),
      (name: 'JP-01', url: defaultTestUrl),
      (name: 'JP-02', url: defaultTestUrl),
    });

    // Snapshot comparison: selections are byte-identical after the run.
    expect(container.read(selectedMapProvider), selectedBefore);
    expect(_groupNows(container), nowsBefore);

    // Run accounting: all five measured, JP-02 reported as failed.
    expect(controller.phase, GlobalDelayTestPhase.done);
    expect(controller.total, 5);
    expect(controller.completed, 5);
    expect(controller.failed, 1);

    // Results actually landed in the shared delay state, keyed by the
    // test URL each target was measured with.
    final delayMap = container.read(delayDataSourceProvider);
    expect(delayMap[_entryTestUrl]?['HK-02'], 42);
    expect(delayMap[defaultTestUrl]?['JP-02'], -1);

    // Drain the bridge watchdog timer that every invoke leaves behind
    // (safeFuture schedules it for the full request timeout).
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('targets resolve nested groups to their selected leaf', (
    tester,
  ) async {
    ClashCore.setHandlerForTesting(_FakeHandler(const {}));
    await _pumpHarness(tester);

    final groups = globalState.appController.getCurrentGroups();
    final exitGroup = groups.getGroup('出口组')!;
    final targets = buildDelayTestTargets(
      exitGroup.all,
      testUrl: exitGroup.testUrl,
      currentGroups: groups,
    );
    expect(targets, {
      const DelayTestTarget(name: 'US-01', url: defaultTestUrl),
      const DelayTestTarget(name: 'HK-02', url: _entryTestUrl),
    });
  });

  testWidgets('result auto-dismisses after five seconds, failures included', (
    tester,
  ) async {
    ClashCore.setHandlerForTesting(_FakeHandler(const {'JP-02': -1}));
    await _pumpHarness(tester);

    final controller = GlobalDelayTestController();
    await globalDelayTest(controller: controller);
    await tester.pump();

    expect(controller.phase, GlobalDelayTestPhase.done);
    expect(controller.failed, 1);

    // Still up just before the five-second mark.
    await tester.pump(const Duration(seconds: 4));
    expect(controller.phase, GlobalDelayTestPhase.done);

    // Gone once five seconds have passed, failures notwithstanding.
    await tester.pump(const Duration(seconds: 2));
    expect(controller.phase, GlobalDelayTestPhase.idle);

    // Drain the bridge watchdog timer that every invoke leaves behind.
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('global run is rejected while a group test is running', (
    tester,
  ) async {
    final handler = _FakeHandler(const {});
    ClashCore.setHandlerForTesting(handler);
    await _pumpHarness(tester);

    final hold = Completer<void>();
    final groupRun = delayTestCoordinator.run('入口组', () => hold.future);
    await tester.pump();
    expect(delayTestCoordinator.isTesting, isTrue);

    final controller = GlobalDelayTestController();
    await globalDelayTest(controller: controller);

    expect(handler.methods, isEmpty);
    expect(controller.phase, GlobalDelayTestPhase.idle);

    hold.complete();
    await groupRun;
  });
}
