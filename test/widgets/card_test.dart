import 'package:bett_box/widgets/card.dart';
import 'package:bett_box/widgets/zodiac_surface.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('卡片表面由星座表面层绘制，按钮层不描边不填色', (tester) async {
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

    // Exactly one constellation surface paints fill / border / shadow.
    expect(find.byType(ZodiacSurface), findsOneWidget);
    // The button Material itself must not paint a filled or stroked
    // rounded rect (that was the pre-surface implementation).
    final material = find.descendant(
      of: find.byType(CommonCard),
      matching: find.byType(Material),
    );
    expect(material, isNot(paints..drrect()));
    expect(material, isNot(paints..rsuperellipse()));

    await tester.tap(find.byType(CommonCard));
    expect(pressed, 1);
  });

  testWidgets('默认卡片层，选中态升主层', (tester) async {
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
    var surface = tester.widget<ZodiacSurface>(find.byType(ZodiacSurface));
    expect(surface.tone, ZodiacTone.card);
    expect(surface.selected, isFalse);

    await tester.pumpWidget(card(selected: true));
    await tester.pumpAndSettle();
    surface = tester.widget<ZodiacSurface>(find.byType(ZodiacSurface));
    expect(surface.tone, ZodiacTone.panel);
    expect(surface.selected, isTrue);
  });

  testWidgets('显式 emphasis 覆盖为面板层', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 80,
            child: CommonCard(
              emphasis: true,
              onPressed: () {},
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final surface = tester.widget<ZodiacSurface>(find.byType(ZodiacSurface));
    expect(surface.tone, ZodiacTone.panel);
  });
}
