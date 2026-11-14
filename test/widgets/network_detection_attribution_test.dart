import 'package:bett_box/views/dashboard/widgets/network_detection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// T109: the compact detection card used to squeeze country, city and
// ASN into one ellipsized line next to the IP, cutting the city down
// to a stub ('United States · B…'). The attribution block must show
// all three elements with no ellipsis truncation, in both themes.
void main() {
  Widget wrap({
    required double width,
    required Brightness brightness,
    required String location,
    required String operator,
  }) {
    return MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: NetworkDetectionAttribution(
              location: location,
              operator: operator,
            ),
          ),
        ),
      ),
    );
  }

  Finder attributionText(String needle) => find.byWidgetPredicate(
    (widget) => widget is Text && (widget.data?.contains(needle) ?? false),
  );

  void expectFullyVisible(WidgetTester tester, String needle) {
    final finder = attributionText(needle);
    expect(finder, findsOneWidget);
    final text = tester.widget<Text>(finder);
    expect(
      text.overflow,
      isNot(TextOverflow.ellipsis),
      reason: 'attribution must never ellipsize',
    );
    // Lay the same text out again at the rendered width: with the
    // widget's line cap, nothing may be left over (an exceeded cap
    // is what used to clip the city away).
    final width = tester.getSize(finder).width;
    final painter = TextPainter(
      text: TextSpan(text: text.data, style: text.style),
      maxLines: text.maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    expect(
      painter.didExceedMaxLines,
      isFalse,
      reason: 'every element must fit its line budget in full',
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'long country + long city stay fully visible ($brightness)',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            width: 320,
            brightness: brightness,
            location: 'United States of America · Ouagadougou',
            operator: 'AS64500 Example Networks',
          ),
        );
        await tester.pump();
        expectFullyVisible(tester, 'Ouagadougou');
        expectFullyVisible(tester, 'United States of America');
        expectFullyVisible(tester, 'AS64500');
      },
    );
  }

  testWidgets('narrow card width still shows the whole city', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        width: 176,
        brightness: Brightness.light,
        location: 'United States · Ouagadougou',
        operator: 'AS64500 Example',
      ),
    );
    await tester.pump();
    expectFullyVisible(tester, 'Ouagadougou');
  });
}
