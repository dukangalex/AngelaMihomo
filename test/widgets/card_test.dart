import 'package:bett_box/widgets/card.dart';
import 'package:bett_box/widgets/glass.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('卡片表面由玻璃层绘制，按钮层不描边不填色', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 80,
            child: CommonCard(
              onPressed: () => pressed++,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Exactly one glass surface paints fill / rim / sheen.
    expect(find.byType(GlassSurface), findsOneWidget);
    // The button Material itself must not paint a filled or stroked
    // rounded rect anymore (that was the pre-glass implementation).
    final material = find.descendant(
      of: find.byType(CommonCard),
      matching: find.byType(Material),
    );
    expect(material, isNot(paints..drrect()));
    expect(material, isNot(paints..rsuperellipse()));

    await tester.tap(find.byType(CommonCard));
    expect(pressed, 1);
  });

  testWidgets('默认次层 20 圆角，选中态升主层 30 圆角并带辉光档', (tester) async {
    Widget card({bool selected = false}) {
      return MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 80,
            child: CommonCard(
              isSelected: selected,
              onPressed: () {},
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(card());
    await tester.pumpAndSettle();
    var surface = tester.widget<GlassSurface>(find.byType(GlassSurface));
    expect(surface.tier, GlassTier.secondary);
    expect(surface.radius, 20);

    await tester.pumpWidget(card(selected: true));
    await tester.pumpAndSettle();
    surface = tester.widget<GlassSurface>(find.byType(GlassSurface));
    expect(surface.tier, GlassTier.primary);
    expect(surface.radius, 30);
  });

  testWidgets('显式 glassTier 覆盖选中态推导', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 80,
            child: CommonCard(
              glassTier: GlassTier.dialog,
              onPressed: () {},
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final surface = tester.widget<GlassSurface>(find.byType(GlassSurface));
    expect(surface.tier, GlassTier.dialog);
  });
}
