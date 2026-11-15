import 'package:bett_box/common/common.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/config/dns.dart';
import 'package:bett_box/widgets/list.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// T154: a switch that is on must read as lit at a glance (user
/// decision 2026-11-15). The app has exactly one switch styling
/// source — [zodiacSwitchTheme], wired into the app theme — and its
/// on state carries the variant's selected gradient by its two
/// endpoints: track = gradient start (the selected paint's first
/// color), thumb = gradient end (last stop, or the secondary for
/// solid themes). The off state keeps the neutral scheme tones, and
/// a disabled switch resolves to the framework's muted rendering
/// instead of the lit colors. These tests assert the colors a switch
/// actually resolves under real pumped themes, for every theme of
/// the family at resolver level and for three of them through the
/// widget tree, plus a real settings page toggle regression.
void main() {
  ThemeData themeFor(ZodiacThemeDef def) {
    final scheme = def.variant.toColorScheme();
    return ThemeData(
      colorScheme: scheme,
      extensions: [ZodiacThemeExtension.of(def)],
      switchTheme: zodiacSwitchTheme(scheme, def.variant),
    );
  }

  Color? resolve(
    SwitchThemeData theme,
    bool thumb,
    Set<WidgetState> states,
  ) {
    final property = thumb ? theme.thumbColor : theme.trackColor;
    return property?.resolve(states);
  }

  void expectLit(SwitchThemeData theme, ZodiacVariant variant) {
    final onTrack = resolve(theme, false, {WidgetState.selected});
    final onThumb = resolve(theme, true, {WidgetState.selected});
    final offTrack = resolve(theme, false, <WidgetState>{});
    final offThumb = resolve(theme, true, <WidgetState>{});
    // The lit pair is the selected gradient's two endpoints, taken
    // from the variant's own tokens at full saturation. The track
    // follows the selected token itself, not the primary: the two
    // agree for most themes, but the paper skeletons (cancer, virgo)
    // give selected a pale reversal face by design (DESIGN 4.4).
    expect(onTrack, variant.selected.firstColor);
    expect(onTrack!.a, 1.0);
    expect(
      onThumb,
      variant.selected.isGradient
          ? variant.selected.stops!.last
          : variant.secondary,
    );
    // On and off must be unmistakably different on both parts.
    expect(onTrack, isNot(offTrack));
    expect(onThumb, isNot(offThumb));
    // A disabled switch never wears the lit colors: the theme hands
    // the state back to the framework's muted disabled rendering.
    final disabledTrack = resolve(theme, false, {
      WidgetState.selected,
      WidgetState.disabled,
    });
    final disabledThumb = resolve(theme, true, {
      WidgetState.selected,
      WidgetState.disabled,
    });
    expect(disabledTrack, isNot(onTrack));
    expect(disabledThumb, isNot(onThumb));
    expect(disabledTrack, isNull);
    expect(disabledThumb, isNull);
  }

  for (final id in ['sagittarius', 'taurus', 'cancer']) {
    testWidgets('pumped switch resolves lit under $id', (tester) async {
      final def = resolveZodiacTheme(id);
      await tester.pumpWidget(
        MaterialApp(
          theme: themeFor(def),
          home: Scaffold(
            body: Column(
              children: [
                Switch(value: true, onChanged: (_) {}),
                Switch(value: false, onChanged: (_) {}),
                const Switch(value: true, onChanged: null),
              ],
            ),
          ),
        ),
      );
      final context = tester.element(find.byType(Switch).first);
      final theme = Theme.of(context).switchTheme;
      expectLit(theme, def.variant);
      // The pumped switches carry the states the resolver was fed:
      // on, off, and disabled-on are all present in the tree.
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.map((s) => s.value), [true, false, true]);
      expect(switches.last.onChanged, isNull);
    });
  }

  test('all twelve themes resolve lit from their own tokens', () {
    expect(zodiacThemes, hasLength(12));
    for (final def in zodiacThemes) {
      final scheme = def.variant.toColorScheme();
      expectLit(zodiacSwitchTheme(scheme, def.variant), def.variant);
    }
  });

  test('no-zodiac fallback keeps the previous scheme colors', () {
    final scheme = resolveZodiacTheme('sagittarius').variant.toColorScheme();
    final theme = zodiacSwitchTheme(scheme, null);
    expect(
      resolve(theme, false, {WidgetState.selected}),
      scheme.primary,
    );
    expect(resolve(theme, true, {WidgetState.selected}), scheme.onPrimary);
  });

  group('DNS settings page toggle regression', () {
    setUpAll(() async {
      await AppLocalizations.load(const Locale('zh', 'CN'));
    });

    setUp(() {
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
      globalState.config = Config(themeProps: defaultThemeProps);
    });

    testWidgets('覆写 DNS switch flips on tap under the lit theme', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final def = resolveZodiacTheme('sagittarius');
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: themeFor(def),
            home: const Scaffold(body: DnsListView()),
          ),
        ),
      );
      await tester.pump();
      final row = find.byWidgetPredicate(
        (w) =>
            w is ListItem &&
            w.title is Text &&
            (w.title as Text).data == '覆写 DNS',
      );
      final switchFinder = find.descendant(
        of: row,
        matching: find.byType(Switch),
      );
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isFalse);
      await tester.tap(switchFinder);
      await tester.pump();
      // The tap fired the row's callback and the provider-backed
      // value flipped, so the switch now renders in its lit state.
      expect(tester.widget<Switch>(switchFinder).value, isTrue);
      await tester.tap(switchFinder);
      await tester.pump();
      expect(tester.widget<Switch>(switchFinder).value, isFalse);
    });
  });
}
