import 'package:bett_box/common/common.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deep space series data (T181)', () {
    test('fifteen events, unique ids, chronological years', () {
      expect(deepSpaceThemeDefs, hasLength(15));
      final ids = deepSpaceThemeDefs.map((d) => d.id).toSet();
      expect(ids, hasLength(15));
      final zodiacIds = zodiacThemes.map((d) => d.id).toSet();
      expect(ids.intersection(zodiacIds), isEmpty);
      final years = deepSpaceThemeDefs.map((d) => int.parse(d.year)).toList();
      final sorted = [...years]..sort();
      expect(years, sorted);
      for (final def in deepSpaceThemeDefs) {
        expect(def.nameZh, isNotEmpty, reason: def.id);
        expect(def.nameEn, isNotEmpty, reason: def.id);
      }
    });

    test('every motif kind is used exactly once', () {
      final used = deepSpaceThemeDefs.map((d) => d.motif).toSet();
      expect(used, DeepSpaceMotif.values.toSet());
    });
  });

  group('theme registry (T180)', () {
    test('deep-space ids resolve to their own palette and motif', () {
      final sel = resolveAppTheme('apollo11');
      expect(sel.isDeepSpace, isTrue);
      expect(sel.motif, DeepSpaceMotif.moonLanding);
      expect(sel.variant, deepSpaceThemeById('apollo11')!.variant);
    });

    test('zodiac ids and unknown ids stay on the constellation series', () {
      final aries = resolveAppTheme('aries');
      expect(aries.isDeepSpace, isFalse);
      expect(aries.motif, isNull);
      final unknown = resolveAppTheme('not-a-theme');
      expect(unknown.id, zodiacDefaultThemeId);
      expect(unknown.isDeepSpace, isFalse);
      expect(resolveAppTheme(null).id, zodiacDefaultThemeId);
    });

    test('glyphs: sign for zodiac, star for deep space', () {
      expect(themeGlyphFor('aries'), '♈');
      expect(themeGlyphFor('apollo11'), '✦');
    });
  });

  testWidgets('backdrop paints the event motif, no guardian', (tester) async {
    final theme = ThemeData(
      extensions: [resolveAppTheme('cassini').toExtension()],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: ZodiacBackdrop()),
      ),
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(ZodiacBackdrop),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );
    expect(find.byType(Image), findsNothing);
    expect(find.byType(ZodiacGuardianPlate), findsNothing);
  });

  group('withdrawn series fall back safely (T190/T192)', () {
    test('withdrawn gold and solar ids fall back to the default theme', () {
      // The golden-saint and solar-system series were withdrawn on
      // 2026-11-17; a device still holding one of their ids must
      // land on the default theme, never on a dead selection.
      for (final id in ['gold-leo', 'sol-earth']) {
        final fallen = resolveAppTheme(id);
        expect(fallen.series, ThemeSeries.zodiac, reason: id);
        expect(fallen.id, zodiacDefaultThemeId, reason: id);
      }
    });
  });

  testWidgets('deep-space backdrop carries the event name plate (T191)', (
    tester,
  ) async {
    final theme = ThemeData(
      extensions: [resolveAppTheme('apollo11').toExtension()],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: ZodiacBackdrop()),
      ),
    );
    await tester.pump();
    expect(find.byType(DeepSpacePlate), findsOneWidget);
    expect(find.text('阿波罗11号'), findsOneWidget);
    expect(find.text('APOLLO 11 · 1969'), findsOneWidget);
    expect(find.byType(ZodiacGuardianPlate), findsNothing);
  });

}
