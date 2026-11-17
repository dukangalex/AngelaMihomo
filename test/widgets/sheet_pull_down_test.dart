import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/widgets/sheet.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// T143: every bottom sheet can be pulled down to dismiss — from the
/// handle/header and from the top of its scrolling body — whether or
/// not the sheet is expandable. Expandable sheets keep their
/// expand/collapse drag, long bodies still scroll to the very end, and
/// a short pull springs back instead of dismissing.
void main() {
  setUp(() {
    globalState.appState = AppState(
      brightness: Brightness.light,
      version: 0,
      viewSize: const Size(400, 800),
      requests: FixedList(100),
      logs: FixedList(100),
      traffics: FixedList(30),
      totalTraffic: Traffic(),
      systemUiOverlayStyle: const SystemUiOverlayStyle(),
    );
  });

  Future<void> openSheet(
    WidgetTester tester, {
    required bool expandable,
    required Widget body,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSheet(
                context: context,
                props: SheetProps(expandable: expandable),
                builder: (_, type) => AdaptiveSheetScaffold(
                  title: '语言选择',
                  body: body,
                  type: type,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('语言选择'), findsOneWidget);
  }

  Widget listBody(int count) {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (_, i) => SizedBox(height: 48, child: Text('选项 $i')),
    );
  }

  /// Slow manual drag so the release velocity stays low and the
  /// distance branch (not the fling branch) decides the outcome.
  Future<void> slowDrag(
    WidgetTester tester,
    Offset start,
    double totalDy,
  ) async {
    final gesture = await tester.startGesture(start);
    final steps = (totalDy.abs() / 30).ceil();
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset(0, totalDy / steps));
      await tester.pump(const Duration(milliseconds: 40));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('non-expandable sheet: header pull-down dismisses', (
    tester,
  ) async {
    await openSheet(tester, expandable: false, body: listBody(5));
    final start = tester.getCenter(find.text('语言选择'));
    await slowDrag(tester, start, 150);
    expect(find.text('语言选择'), findsNothing);
  });

  testWidgets('non-expandable sheet: short pull springs back', (
    tester,
  ) async {
    await openSheet(tester, expandable: false, body: listBody(5));
    final before = tester.getTopLeft(find.text('语言选择')).dy;
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('语言选择')),
    );
    // Step the drag: the arena's touch slop eats the first ~20px, and
    // updates land on subsequent moves.
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 40));
    }
    // The sheet follows the finger while pulling.
    expect(tester.getTopLeft(find.text('语言选择')).dy, greaterThan(before));
    await gesture.up();
    await tester.pumpAndSettle();
    // ...and returns to rest instead of dismissing.
    expect(find.text('语言选择'), findsOneWidget);
    expect(tester.getTopLeft(find.text('语言选择')).dy, closeTo(before, 1));
  });

  testWidgets('non-expandable sheet: pulling the list past its top '
      'dismisses', (tester) async {
    await openSheet(tester, expandable: false, body: listBody(30));
    final start = tester.getCenter(find.text('选项 0'));
    await slowDrag(tester, start, 150);
    expect(find.text('语言选择'), findsNothing);
  });

  testWidgets('expandable sheet: drag up expands, long drag down '
      'collapses then dismisses', (tester) async {
    await openSheet(tester, expandable: true, body: listBody(30));
    final collapsed = tester.getSize(find.byType(AdaptiveSheetScaffold));
    await slowDrag(tester, tester.getCenter(find.text('语言选择')), -160);
    final expanded = tester.getSize(find.byType(AdaptiveSheetScaffold));
    expect(expanded.height, greaterThan(collapsed.height + 40));
    expect(find.text('语言选择'), findsOneWidget);
    await slowDrag(tester, tester.getCenter(find.text('语言选择')), 460);
    expect(find.text('语言选择'), findsNothing);
  });

  testWidgets('long body still scrolls to the very last item', (
    tester,
  ) async {
    await openSheet(tester, expandable: false, body: listBody(40));
    for (var i = 0; i < 6 && find.text('选项 39').evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -320));
      await tester.pumpAndSettle();
    }
    expect(find.text('选项 39'), findsOneWidget);
    expect(find.text('语言选择'), findsOneWidget);
  });
}
