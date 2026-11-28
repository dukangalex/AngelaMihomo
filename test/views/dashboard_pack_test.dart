import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/views/dashboard/dashboard.dart';
import 'package:angelamihomo/widgets/grid.dart';
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

  group('addableDashboardWidgets (T337)', () {
    test('增删面含全部现存目录部件，退役形态无从加回', () {
      final addable = addableDashboardWidgets([]);
      final names = {for (final item in addable) item.name};
      expect(names, isNot(contains('profileMode')));
      expect(names, isNot(contains('startButton')));
      // Every readout option is addable — the user has the final say.
      expect(addable, contains(DashboardWidget.exitNode));
      expect(addable, contains(DashboardWidget.outboundMode));
      expect(addable, contains(DashboardWidget.networkSpeed));
      expect(addable, contains(DashboardWidget.trafficUsage));
      expect(addable, contains(DashboardWidget.todayTraffic));
      expect(addable, contains(DashboardWidget.subscriptionRemaining));
      expect(addable, contains(DashboardWidget.subscription));
      expect(addable, contains(DashboardWidget.memoryInfo));
      expect(addable, contains(DashboardWidget.networkDetection));
    });

    test('已在场的部件不重复出现', () {
      final addable = addableDashboardWidgets([
        DashboardWidget.memoryInfo,
        DashboardWidget.connectionsCount,
      ]);
      expect(addable, isNot(contains(DashboardWidget.memoryInfo)));
      expect(addable, isNot(contains(DashboardWidget.connectionsCount)));
      for (final item in addable) {
        expect(item, item.family);
      }
    });
  });
}
