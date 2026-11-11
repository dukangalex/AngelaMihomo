import 'package:bett_box/widgets/card.dart';
import 'package:bett_box/widgets/glass.dart';
import 'package:bett_box/widgets/glass_prototype.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

GlassTokens _tokens({bool realtime = true}) {
  return GlassTokens.resolve(
    ColorScheme.fromSeed(seedColor: Colors.blue),
    GlassKind.card,
    tier: GlassTier.primary,
    realtime: realtime,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(brightness: Brightness.light),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('T83 prototype shader glass', () {
    testWidgets('falls back to GlassSurface when the shader is not live', (
      tester,
    ) async {
      // On the host test backend the runtime-effect filter cannot be
      // built (Skia), so the surface must degrade to the current
      // GlassSurface rendering — never a black pane, never a throw.
      await tester.pumpWidget(
        _wrap(
          PrototypeGlassSurface(
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            tokens: _tokens(),
            radius: 30,
            child: const SizedBox(width: 300, height: 120),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GlassSurface), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('static tokens (blur off) always take the fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PrototypeGlassSurface(
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            tokens: _tokens(realtime: false),
            radius: 30,
            child: const SizedBox(width: 300, height: 120),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GlassSurface), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('filterFor is null while the prototype is disabled', () {
      GlassPrototype.enabled = false;
      addTearDown(() => GlassPrototype.enabled = true);
      expect(
        GlassEdgeRefraction.filterFor(
          size: const Size(300, 120),
          radius: 30,
          tint: Colors.blue,
        ),
        isNull,
      );
    });

    testWidgets('CommonCard shaderGlass opt-in mounts the prototype surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        GlassScope(
          child: _wrap(
            const CommonCard(
              glassTier: GlassTier.primary,
              shaderGlass: true,
              child: SizedBox(width: 200, height: 80),
            ),
          ),
        ),
      );
      expect(find.byType(PrototypeGlassSurface), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
