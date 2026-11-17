import 'dart:async';
import 'dart:convert';

import 'package:angelamihomo/clash/interface.dart';
import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/controller.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/l10n/l10n.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared harness for the T155 start-trigger tests.
///
/// Why the scenarios live in separate files: `GlobalState.handleStart`
/// awaits the app-wide preferences completer, and a future completed
/// inside one widget test's fake-async zone never delivers to listeners
/// attached in a later test's zone. Each file therefore gets a fresh
/// isolate in which the completer is completed (see
/// [ensurePreferencesCompleted]) inside the zone of the one test per
/// file that drives a successful start. Merging the files back together
/// makes every start after the first hang at that await.

/// Fake core transport: records every invoked method, answers the batch
/// delay request with canned values, and answers listener start/stop
/// like a healthy (or, when [startListenerResult] is false, a refusing)
/// core. Any selection write would show up in [methods] as a
/// `changeProxy` invocation.
class FakeCoreHandler extends ClashHandlerInterface {
  Object? channel = Object();
  final List<String> methods = [];
  final Map<String, int> cannedDelays;

  /// What the core answers to a listener start request.
  bool startListenerResult = true;

  /// When set, batch delay replies are held back until it completes,
  /// keeping a run in flight for re-entry assertions.
  Completer<void>? delaysGate;

  FakeCoreHandler(this.cannedDelays);

  int countMethod(String method) => methods.where((m) => m == method).length;

  @override
  Future<Object?> sendMessage(String message) async {
    final decoded = json.decode(message) as Map<String, dynamic>;
    final id = decoded['id'] as String;
    final method = decoded['method']?.toString() ?? '';
    methods.add(method);
    if (method == ActionMethod.asyncTestDelays.name) {
      final params = json.decode(decoded['data'] as String) as Map;
      final targets = (params['targets'] as List).cast<Map>();
      final reply = <Map<String, Object?>>[
        for (final target in targets)
          {
            'name': target['name'] as String,
            'url': target['url'] as String,
            'value': cannedDelays[target['name'] as String] ?? 100,
          },
      ];
      final gate = delaysGate;
      Future.microtask(() async {
        if (gate != null) await gate.future;
        handleResult(
          ActionResult(
            method: ActionMethod.asyncTestDelays,
            data: json.encode(reply),
            id: id,
          ),
        );
      });
    } else if (method == ActionMethod.startListener.name) {
      Future.microtask(() {
        handleResult(
          ActionResult(
            method: ActionMethod.startListener,
            data: startListenerResult,
            id: id,
          ),
        );
      });
    } else if (method == ActionMethod.stopListener.name) {
      Future.microtask(() {
        handleResult(
          ActionResult(
            method: ActionMethod.stopListener,
            data: true,
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

const entryTestUrl = 'https://example.com/204';

List<Group> fixtureGroups() {
  return const [
    Group(
      type: GroupType.Selector,
      name: '入口组',
      testUrl: entryTestUrl,
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

Future<ProviderContainer> pumpStartHarness(WidgetTester tester) async {
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
    groups: fixtureGroups(),
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

/// Completes the app-wide preferences completer with no store, in the
/// calling test's own zone (see the file-level note for why the zone
/// matters). Must run before any successful `handleStart` in the file.
void ensurePreferencesCompleted() {
  if (!preferences.sharedPreferencesCompleter.isCompleted) {
    preferences.sharedPreferencesCompleter.complete(null);
  }
}

/// Stops the service-side bookkeeping a successful start leaves behind
/// (update-task timer, run state) and drains every pending fake timer
/// (auto-dismiss, bridge watchdogs — each invoke leaves a 30.3-second
/// watchdog behind, so the drain must go past that).
Future<void> shutdownAfterStart(WidgetTester tester) async {
  await globalState.handleStop();
  await tester.pump();
  await tester.pump(const Duration(seconds: 35));
}
