import 'dart:async';

import 'package:bett_box/clash/clash.dart';
import 'package:bett_box/clash/interface.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/common/theme.dart';
import 'package:bett_box/controller.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/dashboard/widgets/node_status_light.dart';
import 'package:bett_box/views/dashboard/widgets/profile_mode.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake core transport, same shape as the T133 light suite: the merged
/// card's tall layout must never need core traffic of its own.
class _FakeHandler extends ClashHandlerInterface {
  Object? channel = Object();

  @override
  Future<Object?> sendMessage(String message) async => channel;

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
  ];
}

final _sagittariusLight = resolveZodiacTheme(
  'sagittarius',
).variant(Brightness.light);

Future<void> _pumpCard(
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
              Brightness.light,
            ),
          ],
        ),
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              globalState.appController = AppController(context, ref);
              globalState.theme = CommonTheme.of(context, 1);
              globalState.measure = Measure.of(context, 1);
              ref.watch(groupsProvider);
              ref.watch(selectedMapProvider);
              ref.watch(delayDataSourceProvider);
              return const Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 400,
                  child: ProfileModeCard(size: DashboardTileSize.tall),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Color _dotColorInCard(WidgetTester tester) {
  final finder = find.descendant(
    of: find.byType(ProfileModeCard),
    matching: find.byKey(const ValueKey('nodeStatusLightDot')),
  );
  expect(finder, findsOneWidget);
  final container = tester.widget<Container>(finder);
  return (container.decoration as BoxDecoration).color!;
}

void main() {
  testWidgets('tall merged card shows the shared light, green on usable delay', (
    tester,
  ) async {
    ClashCore.setHandlerForTesting(_FakeHandler());
    await _pumpCard(
      tester,
      runTime: 3600,
      delayMap: const {
        _entryTestUrl: {'HK-02': 42},
      },
    );
    expect(find.byType(NodeStatusLight), findsOneWidget);
    expect(_dotColorInCard(tester), _sagittariusLight.success);
  });

  testWidgets('tall merged card light is red when the current node failed', (
    tester,
  ) async {
    ClashCore.setHandlerForTesting(_FakeHandler());
    await _pumpCard(
      tester,
      runTime: 3600,
      delayMap: const {
        _entryTestUrl: {'HK-02': -1},
      },
    );
    expect(_dotColorInCard(tester), _sagittariusLight.error);
  });

  testWidgets('tall merged card light is grey when the core is stopped', (
    tester,
  ) async {
    ClashCore.setHandlerForTesting(_FakeHandler());
    await _pumpCard(
      tester,
      runTime: null,
      delayMap: const {
        _entryTestUrl: {'HK-02': 42},
      },
    );
    expect(_dotColorInCard(tester), _sagittariusLight.disabled);
  });
}
