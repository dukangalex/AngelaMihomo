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

  group('golden saints and solar system series (T183/T184)', () {
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

    test('solar system: eight planets, one body each, solid paint', () {
      expect(solarSystemThemeDefs, hasLength(8));
      final bodies = solarSystemThemeDefs.map((d) => d.body).toSet();
      expect(bodies, SolarBody.values.toSet());
      for (final def in solarSystemThemeDefs) {
        expect(def.variant.background.isGradient, isFalse, reason: def.id);
      }
    });

    test('registry resolves gold and solar selections', () {
      final gold = resolveAppTheme('gold-leo');
      expect(gold.series, ThemeSeries.goldSaint);
      expect(gold.variant, goldSaintThemeById('gold-leo')!.variant);
      expect(gold.constellation, resolveZodiacTheme('leo').constellation);
      expect(gold.showGuardian, isFalse);
      final solar = resolveAppTheme('sol-earth');
      expect(solar.series, ThemeSeries.solarSystem);
      expect(solar.planet, SolarBody.earth);
      expect(themeGlyphFor('gold-leo'), '♌');
      expect(themeGlyphFor('sol-earth'), '●');
    });
  });

  testWidgets('solar backdrop: one blurred planet, nothing else', (
    tester,
  ) async {
    final def = solarSystemThemeById('sol-saturn')!;
    final theme = ThemeData(
      extensions: [resolveAppTheme('sol-saturn').toExtension()],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: ZodiacBackdrop()),
      ),
    );
    await tester.pump();
    final paints = tester.widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(ZodiacBackdrop),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(paints, hasLength(1));
    expect(paints.single.painter, isA<SolarPlanetPainter>());
    expect(find.byType(Image), findsNothing);
    expect(find.byType(ZodiacGuardianPlate), findsNothing);
    final boxes = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(ZodiacBackdrop),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      (boxes.first.decoration as BoxDecoration).color,
      def.variant.backgroundBase,
    );
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
