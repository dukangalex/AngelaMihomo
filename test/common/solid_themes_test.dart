import 'package:angelamihomo/common/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('solid zodiac series data (T224)', () {
    test('twelve animals in Chinese zodiac order, unique ids', () {
      expect(solidThemeDefs.map((d) => d.id), [
        'solid-rat',
        'solid-ox',
        'solid-tiger',
        'solid-rabbit',
        'solid-dragon',
        'solid-snake',
        'solid-horse',
        'solid-goat',
        'solid-monkey',
        'solid-rooster',
        'solid-dog',
        'solid-pig',
      ]);
      expect(solidThemeDefs.map((d) => d.nameZh), [
        '鼠',
        '牛',
        '虎',
        '兔',
        '龙',
        '蛇',
        '马',
        '羊',
        '猴',
        '鸡',
        '狗',
        '猪',
      ]);
      final ids = solidThemeDefs.map((d) => d.id).toSet();
      final otherIds = {
        ...zodiacThemes.map((d) => d.id),
        ...deepSpaceThemeDefs.map((d) => d.id),
      };
      expect(ids.intersection(otherIds), isEmpty);
      for (final def in solidThemeDefs) {
        expect(def.nameEn, isNotEmpty, reason: def.id);
        expect(
          def.assetPath,
          'assets/images/solid/${def.id.substring(6)}.webp',
          reason: def.id,
        );
      }
    });

    test('variant bases match the sampled artwork colors', () {
      // The background gradient's last stop (backgroundBase) and the
      // navBar are the base color sampled from each artwork's pixels,
      // so the chrome blends into the image.
      const sampled = {
        'solid-rat': Color(0xFF26282E),
        'solid-ox': Color(0xFF33241A),
        'solid-tiger': Color(0xFF2B1838),
        'solid-rabbit': Color(0xFF38222C),
        'solid-dragon': Color(0xFF1E2542),
        'solid-snake': Color(0xFF173A3A),
        'solid-horse': Color(0xFF142E22),
        'solid-goat': Color(0xFF2E3319),
        'solid-monkey': Color(0xFF3A2A12),
        'solid-rooster': Color(0xFF38181C),
        'solid-dog': Color(0xFF2F2A1A),
        'solid-pig': Color(0xFF331E2A),
      };
      for (final def in solidThemeDefs) {
        expect(def.variant.backgroundBase, sampled[def.id], reason: def.id);
        expect(def.variant.navBar, sampled[def.id], reason: def.id);
        expect(def.variant.background.isNone, isFalse, reason: def.id);
      }
    });
  });

  group('theme registry resolves the solid series (T224)', () {
    test('each solid id resolves to series solid with its asset path', () {
      for (final def in solidThemeDefs) {
        final sel = resolveAppTheme(def.id);
        expect(sel.series, ThemeSeries.solid, reason: def.id);
        expect(sel.isSolid, isTrue, reason: def.id);
        expect(sel.id, def.id, reason: def.id);
        expect(sel.solidAssetPath, def.assetPath, reason: def.id);
        expect(sel.variant, def.variant, reason: def.id);
        expect(sel.motif, isNull, reason: def.id);
        expect(sel.constellation.stars, isEmpty, reason: def.id);
        expect(sel.showGuardian, isFalse, reason: def.id);
        expect(sel.sign, def.nameZh, reason: def.id);
        expect(sel.toExtension().solidAssetPath, def.assetPath, reason: def.id);
      }
    });

    test('glyph for a solid theme is the animal name', () {
      expect(themeGlyphFor('solid-rat'), '鼠');
      expect(themeGlyphFor('solid-dragon'), '龙');
    });

    test('withdrawn ids still fall back to the default theme', () {
      for (final id in ['gold-aries', 'gold-leo', 'sol-earth']) {
        final fallen = resolveAppTheme(id);
        expect(fallen.series, ThemeSeries.zodiac, reason: id);
        expect(fallen.id, zodiacDefaultThemeId, reason: id);
        expect(fallen.solidAssetPath, isNull, reason: id);
      }
    });
  });

  testWidgets('backdrop paints the solid artwork, nothing else', (
    tester,
  ) async {
    final theme = ThemeData(
      extensions: [resolveAppTheme('solid-rat').toExtension()],
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
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ZodiacBackdrop),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(find.byType(ZodiacGuardianPlate), findsNothing);
    expect(find.byType(DeepSpacePlate), findsNothing);
  });
}
