// Tests for the Lucian UX/UI spec batch (T290): #004 progress
// download button, #438 morph action button, #082 icon sweep
// progress, #299 usage warning thresholds, #440 first-run empty
// state, #070 stacking toasts, #336 detent sheet.
import 'package:angelamihomo/manager/message_manager.dart';
import 'package:angelamihomo/models/profile_usage.dart';
import 'package:angelamihomo/views/dashboard/widgets/profile_info.dart';
import 'package:angelamihomo/widgets/detent_sheet.dart';
import 'package:angelamihomo/widgets/first_run_empty_state.dart';
import 'package:angelamihomo/widgets/icon_sweep_progress.dart';
import 'package:angelamihomo/widgets/morph_action_button.dart';
import 'package:angelamihomo/widgets/progress_download_button.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('#299 usage warning level (spec thresholds)', () {
    test('below 80% is normal', () {
      expect(usageWarningLevel(0), UsageWarningLevel.normal);
      expect(usageWarningLevel(0.79), UsageWarningLevel.normal);
    });

    test('80% up to full is warning', () {
      expect(usageWarningLevel(0.8), UsageWarningLevel.warning);
      expect(usageWarningLevel(0.99), UsageWarningLevel.warning);
    });

    test('at the limit is critical', () {
      expect(usageWarningLevel(1), UsageWarningLevel.critical);
      expect(usageWarningLevel(1.2), UsageWarningLevel.critical);
    });

    testWidgets('segment bar fill turns orange at 85%, red at 100%', (
      tester,
    ) async {
      Color? fillColor() {
        for (final widget in tester.widgetList<DecoratedBox>(
          find.byType(DecoratedBox),
        )) {
          final decoration = widget.decoration as BoxDecoration;
          if (decoration.color != null &&
              decoration.color != const Color(0x00000000)) {
            return decoration.color;
          }
        }
        return null;
      }

      await tester.pumpWidget(
        _wrap(const UsageSegmentBar(segments: [0.85], height: 4)),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(fillColor(), const Color(0xFFF59E0B));

      await tester.pumpWidget(
        _wrap(const UsageSegmentBar(segments: [1], height: 4)),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(fillColor(), const Color(0xFFE11D48));
    });
  });

  group('#004 progress download button', () {
    testWidgets('idle tap starts, running shows percent, tap cancels', (
      tester,
    ) async {
      var started = 0;
      var cancelled = 0;
      Widget button(ProgressDownloadPhase phase, double? progress) {
        return _wrap(
          ProgressDownloadButton(
            phase: phase,
            progress: progress,
            label: '同步',
            doneLabel: '已更新',
            onPressed: () => started++,
            onCancel: () => cancelled++,
          ),
        );
      }

      await tester.pumpWidget(button(ProgressDownloadPhase.idle, null));
      await tester.tap(find.text('同步'));
      expect(started, 1);

      await tester.pumpWidget(button(ProgressDownloadPhase.running, 0.42));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('42%'), findsOneWidget);
      await tester.tap(find.text('42%'));
      expect(cancelled, 1);
    });

    testWidgets('done folds, draws the check state, then settles', (
      tester,
    ) async {
      var settled = 0;
      await tester.pumpWidget(
        _wrap(
          ProgressDownloadButton(
            phase: ProgressDownloadPhase.done,
            progress: 1,
            label: '同步',
            doneLabel: '已更新',
            onDoneSettled: () => settled++,
          ),
        ),
      );
      // Fold takes 650ms; the done label expands after it.
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('已更新'), findsOneWidget);
      // Done is held ~2.75s before the owner is told to reset.
      await tester.pump(const Duration(milliseconds: 2800));
      expect(settled, 1);
    });
  });

  group('#438 morph action button', () {
    testWidgets('success: shrinks, checks, grows back, completes', (
      tester,
    ) async {
      var completed = 0;
      await tester.pumpWidget(
        _wrap(
          MorphActionButton(
            label: '保存',
            icon: Icons.save,
            onPressed: () async {
              await Future<void>.delayed(const Duration(milliseconds: 300));
              return true;
            },
            onCompleted: () => completed++,
          ),
        ),
      );
      await tester.pump();
      final fullWidth = tester
          .getSize(find.byType(AnimatedContainer).first)
          .width;
      expect(fullWidth, greaterThan(48));

      // Tap the button itself: the label text also exists in the
      // hidden measuring copy.
      await tester.tap(find.byType(MorphActionButton));
      // One frame to start the implicit width animation, then let
      // the 460ms shrink run to completion.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final busyWidth = tester
          .getSize(find.byType(AnimatedContainer).first)
          .width;
      expect(busyWidth, closeTo(48, 1));

      // Action resolves at ~300ms; success holds 1000ms, grows
      // back over ~700ms, then onCompleted fires.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(const Duration(milliseconds: 800));
      expect(completed, 1);
    });

    testWidgets('failure: grows straight back, never completes', (
      tester,
    ) async {
      var completed = 0;
      await tester.pumpWidget(
        _wrap(
          MorphActionButton(
            label: '保存',
            onPressed: () async => false,
            onCompleted: () => completed++,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(MorphActionButton));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 100));
      expect(completed, 0);
      // Back at idle: the label is visible and tappable again.
      expect(find.text('保存'), findsWidgets);
    });
  });

  group('#082 icon sweep progress', () {
    testWidgets('percent climbs, badge toggles with pause, tap fires', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          IconSweepProgress(
            icon: const SizedBox.expand(child: ColoredBox(color: Colors.blue)),
            progress: 0.42,
            onTap: () => taps++,
          ),
        ),
      );
      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          IconSweepProgress(
            icon: const SizedBox.expand(child: ColoredBox(color: Colors.blue)),
            progress: 0.42,
            paused: true,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow));
      expect(taps, 1);
    });
  });

  group('#440 first-run empty state', () {
    testWidgets('shows headline and CTA, CTA fires', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          FirstRunEmptyState(
            title: '没有配置文件，请先添加配置文件',
            ctaLabel: '添加配置',
            onCta: () => taps++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('没有配置文件，请先添加配置文件'), findsOneWidget);
      await tester.tap(find.text('添加配置'));
      expect(taps, 1);
    });
  });

  group('#070 stacking toasts', () {
    Future<MessageManagerState> pumpManager(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MessageManager(child: Scaffold(body: SizedBox())),
        ),
      );
      return tester.state<MessageManagerState>(find.byType(MessageManager));
    }

    testWidgets('stacks in order; only the front counts down', (tester) async {
      final state = await pumpManager(tester);
      await state.message('甲');
      await state.message('乙');
      await state.message('丙');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('甲'), findsOneWidget);
      expect(find.text('乙'), findsOneWidget);
      expect(find.text('丙'), findsOneWidget);

      // Duplicate text is not stacked twice.
      await state.message('丙');
      await tester.pump();
      expect(find.text('丙'), findsOneWidget);

      // 4.5s passes: only the front toast （丙） is dismissed.
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('丙'), findsNothing);
      expect(find.text('乙'), findsOneWidget);
      expect(find.text('甲'), findsOneWidget);

      // The next in line becomes the front and counts down too.
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('乙'), findsNothing);
      expect(find.text('甲'), findsOneWidget);
    });

    testWidgets('loading toast waits, resolves in place, dismisses', (
      tester,
    ) async {
      final state = await pumpManager(tester);
      final id = state.messageLoading('正在下载更新');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('正在下载更新'), findsOneWidget);
      // Loading never auto-dismisses.
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('正在下载更新'), findsOneWidget);

      state.resolveMessage(id, kind: ToastKind.success, text: '下载完成');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('下载完成'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('下载完成'), findsNothing);
    });

    testWidgets('swiping the front toast sideways dismisses it', (
      tester,
    ) async {
      final state = await pumpManager(tester);
      await state.message('可滑动');
      // Step in small frames so the 500ms enter animation actually
      // plays to rest (a single long pump only ticks it once).
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final center = tester.getCenter(find.text('可滑动'));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(120, 0));
      await gesture.moveBy(const Offset(120, 0));
      await gesture.up();
      // The sideways exit animation (300ms) needs a start frame
      // and a completion frame before the entry is removed.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('可滑动'), findsNothing);
    });
  });

  group('#336 detent sheet', () {
    test('nearest detent honours the 0.2s fling projection', () {
      // Detent tops for a 500px frame (fractions .23 / .5 / .89).
      const tops = [385.0, 250.0, 55.0];
      expect(nearestDetent(topY: 380, velocityY: 0, detentTops: tops), 0);
      expect(nearestDetent(topY: 300, velocityY: -800, detentTops: tops), 2);
      expect(nearestDetent(topY: 300, velocityY: 800, detentTops: tops), 0);
      expect(nearestDetent(topY: 260, velocityY: 0, detentTops: tops), 1);
    });

    test('rubber band resists past the ends at 0.25', () {
      expect(rubberBand(300, 100, 400), 300);
      expect(rubberBand(50, 100, 400), 87.5);
      expect(rubberBand(450, 100, 400), 412.5);
    });

    testWidgets('starts at half, drags with the finger, snaps to a detent', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetentSheet(
              header: SizedBox(height: 40, child: Text('分组详情')),
              child: SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pump();
      // Test surface is 800x600: detent tops are 462 / 300 / 66.
      final sheetSurface = find.descendant(
        of: find.byType(DetentSheet),
        matching: find.byType(Material),
      );
      double sheetTop() => tester.getTopLeft(sheetSurface).dy;
      expect(sheetTop(), closeTo(300, 1));

      // Drag the header up in steps and release near the top:
      // the spring settles on the full detent (top 66).
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('分组详情')),
      );
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();
      expect(sheetTop(), lessThan(200));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(sheetTop(), closeTo(66, 2));
    });

    testWidgets('tapping the header cycles to the next detent', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetentSheet(
              header: SizedBox(height: 40, child: Text('分组详情')),
              child: SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pump();
      final sheetSurface = find.descendant(
        of: find.byType(DetentSheet),
        matching: find.byType(Material),
      );
      double sheetTop() => tester.getTopLeft(sheetSurface).dy;
      expect(sheetTop(), closeTo(300, 1));
      await tester.tap(find.text('分组详情'));
      await tester.pumpAndSettle();
      expect(sheetTop(), closeTo(66, 2));
      // And cycles on from full back to collapsed.
      await tester.tap(find.text('分组详情'));
      await tester.pumpAndSettle();
      expect(sheetTop(), closeTo(462, 2));
    });
  });
}
