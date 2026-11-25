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
import 'package:angelamihomo/views/dashboard/widgets/node_status_light.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake core transport, same shape as the global delay test suite:
/// records every invoked method and answers the batch delay request
/// with canned values. A selection write would show up as changeProxy.
class _FakeHandler extends ClashHandlerInterface {
  Object? channel = Object();
  final List<String> methods = [];
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
      final reply = <Map<String, Object?>>[
        for (final target in targets)
          {
            'name': target['name'],
            'url': target['url'],
            'value': cannedDelays[target['name']] ?? 100,
          },
      ];
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

final _sagittarius = resolveZodiacTheme('sagittarius').dark;

Future<ProviderContainer> _pumpLight(
  WidgetTester tester, {
  required int? runTime,
  required DelayMap delayMap,
}) async {
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
    runTime: runTime,
    delayMap: delayMap,
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
        theme: ThemeData(
          extensions: [
            ZodiacThemeExtension.of(
            resolveZodiacTheme('sagittarius'),
            Brightness.dark,
          ),
          ],
        ),
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              globalState.appController = AppController(context, ref);
              globalState.measure = Measure.of(context, 1);
              ref.watch(groupsProvider);
              ref.watch(selectedMapProvider);
              ref.watch(delayDataSourceProvider);
              return const Align(
                alignment: Alignment.topLeft,
                child: NodeStatusLight(),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

Color _dotColor(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.byKey(const ValueKey('nodeStatusLightDot')),
  );
  return (container.decoration as BoxDecoration).color!;
}

void main() {
  testWidgets('green when the current node has a usable delay', (tester) async {
    ClashCore.setHandlerForTesting(_FakeHandler(const {}));
    await _pumpLight(
      tester,
      runTime: 3600,
      delayMap: const {
        _entryTestUrl: {'HK-02': 42},
      },
    );
    expect(_dotColor(tester), _sagittarius.success);
  });

  testWidgets('red when the latest measurement of the current node failed', (
    tester,
  ) async {
    ClashCore.setHandlerForTesting(_FakeHandler(const {}));
    await _pumpLight(
      tester,
      runTime: 3600,
      delayMap: const {
        _entryTestUrl: {'HK-02': -1},
      },
    );
    expect(_dotColor(tester), _sagittarius.error);
  });

  testWidgets('grey when nothing has been measured yet', (tester) async {
    ClashCore.setHandlerForTesting(_FakeHandler(const {}));
    await _pumpLight(tester, runTime: 3600, delayMap: const {});
    expect(_dotColor(tester), _sagittarius.disabled);
  });

  testWidgets('grey when the core is stopped even with a stale delay', (
    tester,
  ) async {
    ClashCore.setHandlerForTesting(_FakeHandler(const {}));
    await _pumpLight(
      tester,
      runTime: null,
      delayMap: const {
        _entryTestUrl: {'HK-02': 42},
      },
    );
    expect(_dotColor(tester), _sagittarius.disabled);
  });

  testWidgets('tapping the light runs the global test and writes nothing', (
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
    final container = await _pumpLight(
      tester,
      runTime: 3600,
      delayMap: const {},
    );
    final selectedBefore = Map<String, String>.from(
      container.read(selectedMapProvider),
    );

    await tester.tap(find.byType(NodeStatusLight));
    await tester.pump();
    await tester.pump();

    // The tap went through the shared global test engine: exactly one
    // batch measurement, and no selection write of any kind.
    expect(handler.methods, [ActionMethod.asyncTestDelays.name]);
    expect(container.read(selectedMapProvider), selectedBefore);

    // Drain the bridge watchdog timer that every invoke leaves behind.
    await tester.pump(const Duration(seconds: 30));
  });
}
