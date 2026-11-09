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

    test('crystal tokens: low blur, clear fill, bright rim (round 4)', () {
      // User direction: crystal-clear (「晶莹剔透」), not milky frost. Lock
      // the round-4 envelope so tokens cannot drift back to earlier
      // rounds: round 4 deliberately raises sigma into the 14–16 band so
      // the backdrop dissolves into light instead of ghosting through.
      for (final brightness in Brightness.values) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: brightness,
        );
        for (final kind in GlassKind.values) {
          final tokens = GlassTokens.resolve(scheme, kind);
          expect(
            tokens.sigma,
            inInclusiveRange(13, 17),
            reason: '$kind sigma',
          );
          expect(tokens.fill.a, lessThan(0.5), reason: '$kind fill');
          expect(tokens.rim.a, greaterThanOrEqualTo(0.34), reason: '$kind rim');
          expect(
            tokens.highlightPeak,
            greaterThanOrEqualTo(0.18),
            reason: '$kind highlight',
          );
        }
      }
    });

    test('neutral tokens: untinted fill, thin body, saturated backdrop '
        '(round 4)', () {
      // User direction (round 3, kept in round 4): the glass carries no
      // colour of its own — fill is a neutral gray at theme lightness,
      // thinned further in round 4 to the 0.14–0.20 band (Ultrathin
      // territory — the backdrop supplies the body), and tint comes from
      // the backdrop, whose saturation is boosted.
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
          expect(tokens.saturation, 1.8, reason: '$kind saturation');
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
        }
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
