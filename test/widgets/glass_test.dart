import 'package:bett_box/widgets/glass.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GlassTokens hierarchy', () {
    test('primary layer dominates secondary on every axis, both themes', () {
      for (final brightness in Brightness.values) {
        final primary = GlassTokens.of(GlassTier.primary, brightness);
        final secondary = GlassTokens.of(GlassTier.secondary, brightness);
        expect(primary.strength, greaterThan(secondary.strength));
        expect(primary.faceTintAlpha, greaterThan(secondary.faceTintAlpha));
        expect(primary.rimAlpha, greaterThan(secondary.rimAlpha));
        expect(primary.sheen, greaterThan(secondary.sheen));
        expect(
          primary.staticFillAlpha,
          greaterThan(secondary.staticFillAlpha),
        );
        expect(primary.staticRimAlpha, greaterThan(secondary.staticRimAlpha));
        expect(primary.bandScale, greaterThan(secondary.bandScale));
      }
    });

    test('face tint stays restrained so the face cannot read as frosted', () {
      for (final tier in GlassTier.values) {
        for (final brightness in Brightness.values) {
          final tokens = GlassTokens.of(tier, brightness);
          expect(tokens.faceTintAlpha, lessThanOrEqualTo(0.20));
          expect(tokens.contrast, greaterThan(1.0));
          expect(tokens.saturate, greaterThan(1.0));
        }
      }
    });

    test('tone inverts against the background (T106)', () {
      for (final tier in GlassTier.values) {
        final light = GlassTokens.of(tier, Brightness.light);
        final dark = GlassTokens.of(tier, Brightness.dark);
        // Light background: deeper glass — more tint, negative bright,
        // denser static fill. Dark background: lifted glass.
        expect(light.faceTintAlpha, greaterThan(dark.faceTintAlpha));
        expect(light.bright, lessThan(0.0));
        expect(dark.bright, greaterThan(0.0));
        expect(light.staticFillAlpha, greaterThan(dark.staticFillAlpha));
        expect(light.staticDye, greaterThan(dark.staticDye));
      }
      // The rim line is darker on light, brighter on dark.
      final lightScheme = ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      );
      final darkScheme = ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      );
      final lightRim = HSLColor.fromColor(
        GlassTint.resolve(lightScheme).rim,
      ).lightness;
      final darkRim = HSLColor.fromColor(
        GlassTint.resolve(darkScheme).rim,
      ).lightness;
      expect(lightRim, lessThan(darkRim));
    });

    test('bar and dialog sit between primary and secondary', () {
      for (final brightness in Brightness.values) {
        final primary = GlassTokens.of(GlassTier.primary, brightness);
        final secondary = GlassTokens.of(GlassTier.secondary, brightness);
        for (final tier in [GlassTier.bar, GlassTier.dialog]) {
          final tokens = GlassTokens.of(tier, brightness);
          expect(tokens.rimAlpha, lessThanOrEqualTo(primary.rimAlpha));
          expect(tokens.rimAlpha, greaterThan(secondary.rimAlpha));
        }
      }
    });
  });

  group('GlassTint theme following (T82)', () {
    test('hue follows the scheme primary, saturation/lightness clamped', () {
      for (final seed in [
        Colors.blue,
        Colors.green,
        Colors.purple,
        Colors.teal,
        Colors.grey,
      ]) {
        for (final brightness in Brightness.values) {
          final scheme = ColorScheme.fromSeed(
            seedColor: seed,
            brightness: brightness,
          );
          final tint = GlassTint.resolve(scheme);
          final rimHsl = HSLColor.fromColor(tint.rim);
          expect(rimHsl.saturation, inInclusiveRange(0.45, 0.90));
          expect(rimHsl.lightness, inInclusiveRange(0.45, 0.75));
          final seedHue = HSLColor.fromColor(scheme.primary).hue;
          var delta = (rimHsl.hue - seedHue).abs();
          if (delta > 180) delta = 360 - delta;
          expect(delta, lessThan(25), reason: 'rim hue must follow $seed');
        }
      }
    });

    test('extreme seeds cannot collapse the tint to grey or black', () {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF202020),
        brightness: Brightness.dark,
      );
      final tint = GlassTint.resolve(scheme);
      final rimHsl = HSLColor.fromColor(tint.rim);
      expect(rimHsl.saturation, greaterThanOrEqualTo(0.45));
      expect(rimHsl.lightness, greaterThanOrEqualTo(0.45));
    });
  });

  group('GlassSurface', () {
    Widget wrap(Widget child, {bool live = false}) {
      return MaterialApp(
        home: Scaffold(
          body: GlassScope(
            live: live,
            child: Center(child: SizedBox(width: 200, height: 120, child: child)),
          ),
        ),
      );
    }

    testWidgets('static scope renders the static painter and child', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const GlassSurface(
            tier: GlassTier.secondary,
            child: Text('content'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('content'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('live scope falls back to static paint without a shader', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const GlassSurface(
            tier: GlassTier.primary,
            live: true,
            child: Text('hero'),
          ),
        ),
      );
      // In the headless test environment the runtime-effect program is
      // not guaranteed to load; either the shader backdrop or the static
      // painter is acceptable, but the surface must render its child and
      // must never stay blank.
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('hero'), findsOneWidget);
      expect(
        find.byType(BackdropFilter).evaluate().isNotEmpty ||
            find.byType(CustomPaint).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('explicit live=false wins over a live scope', (tester) async {
      await tester.pumpWidget(
        wrap(
          const GlassSurface(
            tier: GlassTier.bar,
            live: false,
            child: Text('bar'),
          ),
          live: true,
        ),
      );
      await tester.pump();
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('bar'), findsOneWidget);
    });
  });

  group('GlassField', () {
    testWidgets('paints the color field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: GlassField())),
      );
      await tester.pump();
      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('landed halo tokens are the Orville azure/blue pair', () {
      expect(GlassField.haloLight, const Color(0x2E60A5FA));
      expect(GlassField.haloDark, const Color(0x2F3B82F6));
    });
  });
}
