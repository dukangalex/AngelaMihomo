import 'dart:async';
import 'dart:convert';

import 'package:angelamihomo/clash/clash.dart';
import 'package:angelamihomo/clash/interface.dart';
import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/common/theme.dart';
import 'package:angelamihomo/controller.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/l10n/l10n.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/dashboard/widgets/node_status_light.dart';
import 'package:angelamihomo/views/dashboard/widgets/profile_mode.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Recording fake core transport (same shape as the T133 suite):
/// a selection write would show up as changeProxy, a delay test as
/// asyncTestDelays.
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
  ];
}

final _sagittarius = resolveZodiacTheme('sagittarius').dark;

Future<ProviderContainer> _pumpCard(
  WidgetTester tester, {
  required DelayMap delayMap,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  globalState.appState = AppState(
    brightness: Brightness.light,
    version: 0,
    viewSize: const Size(800, 600),
    requests: FixedList(maxLength),
    logs: FixedList(maxLogLength),
    traffics: FixedList(30),
    totalTraffic: Traffic(),
    systemUiOverlayStyle: const SystemUiOverlayStyle(),
    groups: _fixtureGroups(),
    runTime: 3600,
    delayMap: delayMap,
  );
  globalState.config = Config(
    themeProps: defaultThemeProps,
    currentProfileId: 'p',
    patchClashConfig: defaultClashConfig.copyWith(mode: Mode.rule),
    profiles: const [
      Profile(
        id: 'p',
        label: '测试配置',
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
              globalState.theme = CommonTheme.of(context, 1);
              globalState.measure = Measure.of(context, 1);
              ref.watch(groupsProvider);
              ref.watch(selectedMapProvider);
              ref.watch(delayDataSourceProvider);
              return const Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: 800, child: ProfileModeCard()),
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

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SystemExplicitStore.instance.ensureLoaded();
  });

  testWidgets(
    'merged card keeps both zones: profile info above, light, chips and modes below',
    (tester) async {
      ClashCore.setHandlerForTesting(_FakeHandler(const {}));
      await _pumpCard(
        tester,
        delayMap: const {
          _entryTestUrl: {'HK-02': 42},
        },
      );
      // Profile zone.
      expect(find.text('测试配置'), findsOneWidget);
      expect(find.text('HK-02'), findsOneWidget);
      // The current selection's delay number, from the shared source.
      expect(find.text('42 ms'), findsOneWidget);
      // Mode zone: exactly one light, the chips and the three modes.
      expect(find.byType(NodeStatusLight), findsOneWidget);
      expect(find.text('System Proxy'), findsOneWidget);
      expect(find.text('Rule'), findsOneWidget);
      expect(find.text('Global'), findsOneWidget);
      expect(find.text('Direct'), findsOneWidget);
      // The light agrees with the number: same source, usable delay.
      final dot = tester.widget<Container>(
        find.byKey(const ValueKey('nodeStatusLightDot')),
      );
      expect((dot.decoration as BoxDecoration).color, _sagittarius.success);
      // No second speed-test trigger anywhere in the card.
      expect(find.byIcon(Icons.network_ping), findsNothing);
      // T292 (supersedes the T149 placement call at the user's direct
      // instruction): the card's leading icon IS the update-current-
      // profile button — exactly one, wearing the Update tooltip.
      // T301 dresses it as a zodiac astrolabe wheel
      // (ZodiacWheelUpdateIcon; the glyph ring and the compass star
      // counter-turn while an update runs). It is a refresh entry,
      // not a test entry: the light above stays the card's only
      // speed-test trigger.
      expect(find.byType(ZodiacWheelUpdateIcon), findsOneWidget);
      expect(find.byTooltip('Update'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping the light runs the global linked test once and writes no selection',
    (tester) async {
      final handler = _FakeHandler(const {'HK-02': 42});
      ClashCore.setHandlerForTesting(handler);
      final container = await _pumpCard(tester, delayMap: const {});
      final before = container.read(selectedMapProvider);
      await tester.tap(find.byType(NodeStatusLight));
      await tester.pump();
      await tester.pump();
      expect(handler.methods, [ActionMethod.asyncTestDelays.name]);
      expect(container.read(selectedMapProvider), before);

      // Drain the bridge watchdog timer that every invoke leaves behind.
      await tester.pump(const Duration(seconds: 30));
    },
  );

  testWidgets(
    'tapping a mode button switches the mode through the controller',
    (tester) async {
      ClashCore.setHandlerForTesting(_FakeHandler(const {}));
      final container = await _pumpCard(
        tester,
        delayMap: const {
          _entryTestUrl: {'HK-02': 42},
        },
      );
      expect(container.read(patchClashConfigProvider).mode, Mode.rule);
      await tester.tap(find.text('Global'));
      // changeMode awaits store/platform futures that only settle in the
      // real async zone (same pattern as the system-explicit suite).
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      expect(container.read(patchClashConfigProvider).mode, Mode.global);

      // Drain the bridge watchdog timer that every invoke leaves behind.
      await tester.pump(const Duration(seconds: 30));
    },
  );
}
