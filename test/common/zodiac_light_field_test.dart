import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The backdrop's guardian layers (T159) read the current page label,
/// so backdrop pumps run under a ProviderScope like the app itself.
class _FixedPageLabel extends CurrentPageLabel {
  @override
  PageLabel build() => PageLabel.dashboard;
}

/// T123 (DESIGN doc section 7): the light field is family-wide — every
/// theme's single variant carries glow spots and a glow tone, every
/// theme carries a recognizable asterism, and backgrounds are imagery
/// gradients except Gemini's documented solid exception (doc 7.4).
/// (Single-set family since 2026-11-15: one variant per theme.)
void main() {
  // The backdrop's name plate (T159) reads the global localizations,
  // which the app loads before any page builds.
  setUp(() async {
    await AppLocalizations.load(const Locale('en'));
  });

  group('light field data audit', () {
    test('every variant has a glow tone and both glow spots', () {
      for (final def in zodiacThemes) {
        final variant = def.variant;
        expect(
          variant.glow,
          isNotNull,
          reason: '${def.id} must carry a glow tone',
        );
        expect(
          variant.glows,
          hasLength(2),
          reason: '${def.id} must carry both glow spots',
        );
        expect(
          variant.glows.map((spot) => spot.pos),
          containsAll([ZodiacGlowPos.topRight, ZodiacGlowPos.centerLeft]),
        );
      }
    });

    test('backgrounds are gradients except the Gemini exception', () {
      for (final def in zodiacThemes) {
        final background = def.variant.background;
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
            reason: '${def.id} bg must be an imagery gradient',
          );
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
      testWidgets('${def.id} paints without error', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentPageLabelProvider.overrideWith(() => _FixedPageLabel()),
            ],
            child: MaterialApp(
              theme: ThemeData(
                colorScheme: def.variant.toColorScheme(),
                extensions: [ZodiacThemeExtension.of(def)],
              ),
              home: const ZodiacBackdrop(),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(CustomPaint), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
