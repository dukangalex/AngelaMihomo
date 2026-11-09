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

    test('crystal tokens: low blur, clear fill, bright rim (round 6)', () {
      // User direction: crystal-clear (「晶莹剔透」), not milky frost. Lock
      // the envelope so tokens cannot drift back to earlier rounds:
      // round 4 raised sigma into the 14–16 band so busy page content
      // would dissolve instead of ghosting through; the round-5
      // reference fitting (iOS 27 captures: mid-tint toolbar sigma
      // ≈ 6.9, heavy blur = frosted plastic) plus the smooth colour
      // field — nothing behind the glass can ghost — keep sigma in
      // 8–14 for every tier (dialog keeps the top of the band: it
      // floats over real content).
      // Round 6 change: the rim/highlight/contour floors are now PER
      // TIER. Rounds ≤ 5 floored every surface at rim ≥ 0.5 /
      // highlight ≥ 0.30, which is precisely what flattened the
      // hierarchy the user rejected — the secondary tier must be
      // ALLOWED to recede (rim floor 0.40, highlight floor 0.20),
      // while primary/bar/dialog keep the round-5 floors, and the
      // primary contour ceiling rises to 0.55 because the primary
      // pane carries the strongest outline (dark 0.50).
      const floors = <GlassTier, (double rim, double highlight)>{
        GlassTier.primary: (0.5, 0.30),
        GlassTier.secondary: (0.40, 0.20),
        GlassTier.bar: (0.5, 0.30),
        GlassTier.dialog: (0.5, 0.30),
      };
      for (final brightness in Brightness.values) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: brightness,
        );
        for (final tier in GlassTier.values) {
          final tokens = GlassTokens.resolve(
            scheme,
            GlassKind.card,
            tier: tier,
          );
          expect(tokens.sigma, inInclusiveRange(8, 14), reason: '$tier sigma');
          expect(tokens.fill.a, lessThan(0.5), reason: '$tier fill');
          final (rimFloor, highlightFloor) = floors[tier]!;
          expect(
            tokens.rim.a,
            greaterThanOrEqualTo(rimFloor),
            reason: '$tier rim',
          );
          expect(
            tokens.highlightPeak,
            greaterThanOrEqualTo(highlightFloor),
            reason: '$tier highlight',
          );
          expect(
            tokens.contour.a,
            inInclusiveRange(0.05, 0.55),
            reason: '$tier contour',
          );
        }
      }
    });

    test('hierarchy tiers: primary clearly outweighs secondary (round 6)',
        () {
      // The round-6 feature itself, locked: on every axis the user
      // can perceive — fill density, static density, rim light,
      // specular peak, backdrop saturation — the primary tier must
      // sit clearly above the secondary tier (a token drift that
      // closes the gap reintroduces the flat single-weight page the
      // user rejected on the round-5 build). Bar and dialog sit
      // between the two.
      for (final brightness in Brightness.values) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: brightness,
        );
        GlassTokens forTier(GlassTier tier) =>
            GlassTokens.resolve(scheme, GlassKind.card, tier: tier);
        final primary = forTier(GlassTier.primary);
        final secondary = forTier(GlassTier.secondary);
        final bar = forTier(GlassTier.bar);
        final dialog = forTier(GlassTier.dialog);
        expect(
          primary.fill.a,
          greaterThan(secondary.fill.a + 0.10),
          reason: 'fill gap $brightness',
        );
        expect(
          primary.staticFill.a,
          greaterThan(secondary.staticFill.a + 0.15),
          reason: 'static fill gap $brightness',
        );
        expect(
          primary.rim.a,
          greaterThan(secondary.rim.a),
          reason: 'rim gap $brightness',
        );
        expect(
          primary.highlightPeak,
          greaterThan(secondary.highlightPeak + 0.10),
          reason: 'highlight gap $brightness',
        );
        expect(
          primary.saturation,
          greaterThan(secondary.saturation),
          reason: 'saturation gap $brightness',
        );
        expect(
          primary.contour.a,
          greaterThan(secondary.contour.a),
          reason: 'contour gap $brightness',
        );
        // Bar and dialog between the two on fill density.
        expect(bar.fill.a, greaterThan(secondary.fill.a));
        expect(bar.fill.a, lessThan(primary.fill.a));
        expect(dialog.fill.a, greaterThan(secondary.fill.a));
        expect(dialog.fill.a, lessThan(primary.fill.a));
        // Kind defaults land on their natural tiers.
        expect(
          GlassTokens.resolve(scheme, GlassKind.card).tier,
          GlassTier.secondary,
        );
        expect(
          GlassTokens.resolve(scheme, GlassKind.navigationBar).tier,
          GlassTier.bar,
        );
        expect(
          GlassTokens.resolve(scheme, GlassKind.dialog).tier,
          GlassTier.dialog,
        );
      }
    });

    test('neutral tokens: untinted fill, tiered body and saturation '
        '(round 6)', () {
      // User direction (round 3, kept since): the glass carries no
      // colour of its own — fill is a neutral gray at theme
      // lightness, and tint comes from the backdrop, whose
      // saturation is boosted.
      // Round 6 change: the single round-4/5 fill band (0.14–0.20)
      // and the single saturation (1.6) are replaced by the tier
      // design values — the bands were the flatness. Each tier's
      // fill alpha and saturation are locked to their design value
      // (±0.02) so a tier cannot silently drift toward its neighbour;
      // neutrality (chroma ≤ 0.03) still holds for every tier.
      const design = <GlassTier, (double light, double dark, double sat)>{
        GlassTier.primary: (0.30, 0.30, 1.9),
        GlassTier.secondary: (0.10, 0.12, 1.35),
        GlassTier.bar: (0.20, 0.22, 1.7),
        GlassTier.dialog: (0.22, 0.23, 1.6),
      };
      double chromaOf(Color c) {
        final components = [c.r, c.g, c.b]..sort();
        return components.last - components.first;
      }

      for (final brightness in Brightness.values) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: brightness,
        );
        final isLight = brightness == Brightness.light;
        for (final tier in GlassTier.values) {
          final tokens = GlassTokens.resolve(
            scheme,
            GlassKind.card,
            tier: tier,
          );
          final (lightA, darkA, sat) = design[tier]!;
          expect(
            tokens.fill.a,
            closeTo(isLight ? lightA : darkA, 0.02),
            reason: '$tier fill alpha',
          );
          expect(
            chromaOf(tokens.fill),
            lessThanOrEqualTo(0.03),
            reason: '$tier fill must be neutral',
          );
          expect(tokens.saturation, sat, reason: '$tier saturation');
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

    test('static tokens paint the static fill (round 6 tiers)', () {
      // Round 6 change: the round-5 single static band (0.66–0.82)
      // becomes per-tier bands. Static surfaces are where most list
      // cards live, so the hierarchy must survive with blur off:
      // primary stays near the old dense lid (0.84–0.90, it is a
      // page's main surface and must hold its own over the field),
      // secondary drops to 0.52–0.66 (receding is the point; the
      // floor still guards text legibility), bar/dialog between.
      const bands = <GlassTier, (double lo, double hi)>{
        GlassTier.primary: (0.84, 0.90),
        GlassTier.secondary: (0.52, 0.66),
        GlassTier.bar: (0.78, 0.82),
        GlassTier.dialog: (0.80, 0.86),
      };
      for (final brightness in Brightness.values) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: brightness,
        );
        for (final tier in GlassTier.values) {
          final tokens = GlassTokens.resolve(
            scheme,
            GlassKind.card,
            tier: tier,
            realtime: false,
          );
          expect(tokens.blur, isFalse, reason: '$tier must not blur');
          expect(
            tokens.effectiveFill,
            tokens.staticFill,
            reason: '$tier static fill',
          );
          final (lo, hi) = bands[tier]!;
          expect(
            tokens.staticFill.a,
            inInclusiveRange(lo, hi),
            reason: '$tier static fill alpha',
          );
        }
      }
    });

    testWidgets('CommonCard glassTier primary mounts a glass surface', (
      tester,
    ) async {
      // Round 6 wiring lock: the tier a page claims on its main card
      // must reach the token resolution (a dropped parameter would
      // silently flatten the page back to all-secondary).
      await tester.pumpWidget(
        _wrap(
          const CommonCard(
            glassTier: GlassTier.primary,
            child: SizedBox(width: 120, height: 60),
          ),
          glass: true,
        ),
      );
      expect(find.byType(GlassSurface), findsOneWidget);
      final surface = tester.widget<GlassSurface>(
        find.byType(GlassSurface),
      );
      expect(surface.tokens.tier, GlassTier.primary);
      await tester.pumpWidget(
        _wrap(
          const CommonCard(child: SizedBox(width: 120, height: 60)),
          glass: true,
        ),
      );
      final secondarySurface = tester.widget<GlassSurface>(
        find.byType(GlassSurface),
      );
      expect(secondarySurface.tokens.tier, GlassTier.secondary);
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
