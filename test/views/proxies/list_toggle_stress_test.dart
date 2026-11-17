import 'dart:math' as math;

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/controller.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/l10n/l10n.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/proxies/list.dart';
import 'package:angelamihomo/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final sticky in [true, false]) {
    testWidgets('列表模式快速连续展开收起 sticky=$sticky', (tester) async {
      final groups = [
        for (var g = 0; g < 8; g++)
          Group(
            type: GroupType.Selector,
            name: 'group$g',
            now: 'node$g-0',
            all: [
              for (var i = 0; i < (g.isEven ? 1500 : 40); i++)
                Proxy(name: 'node$g-$i', type: 'Shadowsocks'),
            ],
          ),
      ];
      globalState.appState = AppState(
        brightness: Brightness.light,
        version: 0,
        viewSize: const Size(400, 800),
        requests: FixedList(maxLength),
        logs: FixedList(maxLogLength),
        traffics: FixedList(30),
        totalTraffic: Traffic(),
        systemUiOverlayStyle: const SystemUiOverlayStyle(),
        groups: groups,
      );
      globalState.config = Config(
        themeProps: defaultThemeProps,
        currentProfileId: 'p',
        profiles: const [
          Profile(id: 'p', label: 'p', autoUpdateDuration: Duration(days: 1)),
        ],
        proxiesStyle: defaultProxiesStyle.copyWith(
          type: ProxiesType.list,
          sortType: ProxiesSortType.name,
          autoStickyHeader: sticky,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [AppLocalizations.delegate],
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  globalState.appController = AppController(context, ref);
                  globalState.measure = Measure.of(context, 1);
                  return const ProxiesListView();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final random = math.Random(3);
      for (var i = 0; i < 120; i++) {
        final buttons = find.byType(CommonExpandIcon);
        final count = buttons.evaluate().length;
        if (count == 0) {
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .jumpTo(0);
          await tester.pump();
          continue;
        }
        await tester.tap(
          buttons.at(random.nextInt(count)),
          warnIfMissed: false,
        );
        if (random.nextBool()) {
          await tester.pump(Duration(milliseconds: random.nextInt(40)));
        }
        if (random.nextInt(6) == 0) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)),
          );
          await tester.pump();
        }
        if (random.nextInt(4) == 0) {
          final position = tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position;
          position.jumpTo(random.nextDouble() * position.maxScrollExtent);
          await tester.pump(Duration(milliseconds: random.nextInt(20)));
        }
        expect(tester.takeException(), isNull, reason: 'step $i');
      }
    });
  }
}
