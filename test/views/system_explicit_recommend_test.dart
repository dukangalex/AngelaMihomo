import 'dart:convert';

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/l10n/l10n.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/system_explicit.dart';
import 'package:angelamihomo/widgets/list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// T141 (T57 carryback): the China adaptation group's recommended
/// combination is a pure action — it turns the three interception
/// options on, never touches the other switches, and persists through
/// the same store as the switches themselves.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLocalizations.load(const Locale('en'));
    await SystemExplicitStore.instance.ensureLoaded();
  });
  setUp(() {
    // One direct exception already on: the action must not reset it.
    SystemExplicitStore.instance.value = SystemExplicitOptions(
      chinaDirect: true,
    );
    globalState.config = Config(
      themeProps: defaultThemeProps,
      patchClashConfig: defaultClashConfig.copyWith(mode: Mode.rule),
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
    'group is titled China adaptation and the action turns on only the interception three',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: generateListView([const SystemExplicitSection()]),
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('China adaptation'), findsOneWidget);
      expect(find.text('Recommended combination'), findsOneWidget);

      // Collapsed: no button yet. Expand the row first.
      expect(find.text('Turn on recommended'), findsNothing);
      await tester.tap(find.text('Recommended combination'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Turn on recommended'), findsOneWidget);

      await tester.tap(find.text('Turn on recommended'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );

      final value = SystemExplicitStore.instance.value;
      expect(value.privacy, isTrue);
      expect(value.blockCommonWebRtc, isTrue);
      expect(value.blockAds, isTrue);
      // Untouched: the pre-existing direct exception stays on, the
      // other two stay off — the action writes nothing else.
      expect(value.chinaDirect, isTrue);
      expect(value.chinaPublicDnsDirect, isFalse);
      expect(value.lanDirect, isFalse);

      final raw = (await SharedPreferences.getInstance()).getString(
        'system_explicit_v1',
      );
      expect(raw, isNotNull);
      final saved = jsonDecode(raw!) as Map<String, dynamic>;
      expect(saved['privacy'], isTrue);
      expect(saved['blockCommonWebRtc'], isTrue);
      expect(saved['blockAds'], isTrue);
      expect(saved['chinaDirect'], isTrue);
    },
  );
}
