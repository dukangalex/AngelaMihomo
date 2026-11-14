import 'package:bett_box/common/zodiac_theme.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/widgets/google_bottom_nav_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppSetting extends AppSetting {
  @override
  AppSettingProps build() => const AppSettingProps();
}

class _FakeThemeSetting extends ThemeSetting {
  @override
  ThemeProps build() => const ThemeProps();
}

const _barY = 758.0;
const _slotWidth = 91.0;
const _firstCenterX = 63.5;

double _slotCenterX(num slot) => _firstCenterX + slot * _slotWidth;

List<NavigationItem> _items() => [
  for (final label in [
    PageLabel.dashboard,
    PageLabel.proxies,
    PageLabel.profiles,
    PageLabel.tools,
  ])
    NavigationItem(
      icon: const Icon(Icons.circle),
      label: label,
      builder: (_) => const SizedBox(),
    ),
];

double? _travelSign;

Future<void> _pumpBar(
  WidgetTester tester, {
  required int selectedIndex,
  required ValueChanged<int> onTabChange,
}) async {
  _travelSign = null;
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appSettingProvider.overrideWith(_FakeAppSetting.new),
        themeSettingProvider.overrideWith(_FakeThemeSetting.new),
      ],
      child: MaterialApp(
        home: Material(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GoogleBottomNavBar(
                  navigationItems: _items(),
                  selectedIndex: selectedIndex,
                  onTabChange: onTabChange,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// T115: the bar no longer paints a pill block — the selection is
// carried by the item colors alone (spec 3.5.6). The readout
// inverts that color encoding back to the continuous indicator
// position: each item's icon color lerps from the unselected color
// to the family secondary by 1 - easeOut(distance), so the peak
// item plus the eased distance reconstruct the exact position the
// drag physics produced.
double _easeOutInverse(double y) {
  var lo = 0.0;
  var hi = 1.0;
  for (var i = 0; i < 40; i++) {
    final mid = (lo + hi) / 2;
    if (Curves.easeOut.transform(mid) < y) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

int? _pressedItemIndex(WidgetTester tester, Finder bar) {
  final expanded = find.descendant(of: bar, matching: find.byType(Expanded));
  if (tester.widgetList(expanded).length != 4) return null;
  for (var i = 0; i < 4; i++) {
    final transforms = find.descendant(
      of: expanded.at(i),
      matching: find.byType(Transform),
    );
    if (tester.widgetList(transforms).length != 1) continue;
    final scale = tester.widget<Transform>(transforms).transform.storage[0];
    // Pressed items shrink below 1.0; every other item scales >= 1.0.
    if (scale < 0.999) return i;
  }
  return null;
}

double _indicatorCenterX(WidgetTester tester) {
  final bar = find.byType(GoogleBottomNavBar);
  final iconFinder = find.descendant(
    of: bar,
    matching: find.byIcon(Icons.circle),
  );
  final factors = <double>[];
  for (var i = 0; i < 4; i++) {
    final element = tester.element(iconFinder.at(i));
    final theme = Theme.of(element);
    final base = theme.colorScheme.onSurfaceVariant;
    final selected = defaultZodiacTheme.light.secondary;
    final color = IconTheme.of(element).color!;
    // Project the rendered color onto the base->selected segment.
    final dr = (selected.r - base.r).abs();
    final dg = (selected.g - base.g).abs();
    final db = (selected.b - base.b).abs();
    final factor = dr >= dg && dr >= db
        ? (color.r - base.r) / (selected.r - base.r)
        : dg >= db
        ? (color.g - base.g) / (selected.g - base.g)
        : (color.b - base.b) / (selected.b - base.b);
    factors.add(factor.clamp(0.0, 1.0));
  }
  // Mid-glide on a multi-slot jump every factor is zero (the
  // origin factor has saturated off, the target's has not risen):
  // the position is somewhere inside the unlit middle zone.
  if (factors.every((f) => f < 0.000001)) {
    return _slotCenterX(1.5);
  }
  var peak = 0;
  for (var i = 1; i < 4; i++) {
    if (factors[i] > factors[peak]) peak = i;
  }
  final distance = _easeOutInverse((1 - factors[peak]).clamp(0.0, 1.0));
  double slot;
  if (peak > 0 && factors[peak - 1] > 0.000001) {
    slot = peak - distance;
  } else if (peak < 3 && factors[peak + 1] > 0.000001) {
    slot = peak + distance;
  } else if (distance <= 0.002) {
    slot = peak.toDouble();
    _travelSign = null;
  } else {
    // Only the peak item carries signal: the position is either a
    // drag overshoot beyond the edge slot, or a jump glide whose
    // middle items are force-unlit. A far pressed item identifies
    // the jump (and its direction); otherwise it is an overshoot,
    // continuing in the established travel direction if any.
    final pressed = _pressedItemIndex(tester, bar);
    if (pressed != null && pressed != peak) {
      _travelSign = pressed > peak ? 1.0 : -1.0;
      slot = peak + _travelSign! * distance;
    } else if (_travelSign != null) {
      // Mid-jump, approaching the far edge from inside.
      slot = peak - _travelSign! * distance;
    } else {
      slot = peak + (peak == 0 ? -distance : distance);
    }
  }
  return _slotCenterX(slot);
}

void main() {
  setUpAll(() async {
    await AppLocalizations.load(const Locale('zh', 'CN'));
  });

  testWidgets('拖拽期间选中指示 1:1 跟手，往返经过起点没有死区', (tester) async {
    await _pumpBar(tester, selectedIndex: 2, onTabChange: (_) {});

    final gesture = await tester.startGesture(Offset(_slotCenterX(2), _barY));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_indicatorCenterX(tester), closeTo(_slotCenterX(2), 0.5));

    var fingerX = _slotCenterX(2);
    final steps = <double>[
      for (var i = 0; i < 20; i++) -3.0,
      for (var i = 0; i < 33; i++) 3.0,
    ];
    double? previousPill;
    var dragStartedAt = -1;
    for (var i = 0; i < steps.length; i++) {
      fingerX += steps[i];
      await gesture.moveTo(Offset(fingerX, _barY));
      await tester.pump(const Duration(milliseconds: 16));
      final pill = _indicatorCenterX(tester);
      if (dragStartedAt < 0 && (pill - _slotCenterX(2)).abs() > 0.5) {
        dragStartedAt = i;
      }
      if (dragStartedAt >= 0) {
        expect(pill, closeTo(fingerX, 0.5), reason: 'step $i');
        if (previousPill != null) {
          expect((pill - previousPill).abs(), greaterThan(2.5));
        }
      }
      previousPill = pill;
    }
    expect(dragStartedAt, inInclusiveRange(0, 2));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('到达最左格时不会撞墙，越界为渐进阻尼', (tester) async {
    int? changedTo;
    await _pumpBar(
      tester,
      selectedIndex: 3,
      onTabChange: (index) => changedTo = index,
    );

    var fingerX = _slotCenterX(3);
    final gesture = await tester.startGesture(Offset(fingerX, _barY));
    await tester.pump(const Duration(milliseconds: 200));

    final deltas = <double>[];
    double? previousPill;
    while (fingerX > _slotCenterX(3) - 3.3 * _slotWidth) {
      fingerX -= 2.0;
      await gesture.moveTo(Offset(fingerX, _barY));
      await tester.pump(const Duration(milliseconds: 8));
      final pill = _indicatorCenterX(tester);
      if (previousPill != null) {
        final slot = (pill - _firstCenterX) / _slotWidth;
        if (slot > -0.03 && slot < 0.05) deltas.add(previousPill - pill);
      }
      previousPill = pill;
    }

    expect(deltas, isNotEmpty);
    for (final delta in deltas) {
      expect(delta, greaterThan(0.8));
    }
    expect(_indicatorCenterX(tester), lessThan(_firstCenterX));
    expect(
      _indicatorCenterX(tester),
      greaterThan(_firstCenterX - 0.23 * _slotWidth),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(changedTo, 0);
    expect(_indicatorCenterX(tester), closeTo(_firstCenterX, 0.5));
  });

  testWidgets('点击屏幕左右边距命中首尾按钮', (tester) async {
    final changes = <int>[];
    await _pumpBar(tester, selectedIndex: 2, onTabChange: changes.add);

    await tester.tapAt(const Offset(5, _barY));
    await tester.pumpAndSettle();
    expect(changes, [0]);

    await tester.tapAt(const Offset(395, _barY));
    await tester.pumpAndSettle();
    expect(changes, [0, 3]);
  });

  testWidgets('跨多格点击时抬手不重启滑行，并立即切换页面', (tester) async {
    final changes = <int>[];
    await _pumpBar(tester, selectedIndex: 0, onTabChange: changes.add);

    final gesture = await tester.startGesture(Offset(_slotCenterX(3), _barY));
    await tester.pump();
    // Start segment: the indicator leaves slot 0 moving right.
    // (Mid-glide the position has no rendered readout at all: the
    // jump logic keeps the middle items unlit and the target factor
    // only rises within the last slot — that was true of the color
    // encoding by design, so the glide is verified at its two
    // observable segments and its endpoints.)
    var previous = _indicatorCenterX(tester);
    await tester.pump(const Duration(milliseconds: 16));
    var current = _indicatorCenterX(tester);
    expect(current, greaterThan(previous));
    previous = current;

    await gesture.up();
    expect(changes, [3]);

    // Collect the rest of the glide: it must never move backwards
    // (a restarted glide would head back toward slot 0), it must
    // pass the visible tail past slot 2, and it must settle exactly
    // on slot 3. Plateaus are expected while the position crosses
    // the unlit middle zone.
    var last = previous;
    var sawVisibleTail = false;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final now = _indicatorCenterX(tester);
      expect(now, greaterThanOrEqualTo(last - 0.5));
      if (now > _slotCenterX(2)) sawVisibleTail = true;
      last = now;
      if ((now - _slotCenterX(3)).abs() < 0.5) break;
    }
    expect(sawVisibleTail, isTrue);

    await tester.pumpAndSettle();
    expect(changes, [3]);
    expect(_indicatorCenterX(tester), closeTo(_slotCenterX(3), 0.5));
  });

  testWidgets('按下非当前格后立即拖动，选中指示不会与手指错位', (tester) async {
    await _pumpBar(tester, selectedIndex: 0, onTabChange: (_) {});

    var fingerX = _slotCenterX(3);
    final gesture = await tester.startGesture(Offset(fingerX, _barY));
    await tester.pump(const Duration(milliseconds: 20));
    fingerX -= 12;
    await gesture.moveTo(Offset(fingerX, _barY));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_indicatorCenterX(tester), closeTo(fingerX, 0.5));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('跨项点击时中间项不产生缩放跳动', (tester) async {
    await _pumpBar(tester, selectedIndex: 0, onTabChange: (_) {});

    await tester.tapAt(Offset(_slotCenterX(3), _barY));
    await tester.pump();

    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final transforms = tester
          .widgetList<Transform>(find.byType(Transform))
          .toList();
      if (transforms.length >= 4) {
        final scale1 = transforms[1].transform.storage[0];
        final scale2 = transforms[2].transform.storage[0];
        expect(scale1, closeTo(1.0, 0.001));
        expect(scale2, closeTo(1.0, 0.001));
      }
    }

    await tester.pumpAndSettle();
  });

  testWidgets('相邻点击时正常产生缩放连续过渡', (tester) async {
    await _pumpBar(tester, selectedIndex: 0, onTabChange: (_) {});

    await tester.tapAt(Offset(_slotCenterX(1), _barY));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final transforms = tester
        .widgetList<Transform>(find.byType(Transform))
        .toList();
    if (transforms.length >= 2) {
      final scale1 = transforms[1].transform.storage[0];
      expect(scale1, greaterThan(1.0));
    }

    await tester.pumpAndSettle();
  });
}
