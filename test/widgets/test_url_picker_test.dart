import 'package:bett_box/common/common.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/config/general.dart';
import 'package:bett_box/widgets/input.dart';
import 'package:bett_box/widgets/test_url_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeAppSetting extends AppSetting {
  @override
  AppSettingProps build() => const AppSettingProps();

  @override
  onUpdate(value) {}
}

class _FakeOverrideTestUrl extends OverrideTestUrl {
  @override
  bool build() => false;

  @override
  onUpdate(value) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => AppLocalizations.load(const Locale('zh', 'CN')));

  setUp(() {
    // CommonDialog watches viewSizeProvider, which reads appState.
    globalState.appState = AppState(
      brightness: Brightness.light,
      version: 0,
      viewSize: const Size(400, 800),
      requests: FixedList(maxLength),
      logs: FixedList(maxLogLength),
      traffics: FixedList(30),
      totalTraffic: Traffic(),
      systemUiOverlayStyle: const SystemUiOverlayStyle(),
    );
  });

  group('T84 preset list hygiene', () {
    test('presetTestUrls contains no Huawei endpoint', () {
      for (final url in presetTestUrls) {
        expect(url.toLowerCase(), isNot(contains('huawei')));
        expect(url.toLowerCase(), isNot(contains('hicloud')));
      }
    });

    test('presetTestUrls is the one shared list both contexts read', () {
      expect(presetTestUrls, const [
        'https://g.cn/generate_204',
        'https://www.gstatic.com/generate_204',
        'https://www.google.com/generate_204',
        'https://cp.cloudflare.com/generate_204',
        'https://www.apple.com/library/test/success.html',
      ]);
    });
  });

  Future<void> pumpPicker(
    WidgetTester tester, {
    required String currentUrl,
    required ValueChanged<String> onSelected,
    Widget? header,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: globalState.navigatorKey,
          localizationsDelegates: const [AppLocalizations.delegate],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                globalState.measure = Measure.of(context, 1);
                return ElevatedButton(
                  onPressed: () {
                    globalState.showCommonDialog(
                      child: TestUrlPickerDialog(
                        title: 'URL',
                        currentUrl: currentUrl,
                        fieldLabel: 'URL',
                        onSelected: onSelected,
                        header: header,
                      ),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(TestUrlPickerDialog), findsOneWidget);
  }

  OptionItem itemFor(WidgetTester tester, String text) =>
      tester.widget<OptionItem>(find.widgetWithText(OptionItem, text));

  group('T84 shared picker (group context shape)', () {
    testWidgets('renders every preset plus custom, with no switch', (
      tester,
    ) async {
      await pumpPicker(
        tester,
        currentUrl: presetTestUrls.first,
        onSelected: (_) {},
      );
      expect(
        find.byType(OptionItem),
        findsNWidgets(presetTestUrls.length + 1),
      );
      for (final url in presetTestUrls) {
        expect(find.widgetWithText(OptionItem, url), findsOneWidget);
      }
      // No header passed (group context): the global "override config"
      // switch must not appear.
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('echoes a preset currentUrl as the selected row', (
      tester,
    ) async {
      await pumpPicker(
        tester,
        currentUrl: presetTestUrls[1],
        onSelected: (_) {},
      );
      expect(itemFor(tester, presetTestUrls[1]).selected, isTrue);
      for (final url in presetTestUrls) {
        if (url == presetTestUrls[1]) continue;
        expect(itemFor(tester, url).selected, isFalse);
      }
      expect(
        itemFor(tester, appLocalizations.customUrl).selected,
        isFalse,
      );
    });

    testWidgets('echoes a non-preset currentUrl as the custom row', (
      tester,
    ) async {
      await pumpPicker(
        tester,
        currentUrl: 'https://example.com/healthz',
        onSelected: (_) {},
      );
      expect(itemFor(tester, appLocalizations.customUrl).selected, isTrue);
      for (final url in presetTestUrls) {
        expect(itemFor(tester, url).selected, isFalse);
      }
    });

    testWidgets('preset tap reports the selection and pops', (tester) async {
      final selections = <String>[];
      await pumpPicker(
        tester,
        currentUrl: presetTestUrls.first,
        onSelected: selections.add,
      );
      await tester.tap(find.widgetWithText(OptionItem, presetTestUrls[2]));
      await tester.pumpAndSettle();
      expect(selections, [presetTestUrls[2]]);
      expect(find.byType(TestUrlPickerDialog), findsNothing);
    });

    testWidgets('header slot renders when a caller provides one', (
      tester,
    ) async {
      await pumpPicker(
        tester,
        currentUrl: presetTestUrls.first,
        onSelected: (_) {},
        header: const Switch(value: false, onChanged: null),
      );
      expect(find.byType(Switch), findsOneWidget);
    });
  });

  group('T84 global test-url regression', () {
    testWidgets(
      'TestUrlItem opens the shared picker with the override switch and '
      'a preset tap writes the global testUrl',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appSettingProvider.overrideWith(_FakeAppSetting.new),
              overrideTestUrlProvider.overrideWith(
                _FakeOverrideTestUrl.new,
              ),
            ],
            child: MaterialApp(
              navigatorKey: globalState.navigatorKey,
              localizationsDelegates: const [AppLocalizations.delegate],
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    globalState.measure = Measure.of(context, 1);
                    return const TestUrlItem();
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(TestUrlItem)),
        );
        // Default global testUrl is the apple preset.
        expect(container.read(appSettingProvider).testUrl, defaultTestUrl);

        await tester.tap(find.text(defaultTestUrl));
        await tester.pumpAndSettle();
        expect(find.byType(TestUrlPickerDialog), findsOneWidget);
        expect(find.byType(Switch), findsOneWidget);
        // Echo: the current global URL (apple preset) is selected.
        expect(itemFor(tester, defaultTestUrl).selected, isTrue);

        await tester.tap(
          find.widgetWithText(OptionItem, presetTestUrls[1]),
        );
        await tester.pumpAndSettle();
        expect(container.read(appSettingProvider).testUrl, presetTestUrls[1]);
        expect(find.byType(TestUrlPickerDialog), findsNothing);
      },
    );
  });
}
