import 'package:bett_box/widgets/card.dart';
import 'package:bett_box/widgets/glass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _wrap(
  Widget child, {
  bool glass = false,
  bool live = true,
  Brightness brightness = Brightness.light,
}) {
  final app = MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(body: Center(child: child)),
  );
  return glass ? GlassScope(live: live, child: app) : app;
}

void main() {
  group('CommonCard liquid glass (T38 phase 1)', () {
    testWidgets('no BackdropFilter outside a GlassScope', (tester) async {
      await tester.pumpWidget(
        _wrap(const CommonCard(child: SizedBox(width: 120, height: 60))),
      );
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('BackdropFilter appears inside a GlassScope', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CommonCard(child: SizedBox(width: 120, height: 60)),
          glass: true,
        ),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(GlassSurface), findsOneWidget);
    });

    testWidgets('degraded mode keeps translucency without BackdropFilter', (
      tester,
    ) async {
      GlassEffects.blurEnabled = false;
      addTearDown(() => GlassEffects.blurEnabled = true);
      await tester.pumpWidget(
        _wrap(
          const CommonCard(child: SizedBox(width: 120, height: 60)),
          glass: true,
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);
      final tokens = GlassTokens.resolve(
        ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        GlassKind.card,
      );
      expect(tokens.effectiveFill, tokens.staticFill);
    });

    test('crystal tokens: low blur, clear fill, bright rim (round 5)', () {
      // User direction: crystal-clear (「晶莹剔透」), not milky frost. Lock
      // the envelope so tokens cannot drift back to earlier rounds:
      // round 4 raised sigma into the 14–16 band so busy page content
      // would dissolve instead of ghosting through; the round-5
      // reference fitting (iOS 27 captures: mid-tint toolbar sigma
      // ≈ 6.9, heavy blur = frosted plastic) plus the new smooth
      // colour field — nothing behind the glass can ghost — pull
      // sigma back down into 8–14 (dialog keeps the top of the band:
      // it floats over real content). Round 5 also raises the
      // rim/highlight floors (rim ≥ 0.5, highlight ≥ 0.30 in BOTH
      // themes) because the edge light is what separates a pane from
      // the bright colour field behind it, and adds the dark contour
      // line (0.05–0.45) that carries the pane's outline.
      for (final brightness in Brightness.values) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: brightness,
        );
        for (final kind in GlassKind.values) {
          final tokens = GlassTokens.resolve(scheme, kind);
          expect(tokens.sigma, inInclusiveRange(8, 14), reason: '$kind sigma');
          expect(tokens.fill.a, lessThan(0.5), reason: '$kind fill');
          expect(tokens.rim.a, greaterThanOrEqualTo(0.5), reason: '$kind rim');
          expect(
            tokens.highlightPeak,
            greaterThanOrEqualTo(0.30),
            reason: '$kind highlight',
          );
          expect(
            tokens.contour.a,
            inInclusiveRange(0.05, 0.45),
            reason: '$kind contour',
          );
        }
      }
    });

    test('neutral tokens: untinted fill, thin body, saturated backdrop '
        '(round 5)', () {
      // User direction (round 3, kept since): the glass carries no
      // colour of its own — fill is a neutral gray at theme lightness,
      // thinned in round 4 to the 0.14–0.20 band (Ultrathin
      // territory — the backdrop supplies the body), and tint comes
      // from the backdrop, whose saturation is boosted. Round 5 sets
      // that boost to 1.6, anchored on the reference colour model
      // (saturation 1.4) with headroom for the pale field.
      double chromaOf(Color c) {
        final components = [c.r, c.g, c.b]..sort();
        return components.last - components.first;
      }

      for (final brightness in Brightness.values) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: brightness,
        );
        for (final kind in GlassKind.values) {
          final tokens = GlassTokens.resolve(scheme, kind);
          expect(
            tokens.fill.a,
            inInclusiveRange(0.14, 0.20),
            reason: '$kind fill alpha',
          );
          expect(
            chromaOf(tokens.fill),
            lessThanOrEqualTo(0.03),
            reason: '$kind fill must be neutral',
          );
          expect(tokens.saturation, 1.6, reason: '$kind saturation');
        }
        // Caller-supplied bases (the nav bar passes its card-matching body
        // colour) are neutralised as well.
        final navTokens = GlassTokens.resolve(
          scheme,
          GlassKind.navigationBar,
          base: scheme.surfaceContainerHigh,
        );
        expect(
          chromaOf(navTokens.fill),
          lessThanOrEqualTo(0.03),
          reason: 'nav fill must be neutral even with a caller base',
        );
      }
    });

    test('saturation backdrop stage is a ColorFilter, not a transform', () {
      // Regression lock: the backdrop saturation stage must be built with
      // ColorFilter.matrix (4x5, 20 entries). Building it with
      // ImageFilter.matrix (4x4 spatial transform, 16 entries) throws
      // ArgumentError on device and silently blanks every glass surface,
      // while host-side widget tests do not surface the error.
      expect(saturationFilter(1.8), isA<ColorFilter>());
    });

    testWidgets('static scope keeps glass surface without BackdropFilter', (
      tester,
    ) async {
      // Full-rollout discipline: cards in long scrolling lists opt into a
      // static scope — glass fill, rim and radius, but never a live
      // BackdropFilter.
      await tester.pumpWidget(
        _wrap(
          const CommonCard(child: SizedBox(width: 120, height: 60)),
          glass: true,
          live: false,
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);
      // Round 5: static surfaces still mount a GlassSurface — the
      // sheen and rim layers are painted without any backdrop filter.
      expect(find.byType(GlassSurface), findsOneWidget);
      expect(find.byType(CommonCard), findsOneWidget);
    });

    test('static tokens paint the static fill (full rollout)', () {
      for (final brightness in Brightness.values) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: brightness,
        );
        for (final kind in GlassKind.values) {
          final tokens = GlassTokens.resolve(scheme, kind, realtime: false);
          expect(tokens.blur, isFalse, reason: '$kind must not blur');
          expect(
            tokens.effectiveFill,
            tokens.staticFill,
            reason: '$kind static fill',
          );
          // Round 5 band: the static fill thinned from the 0.88–0.94
          // lid of rounds ≤ 4 (which is what read as a flat pale card
          // over a bright background) to 0.68–0.80 over the designed
          // field, and its body leans toward the field's hues instead
          // of neutral grey. The floor guards legibility, the ceiling
          // guards against drifting back to opaque-flat.
          expect(
            tokens.staticFill.a,
            inInclusiveRange(0.66, 0.82),
            reason: '$kind static fill alpha',
          );
        }
      }
    });

    testWidgets('glass field paints in both brightnesses (round 5)', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: GlassField(brightness: brightness),
          ),
        );
        expect(find.byType(GlassField), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('dark theme also renders glass', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CommonCard(child: SizedBox(width: 120, height: 60)),
          glass: true,
          brightness: Brightness.dark,
        ),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  });
}
