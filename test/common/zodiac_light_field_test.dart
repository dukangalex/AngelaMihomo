import 'package:bett_box/common/common.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// T123 (DESIGN doc section 7): the light field is family-wide — every
/// variant carries glow spots and a glow tone, every theme carries a
/// recognizable asterism, and backgrounds are imagery gradients except
/// Gemini's documented solid exception (doc 7.4).
void main() {
  group('light field data audit', () {
    test('every variant has a glow tone and both glow spots', () {
      for (final def in zodiacThemes) {
        for (final brightness in Brightness.values) {
          final variant = def.variant(brightness);
          expect(
            variant.glow,
            isNotNull,
            reason: '${def.id} $brightness must carry a glow tone',
          );
          expect(
            variant.glows,
            hasLength(2),
            reason: '${def.id} $brightness must carry both glow spots',
          );
          expect(
            variant.glows.map((spot) => spot.pos),
            containsAll([ZodiacGlowPos.topRight, ZodiacGlowPos.centerLeft]),
          );
        }
      }
    });

    test('backgrounds are gradients except the Gemini exception', () {
      for (final def in zodiacThemes) {
        for (final brightness in Brightness.values) {
          final background = def.variant(brightness).background;
          if (def.id == 'gemini') {
            expect(
              background.isGradient,
              isFalse,
              reason: 'gemini keeps its solid block bg (doc 7.4)',
            );
          } else {
            expect(
              background.isGradient,
              isTrue,
              reason: '${def.id} $brightness bg must be an imagery gradient',
            );
          }
        }
      }
    });

    test('every theme carries a well-formed asterism', () {
      expect(zodiacThemes, hasLength(12));
      for (final def in zodiacThemes) {
        final constellation = def.constellation;
        expect(
          constellation.stars.length,
          greaterThanOrEqualTo(4),
          reason: '${def.id} asterism needs at least 4 stars',
        );
        expect(
          constellation.edges.length,
          greaterThanOrEqualTo(3),
          reason: '${def.id} asterism needs connecting lines',
        );
        for (final star in constellation.stars) {
          expect(star.x, inInclusiveRange(0, 1));
          expect(star.y, inInclusiveRange(0, 1));
          expect(star.magnitude, inInclusiveRange(1, 3));
        }
        for (final edge in constellation.edges) {
          expect(edge.a, inInclusiveRange(0, constellation.stars.length - 1));
          expect(edge.b, inInclusiveRange(0, constellation.stars.length - 1));
          expect(edge.a, isNot(edge.b));
        }
      }
    });
  });

  group('backdrop rendering', () {
    for (final def in zodiacThemes) {
      for (final brightness in Brightness.values) {
        testWidgets('${def.id} $brightness paints without error',
            (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                brightness: brightness,
                extensions: [ZodiacThemeExtension.of(def, brightness)],
              ),
              home: const ZodiacBackdrop(),
            ),
          );
          await tester.pump();
          expect(find.byType(CustomPaint), findsWidgets);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
