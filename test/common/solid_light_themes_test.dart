import 'dart:io';

import 'package:angelamihomo/common/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('solid zodiac light group data (T264)', () {
    test('twelve animals mirroring the dark set, unique ids', () {
      expect(solidLightThemeDefs.map((d) => d.id), [
        'solid-light-rat',
        'solid-light-ox',
        'solid-light-tiger',
        'solid-light-rabbit',
        'solid-light-dragon',
        'solid-light-snake',
        'solid-light-horse',
        'solid-light-goat',
        'solid-light-monkey',
        'solid-light-rooster',
        'solid-light-dog',
        'solid-light-pig',
      ]);
      expect(
        solidLightThemeDefs.map((d) => d.nameZh),
        solidThemeDefs.map((d) => d.nameZh),
      );
      // Same skeleton per animal as the dark sibling.
      for (var i = 0; i < 12; i++) {
        expect(
          solidLightThemeDefs[i].skeleton,
          solidThemeDefs[i].skeleton,
          reason: solidLightThemeDefs[i].id,
        );
        expect(
          solidLightThemeDefs[i].nameEn,
          '${solidThemeDefs[i].nameEn} Light',
          reason: solidLightThemeDefs[i].id,
        );
        expect(
          solidLightThemeDefs[i].assetPath,
          'assets/images/solid/light/'
          '${solidLightThemeDefs[i].id.substring(12)}.webp',
          reason: solidLightThemeDefs[i].id,
        );
        expect(
          File(solidLightThemeDefs[i].assetPath).existsSync(),
          isTrue,
          reason: solidLightThemeDefs[i].id,
        );
      }
      // No id collides with any of the pre-existing 39 themes.
      final lightIds = solidLightThemeDefs.map((d) => d.id).toSet();
      final existingIds = {
        ...zodiacThemes.map((d) => d.id),
        ...deepSpaceThemeDefs.map((d) => d.id),
        ...solidThemeDefs.map((d) => d.id),
      };
      expect(existingIds.length, 39);
      expect(lightIds.intersection(existingIds), isEmpty);
      expect(solidAllThemes.length, 24);
    });

    test('variant bases match the light artwork base colors', () {
      const sampled = {
        'solid-light-rat': Color(0xFFEBEBED),
        'solid-light-ox': Color(0xFFEFEBE8),
        'solid-light-tiger': Color(0xFFEDE8F0),
        'solid-light-rabbit': Color(0xFFEEE9EC),
        'solid-light-dragon': Color(0xFFE8E9F0),
        'solid-light-snake': Color(0xFFE7F0F0),
        'solid-light-horse': Color(0xFFE8F0EC),
        'solid-light-goat': Color(0xFFEEEFE8),
        'solid-light-monkey': Color(0xFFF1EDE7),
        'solid-light-rooster': Color(0xFFF0E8E9),
        'solid-light-dog': Color(0xFFEFEDE9),
        'solid-light-pig': Color(0xFFEFE9EC),
      };
      for (final def in solidLightThemeDefs) {
        expect(def.variant.backgroundBase, sampled[def.id], reason: def.id);
        expect(def.variant.navBar, sampled[def.id], reason: def.id);
        expect(def.variant.background.isNone, isFalse, reason: def.id);
      }
    });

    test('every light palette meets WCAG AA contrast floors', () {
      for (final def in solidLightThemeDefs) {
        final v = def.variant;
        final base = v.backgroundBase;
        expect(
          _contrast(v.textPrimary, base),
          greaterThanOrEqualTo(7.0),
          reason: '${def.id} textPrimary',
        );
        expect(
          _contrast(v.textSecondary, base),
          greaterThanOrEqualTo(4.5),
          reason: '${def.id} textSecondary',
        );
        expect(
          _contrast(v.primary, base),
          greaterThanOrEqualTo(4.5),
          reason: '${def.id} primary',
        );
        expect(
          _contrast(v.onPrimary, v.primary),
          greaterThanOrEqualTo(4.5),
          reason: '${def.id} onPrimary',
        );
        expect(
          _contrast(v.accent, base),
          greaterThanOrEqualTo(4.5),
          reason: '${def.id} accent',
        );
        expect(
          _contrast(v.success, base),
          greaterThanOrEqualTo(4.5),
          reason: '${def.id} success',
        );
        expect(
          _contrast(v.warning, base),
          greaterThanOrEqualTo(4.5),
          reason: '${def.id} warning',
        );
        expect(
          _contrast(v.error, base),
          greaterThanOrEqualTo(4.5),
          reason: '${def.id} error',
        );
        expect(
          _contrast(v.textPrimary, v.selected.firstColor),
          greaterThanOrEqualTo(4.5),
          reason: '${def.id} selected',
        );
        // The light group really is light: base luminance stays high.
        expect(base.computeLuminance(), greaterThan(0.75), reason: def.id);
      }
    });
  });

  group('theme registry resolves the light group (T264)', () {
    test('each light id resolves to series solid with its asset path', () {
      for (final def in solidLightThemeDefs) {
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
        expect(isSolidLightThemeId(def.id), isTrue, reason: def.id);
      }
      for (final def in solidThemeDefs) {
        expect(isSolidLightThemeId(def.id), isFalse, reason: def.id);
      }
    });

    test('glyph for a light theme is the animal name', () {
      expect(themeGlyphFor('solid-light-rat'), '鼠');
      expect(themeGlyphFor('solid-light-dragon'), '龙');
    });
  });

  group('pre-existing 39 themes resolve exactly as before (T264)', () {
    test('series sizes and resolution are unchanged', () {
      expect(zodiacThemes.length, 12);
      expect(deepSpaceThemeDefs.length, 15);
      expect(solidThemeDefs.length, 12);
      expect(solidThemes.length, 12);
      for (final def in zodiacThemes) {
        final sel = resolveAppTheme(def.id);
        expect(sel.series, ThemeSeries.zodiac, reason: def.id);
        expect(sel.id, def.id, reason: def.id);
        expect(sel.variant, def.variant, reason: def.id);
        expect(sel.solidAssetPath, isNull, reason: def.id);
      }
      for (final def in deepSpaceThemeDefs) {
        final sel = resolveAppTheme(def.id);
        expect(sel.series, ThemeSeries.deepSpace, reason: def.id);
        expect(sel.id, def.id, reason: def.id);
        expect(sel.variant, def.variant, reason: def.id);
        expect(sel.solidAssetPath, isNull, reason: def.id);
      }
      for (final def in solidThemeDefs) {
        final sel = resolveAppTheme(def.id);
        expect(sel.series, ThemeSeries.solid, reason: def.id);
        expect(sel.id, def.id, reason: def.id);
        expect(sel.variant, def.variant, reason: def.id);
        expect(sel.solidAssetPath, def.assetPath, reason: def.id);
      }
    });

    test('fallback for missing and unknown ids is unchanged', () {
      for (final id in <String?>[null, '', 'no-such-theme']) {
        final sel = resolveAppTheme(id);
        expect(sel.series, ThemeSeries.zodiac, reason: '$id');
        expect(sel.id, zodiacDefaultThemeId, reason: '$id');
        expect(sel.solidAssetPath, isNull, reason: '$id');
      }
    });
  });

  testWidgets('backdrop paints the light solid artwork, nothing else', (
    tester,
  ) async {
    final theme = ThemeData(
      extensions: [resolveAppTheme('solid-light-rat').toExtension()],
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
