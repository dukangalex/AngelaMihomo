import 'package:bett_box/common/common.dart';
import 'package:bett_box/common/theme.dart';
import 'package:bett_box/controller.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/proxies/list.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// T134: every group header on the proxies list shows its node count —
/// the number of members in the group's `all` list, nested groups
/// counted as members, empty groups showing 0.
List<Group> _fixtureGroups() {
  return const [
    Group(
      type: GroupType.Selector,
      name: '入口组',
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
        // A nested group counts as one member, not as its own members.
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
    Group(type: GroupType.Selector, name: '空组', all: []),
  ];
}

Future<void> _pumpList(WidgetTester tester) async {
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
    delayMap: const {},
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
            ZodiacThemeExtension.of(resolveZodiacTheme('sagittarius')),
          ],
        ),
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              globalState.appController = AppController(context, ref);
              globalState.theme = CommonTheme.of(context, 1);
              globalState.measure = Measure.of(context, 1);
              return const ProxiesListView();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void _expectCount(String groupName, String text) {
  final header = find.byKey(ValueKey('header_$groupName'));
  expect(header, findsOneWidget, reason: 'header for $groupName');
  expect(
    find.descendant(of: header, matching: find.text(text)),
    findsOneWidget,
    reason: '$groupName should show "$text"',
  );
}

void main() {
  testWidgets('each group header shows its member count', (tester) async {
    await _pumpList(tester);
    _expectCount('入口组', '2 nodes');
    _expectCount('出口组', '2 nodes');
    _expectCount('自动组', '3 nodes');
    _expectCount('空组', '0 nodes');
  });
}
