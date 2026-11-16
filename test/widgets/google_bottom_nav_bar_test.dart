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

// The bar is a full-width strip (design doc 3.5.6, alignment round):
// on a 400-wide view the four slots are 100 wide, centers at 50/150/250/350,
// and the 60-high bar sits flush at the bottom (y 740..800).
const _barY = 770.0;
const _slotWidth = 100.0;
const _firstCenterX = 50.0;

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

Future<void> _pumpBar(
  WidgetTester tester, {
  required int selectedIndex,
  required ValueChanged<int> onTabChange,
}) async {
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

/// Selection is read from icon/label color alone — there is no backing
/// block behind the current tab. Each item's tint is the projection of
/// its IconTheme color onto the onSurfaceVariant -> primary segment:
/// 1 = fully highlighted, 0 = resting.
List<double> _itemTints(WidgetTester tester) {
  final barElement = tester.element(find.byType(GoogleBottomNavBar));
  final scheme = Theme.of(barElement).colorScheme;
  final base = scheme.onSurfaceVariant;
  final target = scheme.primary;
  final dr = target.r - base.r;
  final dg = target.g - base.g;
  final db = target.b - base.b;
  final denom = dr * dr + dg * dg + db * db;
  final themes = tester
      .widgetList<IconTheme>(
        find.descendant(
          of: find.byType(GoogleBottomNavBar),
          matching: find.byType(IconTheme),
        ),
      )
      .toList();
  return [
    for (final theme in themes)
      if (theme.data.color == null || denom == 0)
        0.0
      else
        (((theme.data.color!.r - base.r) * dr +
                    (theme.data.color!.g - base.g) * dg +
                    (theme.data.color!.b - base.b) * db) /
                denom)
            .clamp(0.0, 1.0),
  ];
}

int _highlightIndex(WidgetTester tester) {
  final tints = _itemTints(tester);
  var best = 0;
  for (var i = 1; i < tints.length; i++) {
    if (tints[i] > tints[best]) best = i;
  }
  return best;
}

void main() {
  setUpAll(() async {
    await AppLocalizations.load(const Locale('zh', 'CN'));
  });

  testWidgets('全宽平直栏：无胶囊、无选中底衬色块', (tester) async {
    await _pumpBar(tester, selectedIndex: 1, onTabChange: (_) {});

    // No CustomPaint backing block anywhere in the bar.
    expect(
      find.descendant(
        of: find.byType(GoogleBottomNavBar),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    // The bar spans the full width and sits flush on the bottom edge.
    final barRect = tester.getRect(find.byType(GoogleBottomNavBar));
    expect(barRect.left, 0);
    expect(barRect.right, 400);
    expect(barRect.bottom, 800);
    // Exactly the selected item is tinted.
    final tints = _itemTints(tester);
    expect(tints.length, 4);
    expect(tints[1], closeTo(1.0, 0.02));
    expect(tints[0], closeTo(0.0, 0.02));
    expect(tints[2], closeTo(0.0, 0.02));
    expect(tints[3], closeTo(0.0, 0.02));
  });

  testWidgets('拖拽期间高亮 1:1 跟手，起步没有死区', (tester) async {
    await _pumpBar(tester, selectedIndex: 2, onTabChange: (_) {});

    final gesture = await tester.startGesture(Offset(_slotCenterX(2), _barY));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_highlightIndex(tester), 2);

    var fingerX = _slotCenterX(2);
    final steps = <double>[
      for (var i = 0; i < 20; i++) -3.0,
      for (var i = 0; i < 33; i++) 3.0,
    ];
    var respondedAt = -1;
    for (var i = 0; i < steps.length; i++) {
      fingerX += steps[i];
      await gesture.moveTo(Offset(fingerX, _barY));
      await tester.pump(const Duration(milliseconds: 16));
      final tints = _itemTints(tester);
      // The neighbor tint rises from zero as soon as the drag moves:
      // no dead zone at the start.
      if (respondedAt < 0 && tints[1] > 0.01) respondedAt = i;
      // The strongest tint always sits on the slot nearest the finger.
      final nearest = ((fingerX - _firstCenterX) / _slotWidth)
          .round()
          .clamp(0, 3);
      expect(_highlightIndex(tester), nearest, reason: 'step $i');
    }
    expect(respondedAt, inInclusiveRange(0, 2));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  test('槽位阻尼：范围内直通，越界渐进且有界', () {
    expect(navBarSlotResistance(0.5, 4), 0.5);
    expect(navBarSlotResistance(3.0, 4), 3.0);
    final slight = navBarSlotResistance(-0.5, 4);
    expect(slight, lessThan(0));
    expect(slight, greaterThan(-0.5));
    final far = navBarSlotResistance(-3.0, 4);
    expect(far, lessThan(slight));
    expect(far, greaterThan(-0.35));
    final right = navBarSlotResistance(6.0, 4);
    expect(right, greaterThan(3.0));
    expect(right, lessThan(3.35));
  });

  testWidgets('拖到最左越界后松手吸附到首格', (tester) async {
    int? changedTo;
    await _pumpBar(
      tester,
      selectedIndex: 3,
      onTabChange: (index) => changedTo = index,
    );

    var fingerX = _slotCenterX(3);
    final gesture = await tester.startGesture(Offset(fingerX, _barY));
    await tester.pump(const Duration(milliseconds: 200));
    while (fingerX > _slotCenterX(3) - 3.3 * _slotWidth) {
      fingerX -= 4.0;
      await gesture.moveTo(Offset(fingerX, _barY));
      await tester.pump(const Duration(milliseconds: 8));
    }
    expect(_highlightIndex(tester), 0);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(changedTo, 0);
    final tints = _itemTints(tester);
    expect(tints[0], closeTo(1.0, 0.02));
    expect(tints[3], closeTo(0.0, 0.02));
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

  // Upstream v1.19.8 nav-bar model: a plain tap snaps the highlight to
  // the target and switches the page immediately; only drags glide.
  testWidgets('跨多格点击立即切换页面且高亮吸附到位', (tester) async {
    final changes = <int>[];
    await _pumpBar(tester, selectedIndex: 0, onTabChange: changes.add);

    final gesture = await tester.startGesture(Offset(_slotCenterX(3), _barY));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(changes, [3]);
    expect(_highlightIndex(tester), 3);

    await tester.pumpAndSettle();
    expect(changes, [3]);
    final tints = _itemTints(tester);
    expect(tints[3], closeTo(1.0, 0.02));
    expect(tints[0], closeTo(0.0, 0.02));
  });

  testWidgets('按下非当前格后立即拖动，高亮不会与手指错位', (tester) async {
    await _pumpBar(tester, selectedIndex: 0, onTabChange: (_) {});

    var fingerX = _slotCenterX(3);
    final gesture = await tester.startGesture(Offset(fingerX, _barY));
    await tester.pump(const Duration(milliseconds: 20));
    fingerX -= 12;
    await gesture.moveTo(Offset(fingerX, _barY));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_highlightIndex(tester), 3);
    expect(_itemTints(tester)[3], greaterThan(0.5));

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
