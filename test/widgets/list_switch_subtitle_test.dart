import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/widgets/list.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// T218: while a switch row is on, its small print wears the switch's
// lit color (the thumb's color, theme by theme); off rows keep the
// muted subtitle tone.
void main() {
  Future<void> pumpRows(WidgetTester tester, {required bool on}) async {
    final selection = resolveAppTheme('sagittarius');
    final colorScheme = ColorScheme.fromSeed(
      seedColor: selection.variant.primary,
      brightness: Brightness.dark,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: colorScheme,
          extensions: [selection.toExtension()],
          switchTheme: zodiacSwitchTheme(colorScheme, selection.variant),
        ),
        home: Scaffold(
          body: ListItem.switchItem(
            title: const Text('row title'),
            subtitle: const Text('row small print'),
            delegate: SwitchDelegate(value: on, onChanged: (_) {}),
          ),
        ),
      ),
    );
  }

  testWidgets('on switch: subtitle takes the lit thumb color', (
    tester,
  ) async {
    await pumpRows(tester, on: true);
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    final selection = resolveAppTheme('sagittarius');
    final expected = zodiacSwitchLitColor(
      Theme.of(tester.element(find.byType(ListTile))).colorScheme,
      selection.variant,
    );
    expect(tile.subtitleTextStyle?.color, expected);
    // The lit color is the theme's own accent, not a fixed green:
    // for Sagittarius it is the selected gradient's last stop.
    expect(expected, selection.variant.selected.stops!.last);
  });

  testWidgets('off switch: subtitle keeps the muted tone', (tester) async {
    await pumpRows(tester, on: false);
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    final scheme = Theme.of(
      tester.element(find.byType(ListTile)),
    ).colorScheme;
    expect(tile.subtitleTextStyle?.color, scheme.onSurfaceVariant);
  });
}
