import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/widgets/list.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// T218 (as corrected by the user): the small print is always lit —
// the theme's lit color halved toward onSurface — so it reads
// clearly over the backdrop without wearing a switch's full
// highlight. The tone does not depend on any switch state.
void main() {
  Future<Color?> pumpAndRead(
    WidgetTester tester, {
    required bool on,
  }) async {
    final selection = resolveAppTheme('sagittarius');
    final colorScheme = ColorScheme.fromSeed(
      seedColor: selection.darkVariant.primary,
      brightness: Brightness.dark,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: colorScheme,
          extensions: [selection.toExtension(Brightness.dark)],
          switchTheme: zodiacSwitchTheme(colorScheme, selection.darkVariant),
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
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    return tile.subtitleTextStyle?.color;
  }

  testWidgets('subtitle tone is the halved lit color, on or off', (
    tester,
  ) async {
    final selection = resolveAppTheme('sagittarius');
    final onColor = await pumpAndRead(tester, on: true);
    final offColor = await pumpAndRead(tester, on: false);
    expect(onColor, offColor);
    final scheme = ColorScheme.fromSeed(
      seedColor: selection.darkVariant.primary,
      brightness: Brightness.dark,
    );
    expect(
      onColor,
      zodiacSubtitleColor(scheme, selection.darkVariant),
    );
    // Softer than the switch's full lit color, brighter than the
    // old muted variant tone.
    final lit = zodiacSwitchLitColor(scheme, selection.darkVariant);
    expect(onColor, isNot(lit));
    expect(onColor, isNot(scheme.onSurfaceVariant));
  });
}
