import 'package:bett_box/common/common.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// T142: cards floating over the zodiac light field must be glass, not
/// slabs. Two opaque traps are pinned here:
///  - shared fills that reach for the composited (opaque) container
///    tones instead of the raw translucent surface token
///    (ContinuousListItem — the connections page);
///  - the stock black shadow stack under a 7%-white glass fill, which
///    composited CommonCard interiors to near-opaque navy and cut the
///    constellation at the card edge (the dashboard tiles).
void main() {
  ThemeData themeFor(String id, Brightness brightness) {
    final def = resolveZodiacTheme(id);
    final variant = def.variant(brightness);
    return ThemeData(
      colorScheme: variant.toColorScheme(brightness),
      extensions: [ZodiacThemeExtension.of(def, brightness)],
    );
  }

  Color? cardBackground(WidgetTester tester) {
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    return button.style?.backgroundColor?.resolve({});
  }

  int shadowLayers(WidgetTester tester) {
    var count = 0;
    for (final box in tester.widgetList<DecoratedBox>(
      find.byType(DecoratedBox),
    )) {
      final decoration = box.decoration;
      if (decoration is ShapeDecoration &&
          (decoration.shadows?.isNotEmpty ?? false)) {
        count++;
      }
    }
    return count;
  }

  group('CommonCard glass discipline', () {
    for (final brightness in Brightness.values) {
      testWidgets('immersive $brightness: fill is the raw surface token', (
        tester,
      ) async {
        final variant = resolveZodiacTheme(
          'sagittarius',
        ).variant(brightness);
        await tester.pumpWidget(
          MaterialApp(
            theme: themeFor('sagittarius', brightness),
            home: const Scaffold(
              body: CommonCard(child: SizedBox(width: 80, height: 40)),
            ),
          ),
        );
        expect(cardBackground(tester), variant.surface);
      });
    }

    testWidgets('immersive dark: no shadow stack under the glass', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: themeFor('sagittarius', Brightness.dark),
          home: const Scaffold(
            body: CommonCard(child: SizedBox(width: 80, height: 40)),
          ),
        ),
      );
      expect(shadowLayers(tester), 0);
    });

    testWidgets('non-immersive dark: legacy opaque fill and shadow stay', (
      tester,
    ) async {
      // Aries is the layered skeleton: solid cards are its identity
      // (design doc 7.1.5) and must not be glassed by this change.
      final scheme = resolveZodiacTheme(
        'aries',
      ).variant(Brightness.dark).toColorScheme(Brightness.dark);
      await tester.pumpWidget(
        MaterialApp(
          theme: themeFor('aries', Brightness.dark),
          home: const Scaffold(
            body: CommonCard(child: SizedBox(width: 80, height: 40)),
          ),
        ),
      );
      expect(cardBackground(tester), scheme.surfaceContainerHigh);
      expect(shadowLayers(tester), 1);
    });
  });

  group('ContinuousListItem glass discipline', () {
    Color frameColor(WidgetTester tester) {
      for (final ro in tester.allRenderObjects) {
        if (ro.runtimeType.toString() == '_RenderContinuousItemFrame') {
          return (ro as dynamic).color as Color;
        }
      }
      fail('continuous item frame not found');
    }

    for (final brightness in Brightness.values) {
      testWidgets('immersive $brightness: fill is the raw surface token', (
        tester,
      ) async {
        final variant = resolveZodiacTheme(
          'sagittarius',
        ).variant(brightness);
        await tester.pumpWidget(
          MaterialApp(
            theme: themeFor('sagittarius', brightness),
            home: const Scaffold(
              body: ContinuousListItem(
                index: 0,
                count: 1,
                child: SizedBox(height: 40),
              ),
            ),
          ),
        );
        expect(frameColor(tester), variant.surface);
      });
    }

    testWidgets('non-immersive dark: legacy opaque fill stays', (
      tester,
    ) async {
      final scheme = resolveZodiacTheme(
        'aries',
      ).variant(Brightness.dark).toColorScheme(Brightness.dark);
      await tester.pumpWidget(
        MaterialApp(
          theme: themeFor('aries', Brightness.dark),
          home: const Scaffold(
            body: ContinuousListItem(
              index: 0,
              count: 1,
              child: SizedBox(height: 40),
            ),
          ),
        ),
      );
      expect(frameColor(tester), scheme.surfaceContainerHigh);
    });
  });

  group('token premise', () {
    test('every immersive variant surface is translucent, both tones', () {
      for (final def in zodiacThemes) {
        if (def.skeleton != ZodiacSkeleton.immersive) continue;
        for (final brightness in Brightness.values) {
          final variant = def.variant(brightness);
          expect(
            variant.surface.a,
            lessThan(1),
            reason: '${def.id} $brightness surface must carry alpha',
          );
          expect(
            variant.surfaceVariant.a,
            lessThan(1),
            reason: '${def.id} $brightness surfaceVariant must carry alpha',
          );
        }
      }
    });
  });
}
