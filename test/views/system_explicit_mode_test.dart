import 'dart:async';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/controller.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/system_explicit.dart';
import 'package:bett_box/widgets/list.dart';
import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLocalizations.load(const Locale('en'));
    await SystemExplicitStore.instance.ensureLoaded();
  });
  setUp(() {
    SystemExplicitStore.instance.value = SystemExplicitOptions();
    globalState.config = Config(
      themeProps: defaultThemeProps,
      patchClashConfig: defaultClashConfig.copyWith(mode: Mode.global),
    );
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
  testWidgets(
    'global mode asks before enabling a route and cancellation preserves state',
    (tester) async {
      await tester.runAsync(() async {
        // T30 class: the section's dialog is material_ui's showDialog,
        // so the pump must use the app's exact delegate list (the
        // fork's localizations only) — Flutter's MaterialApp with
        // Flutter's delegates would hide the crash the app hits.
        await tester.pumpWidget(
          ProviderScope(
            child: mui.MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...mui.GlobalMaterialLocalizations.delegates,
              ],
              locale: const Locale('en'),
              home: mui.Scaffold(
                body: generateListView([const SystemExplicitSection()]),
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 100));
      final toggle = tester.widget<mui.Switch>(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) =>
                w is ListItem &&
                w.title is Text &&
                (w.title as Text).data == 'China IPs and domains direct',
          ),
          matching: find.byType(mui.Switch),
        ),
      );
      toggle.onChanged!(true);
      await tester.pump();
      expect(SystemExplicitStore.instance.value.chinaDirect, isFalse);
      expect(find.text('Switch to rule mode?'), findsOneWidget);
      expect(globalState.config.patchClashConfig.mode, Mode.global);
      expect(
        (await SharedPreferences.getInstance()).getString('system_explicit_v1'),
        isNull,
      );
    },
  );
  testWidgets(
    'leaving rule mode shows safety warning; cancel preserves choices',
    (tester) async {
      SystemExplicitStore.instance.value = SystemExplicitOptions(
        lanDirect: true,
      );
      globalState.config = globalState.config.copyWith(
        patchClashConfig: defaultClashConfig.copyWith(mode: Mode.rule),
      );
      late AppController controller;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            // T54 defect 1: changeMode resolves its dialog context
            // from the navigator key, as the production app does
            // (application.dart) — without it the confirmation dialog
            // cannot be shown and the switch is refused.
            navigatorKey: globalState.navigatorKey,
            localizationsDelegates: mui.GlobalMaterialLocalizations.delegates,
            home: Consumer(
              builder: (context, ref, child) {
                controller = AppController(context, ref);
                return Text(
                  ref.watch(patchClashConfigProvider).mode.name,
                  textDirection: TextDirection.ltr,
                );
              },
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        unawaited(controller.changeMode(Mode.direct));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('Change routing mode?'), findsOneWidget);
      // T54 wording: leaving rule mode pauses only the direct
      // exceptions; interception options keep working.
      expect(
        find.textContaining('pauses the system explicit direct exceptions'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.pump();
      expect(find.text('rule'), findsOneWidget);
      expect(SystemExplicitStore.instance.value.lanDirect, isTrue);
    },
  );
  testWidgets('missing active profile does not report rule mode applied', (
    tester,
  ) async {
    SystemExplicitStore.instance.value = SystemExplicitOptions(lanDirect: true);
    late AppController controller;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: mui.GlobalMaterialLocalizations.delegates,
          home: Consumer(
            builder: (context, ref, child) {
              controller = AppController(context, ref);
              final mode = ref.watch(patchClashConfigProvider).mode;
              return Text(mode.name, textDirection: TextDirection.ltr);
            },
          ),
        ),
      ),
    );
    await tester.runAsync(() => controller.changeMode(Mode.rule));
    await tester.pump();
    expect(find.text('global'), findsOneWidget);
  });
  testWidgets('option descriptions stay collapsed until the chevron is tapped', (
    tester,
  ) async {
    globalState.config = globalState.config.copyWith(
      patchClashConfig: defaultClashConfig.copyWith(mode: Mode.rule),
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: Scaffold(body: generateListView([const SystemExplicitSection()]))),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(milliseconds: 100));
    const desc =
        'Uses Mihomo GEOIP/GEOSITE China rules. Replaces only same-category '
        'China IP/domain rules; unrelated rules remain.';
    expect(find.text(desc), findsNothing);
    final chevron = find.descendant(
      of: find.byWidgetPredicate(
        (w) =>
            w is ListItem &&
            w.title is Text &&
            (w.title as Text).data == 'China IPs and domains direct',
      ),
      matching: find.byIcon(Icons.expand_more),
    );
    await tester.tap(chevron);
    await tester.pump();
    expect(find.text(desc), findsOneWidget);
    await tester.tap(find.byIcon(Icons.expand_less));
    await tester.pump();
    expect(find.text(desc), findsNothing);
  });
  test('routing preferences pause and restore without mutation', () {
    // T54 semantics: outside rule mode the direct exceptions pause,
    // but the interception class (here WebRTC blocking) keeps
    // applying, terminated by a MATCH to the selected mode's target.
    final opts = SystemExplicitOptions(
      chinaDirect: true,
      blockCommonWebRtc: true,
    );
    final rule = opts.buildRuntimeRulesForMode(Mode.rule);
    expect(rule, contains('GEOIP,CN,DIRECT,no-resolve'));
    expect(rule, contains('DOMAIN-KEYWORD,stun,REJECT'));
    final global = opts.buildRuntimeRulesForMode(Mode.global);
    expect(global, contains('DOMAIN-KEYWORD,stun,REJECT'));
    expect(global.last, 'MATCH,GLOBAL');
    expect(global, isNot(contains('GEOIP,CN,DIRECT,no-resolve')));
    final direct = opts.buildRuntimeRulesForMode(Mode.direct);
    expect(direct, contains('DOMAIN-KEYWORD,stun,REJECT'));
    expect(direct.last, 'MATCH,DIRECT');
    expect(direct, isNot(contains('GEOIP,CN,DIRECT,no-resolve')));
    // Building runtime rules never mutates the stored choices, and
    // returning to rule mode restores the full set.
    expect(opts.chinaDirect, isTrue);
    expect(opts.blockCommonWebRtc, isTrue);
    expect(opts.buildRuntimeRulesForMode(Mode.rule), rule);
    final roundtrip = SystemExplicitOptions.fromJson(opts.toJson());
    expect(roundtrip.toJson(), opts.toJson());
  });
}
