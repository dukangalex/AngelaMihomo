import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/views/dashboard/dashboard.dart';
import 'package:bett_box/widgets/grid.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('packGridItems correctly packs half and full width items', () {
    const item1 = GridItem(crossAxisCellCount: 4, child: SizedBox());
    const item2 = GridItem(crossAxisCellCount: 8, child: SizedBox());
    const item3 = GridItem(crossAxisCellCount: 4, child: SizedBox());
    const item4 = GridItem(crossAxisCellCount: 4, child: SizedBox());

    final packed = packGridItems([item1, item2, item3, item4], 8);

    expect(packed, [item1, item3, item2, item4]);
  });

  test('packGridItems preserves order when already packed', () {
    const item1 = GridItem(crossAxisCellCount: 4, child: SizedBox());
    const item2 = GridItem(crossAxisCellCount: 4, child: SizedBox());
    const item3 = GridItem(crossAxisCellCount: 8, child: SizedBox());

    final packed = packGridItems([item1, item2, item3], 8);

    expect(packed, [item1, item2, item3]);
  });

  test(
    'packGridItems handles single half width with only full width remaining',
    () {
      const item1 = GridItem(crossAxisCellCount: 4, child: SizedBox());
      const item2 = GridItem(crossAxisCellCount: 8, child: SizedBox());
      const item3 = GridItem(crossAxisCellCount: 8, child: SizedBox());

      final packed = packGridItems([item1, item2, item3], 8);

      expect(packed, [item1, item2, item3]);
    },
  );

  test('packGridItems handles empty list', () {
    expect(packGridItems([], 8), isEmpty);
  });

  group('addableDashboardWidgets (T153)', () {
    test('增删面数据源不含合并卡，即使当前布局缺失它', () {
      final addable = addableDashboardWidgets([]);
      expect(addable, isNot(contains(DashboardWidget.profileMode)));
      expect(addable.where((item) => item.pinned), isEmpty);
      // The surface itself is alive: other families remain addable.
      expect(addable, contains(DashboardWidget.memoryInfo));
    });

    test('已在场的部件不重复出现，合并卡恒不出现', () {
      final addable = addableDashboardWidgets([
        DashboardWidget.profileMode,
        DashboardWidget.memoryInfo,
      ]);
      expect(addable, isNot(contains(DashboardWidget.profileMode)));
      expect(addable, isNot(contains(DashboardWidget.memoryInfo)));
      for (final item in addable) {
        expect(item, item.family);
      }
    });
  });
}
