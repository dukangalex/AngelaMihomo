import 'package:bett_box/common/common.dart';
import 'package:bett_box/widgets/card.dart';
import 'package:bett_box/widgets/list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// T151: card glass is a family-wide discipline (DESIGN doc section
/// 3.4 rule 7, user-verified on a real device 2026-11-15). T142 fixed
/// the immersive skeleton only and audited the raw `surface` token —
/// but nine themes' cards still rendered opaque, because their tokens
/// were solid AND the shared fill path gated the glass branch on the
/// immersive skeleton. These tests assert what the cards actually
/// resolve to when painted — the button style's resolved fill and
/// border, the shadow stack, and the list frame's paint color — for
/// every theme of the (single-set) family, so the discipline cannot
/// silently narrow again.
void main() {
  ThemeData themeFor(ZodiacThemeDef def) {
    return ThemeData(
      colorScheme: def.variant.toColorScheme(),
      extensions: [ZodiacThemeExtension.of(def)],
    );
  }

  Future<({Color? fill, BorderSide? side, int shadows})> pumpCard(
    WidgetTester tester,
    ThemeData theme, {
    bool selected = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: CommonCard(
            isSelected: selected,
            child: const SizedBox(width: 200, height: 80),
          ),
        ),
      ),
    );
    final button = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byType(CommonCard),
        matching: find.byType(OutlinedButton),
      ),
    );
    final style = button.style!;
    var shadows = 0;
    for (final box in tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(CommonCard),
        matching: find.byType(DecoratedBox),
      ),
    )) {
      final decoration = box.decoration;
      if (decoration is ShapeDecoration) {
        shadows += decoration.shadows?.length ?? 0;
      }
    }
    return (
      fill: style.backgroundColor!.resolve(const <WidgetState>{}),
      side: style.side!.resolve(const <WidgetState>{}),
      shadows: shadows,
    );
  }

  group('glass premise: the canonical tokens are translucent', () {
    for (final def in zodiacThemes) {
      test('${def.id} surface tokens sit in the glass band', () {
        final variant = def.variant;
        for (final token in [variant.surface, variant.surfaceVariant]) {
          expect(
            token.a,
            inInclusiveRange(0.03, 0.12),
            reason: '${def.id} token $token must be dark-field glass',
          );
          // White-based: the rgb channels are equal and bright, so the
          // fill lightens the field instead of tinting it.
          expect(token.r, token.g);
          expect(token.g, token.b);
          expect(token.r, greaterThan(0.9));
        }
      });
    }
  });

  group('every theme paints glass cards', () {
    for (final def in zodiacThemes) {
      testWidgets('${def.id} card fill is the raw surface token', (
        tester,
      ) async {
        final card = await pumpCard(tester, themeFor(def));
        expect(card.fill, def.variant.surface, reason: def.id);
        expect(card.side?.color, def.variant.outline, reason: def.id);
        expect(
          card.shadows,
          0,
          reason: '${def.id}: glass cards carry no shadow stack',
        );
      });

      testWidgets('${def.id} selected card fill is the surfaceVariant', (
        tester,
      ) async {
        final card = await pumpCard(tester, themeFor(def), selected: true);
        expect(card.fill, def.variant.surfaceVariant, reason: def.id);
      });

      testWidgets('${def.id} list item frame paints the surface token', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: themeFor(def),
            home: const Scaffold(
              body: Column(
                children: [
                  ContinuousListItem(
                    index: 0,
                    count: 1,
                    child: Text('entry'),
                  ),
                ],
              ),
            ),
          ),
        );
        // The frame is a private render-object widget; read the color
        // it was actually given to paint with.
        Color? frameColor;
        void visit(Element element) {
          if (element.widget.runtimeType.toString() ==
              '_ContinuousItemFrame') {
            frameColor = (element.widget as dynamic).color as Color;
          }
          element.visitChildren(visit);
        }

        tester.element(find.byType(ContinuousListItem)).visitChildren(visit);
        expect(frameColor, def.variant.surface, reason: def.id);
      });
    }
  });

  group('without a zodiac theme the legacy fills are unchanged', () {
    testWidgets('plain dark theme keeps solid fill and its shadows', (
      tester,
    ) async {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      );
      final card = await pumpCard(tester, ThemeData(colorScheme: scheme));
      expect(card.fill, scheme.surfaceContainerHigh);
      expect(card.shadows, greaterThan(0));
    });
  });
}
