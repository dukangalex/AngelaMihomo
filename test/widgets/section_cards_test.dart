import 'package:bett_box/widgets/card.dart';
import 'package:bett_box/widgets/list.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cards mode renders one card per item and no dividers', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionContainer(
            title: 'Section',
            cards: true,
            items: [
              ListItem(title: Text('Alpha')),
              ListItem(title: Text('Beta')),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(CommonCard), findsNWidgets(2));
    expect(find.byType(Divider), findsNothing);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('panel mode keeps one shared card with a divider', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionContainer(
            title: 'Section',
            items: [
              ListItem(title: Text('Alpha')),
              ListItem(title: Text('Beta')),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(CommonCard), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('style scope restyles title and gives a circular trailing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListItemStyleScope(
            titleStyle: const TextStyle(fontSize: 33),
            circularTrailing: true,
            child: ListItem.next(
              title: const Text('Theme'),
              delegate: NextDelegate(
                title: 'Theme',
                builder: (_) => const SizedBox(),
              ),
            ),
          ),
        ),
      ),
    );
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.titleTextStyle?.fontSize, 33);
    final circle = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle,
    );
    expect(circle, findsOneWidget);
  });

  testWidgets('without a scope the nav trailing stays a plain chevron', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListItem.next(
            title: const Text('Theme'),
            delegate: NextDelegate(
              title: 'Theme',
              builder: (_) => const SizedBox(),
            ),
          ),
        ),
      ),
    );
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.trailing, isA<Icon>());
    expect((tile.trailing as Icon).icon, Icons.chevron_right_rounded);
  });
}
