import 'package:bett_box/common/common.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deep space series data (T181)', () {
    test('twelve events, unique ids, chronological years', () {
      expect(deepSpaceThemeDefs, hasLength(12));
      final ids = deepSpaceThemeDefs.map((d) => d.id).toSet();
      expect(ids, hasLength(12));
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

  testWidgets('solid mode also flattens a deep-space theme', (tester) async {
    final def = deepSpaceThemeById('jwst')!;
    final theme = ThemeData(
      extensions: [
        resolveAppTheme('jwst').toExtension(solidBackground: true),
      ],
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
      findsNothing,
    );
    final boxes = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(ZodiacBackdrop),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(boxes, hasLength(1));
    expect(
      (boxes.single.decoration as BoxDecoration).color,
      def.variant.backgroundBase,
    );
  });
}
