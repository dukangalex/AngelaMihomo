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

  group('golden saints series (T184)', () {
    test('golden saints: twelve, mirroring valid zodiac ids', () {
      expect(goldSaintThemeDefs, hasLength(12));
      final ids = goldSaintThemeDefs.map((d) => d.id).toSet();
      expect(ids, hasLength(12));
      final zodiacIds = zodiacThemes.map((d) => d.id).toSet();
      expect(ids.intersection(zodiacIds), isEmpty);
      for (final def in goldSaintThemeDefs) {
        expect(zodiacIds, contains(def.zodiacId), reason: def.id);
        expect(def.nameZh, contains('·'), reason: def.id);
      }
    });

    test('registry resolves gold selections', () {
      final gold = resolveAppTheme('gold-leo');
      expect(gold.series, ThemeSeries.goldSaint);
      expect(gold.variant, goldSaintThemeById('gold-leo')!.variant);
      expect(gold.constellation, resolveZodiacTheme('leo').constellation);
      expect(gold.showGuardian, isFalse);
      expect(themeGlyphFor('gold-leo'), '♌');
    });

    test('withdrawn solar-system ids fall back to the default theme', () {
      // The solar-system series was withdrawn on 2026-11-17; a device
      // still holding one of its ids must land on the default theme,
      // never on a dead selection.
      final fallen = resolveAppTheme('sol-earth');
      expect(fallen.series, ThemeSeries.zodiac);
      expect(fallen.id, zodiacDefaultThemeId);
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

  testWidgets('gold backdrop: gilded constellation, no guardian', (
    tester,
  ) async {
    final theme = ThemeData(
      extensions: [resolveAppTheme('gold-leo').toExtension()],
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
}
