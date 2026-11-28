import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/l10n/l10n.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// T337 （星宫）: the theme-mode options are the mode's single
/// switch surface. Tapping dark / light / auto must write the
/// app's one existing theme-mode state — themeSettingProvider's
/// ThemeProps.themeMode, the same value MaterialApp applies —
/// and the write must land in globalState.config.themeProps,
/// the persisted source every other reader uses. No parallel
/// state may appear.
Future<ProviderContainer> _pumpOptions(
  WidgetTester tester, {
  ThemeMode initial = ThemeMode.system,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  globalState.config = Config(
    themeProps: ThemeProps(themeMode: initial),
    currentProfileId: null,
    profiles: const [],
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
        home: const Scaffold(body: ThemeModeOptions()),
      ),
    ),
  );
  await tester.pump();
  return container;
}

Finder _optionAt(int index) => find.byType(InkWell).at(index);

/// The single selected mark must sit inside the option card at
/// [index] (the mark rides the card's top-right corner, so this
/// checks horizontal containment rather than centre distance).
void _expectSelectedOn(WidgetTester tester, int index) {
  expect(find.byIcon(Icons.check_circle), findsOneWidget);
  final checkRect = tester.getRect(find.byIcon(Icons.check_circle));
  final cardRect = tester.getRect(_optionAt(index));
  expect(checkRect.center.dx, greaterThan(cardRect.left));
  expect(checkRect.center.dx, lessThan(cardRect.right));
}

void main() {
  testWidgets('three options render; auto is selected by default', (
    tester,
  ) async {
    final container = await _pumpOptions(tester);
    expect(find.byType(InkWell), findsNWidgets(3));
    expect(find.byIcon(Icons.auto_mode), findsOneWidget);
    expect(container.read(themeSettingProvider).themeMode, ThemeMode.system);
    // Exactly one selected mark, on the auto card (third).
    _expectSelectedOn(tester, 2);
  });

  testWidgets('tapping dark writes ThemeMode.dark to the shared state', (
    tester,
  ) async {
    final container = await _pumpOptions(tester);
    await tester.tap(_optionAt(0));
    await tester.pump();
    expect(container.read(themeSettingProvider).themeMode, ThemeMode.dark);
    // The persisted source moved with it — same state, not a copy.
    expect(globalState.config.themeProps.themeMode, ThemeMode.dark);
    _expectSelectedOn(tester, 0);
  });

  testWidgets('tapping light writes ThemeMode.light to the shared state', (
    tester,
  ) async {
    final container = await _pumpOptions(tester, initial: ThemeMode.dark);
    await tester.tap(_optionAt(1));
    await tester.pump();
    expect(container.read(themeSettingProvider).themeMode, ThemeMode.light);
    expect(globalState.config.themeProps.themeMode, ThemeMode.light);
  });

  testWidgets('tapping auto writes ThemeMode.system (follow system)', (
    tester,
  ) async {
    final container = await _pumpOptions(tester, initial: ThemeMode.light);
    await tester.tap(_optionAt(2));
    await tester.pump();
    expect(container.read(themeSettingProvider).themeMode, ThemeMode.system);
    expect(globalState.config.themeProps.themeMode, ThemeMode.system);
  });
}
