import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/views/dashboard/widgets/tile.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Harness extends StatefulWidget {
  final bool editing;
  final List<String> log;

  const _Harness({required this.editing, required this.log});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  List<String> items = ['A', 'B', 'C', 'D'];
  final wide = <String>{};

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: EditableGrid<String>(
            items: items,
            editing: widget.editing,
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 108,
            keyOf: (item) => item,
            crossAxisCellCountOf: (item) => wide.contains(item) ? 2 : 1,
            mainAxisCellCountOf: (_) => 1,
            itemBuilder: (_, item) => ColoredBox(
              color: Colors.blueGrey,
              child: Center(child: Text(item)),
            ),
            canResize: (item) => item != 'D',
            onResize: (item) {
              widget.log.add('resize $item');
              setState(
                () => wide.contains(item) ? wide.remove(item) : wide.add(item),
              );
            },
            canDelete: (item) => item != 'A',
            onDelete: (item) {
              widget.log.add('delete $item');
              setState(() => items = [...items]..remove(item));
            },
            canMove: (item) => item != 'C',
            onMove: (from, to) {
              widget.log.add('move $from>$to');
              setState(() {
                final next = [...items];
                next.insert(
                  next.indexOf(to),
                  next.removeAt(next.indexOf(from)),
                );
                items = next;
              });
            },
            onLongPress: () => widget.log.add('longPress'),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('普通模式长按触发进入编辑', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(_Harness(editing: false, log: log));
    await tester.longPress(find.text('B'));
    expect(log, ['longPress']);
    expect(find.byIcon(Icons.open_in_full_rounded), findsNothing);
  });

  testWidgets('编辑模式点按切换尺寸并带过渡、删除角标仅出现在可删除项', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(_Harness(editing: true, log: log));
    await tester.pump();
    expect(find.byIcon(Icons.open_in_full_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.close_rounded), findsNWidgets(3));

    final before = tester.getTopLeft(find.text('C'));
    await tester.tap(find.text('B'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(log, ['resize B']);
    final moving = tester.getTopLeft(find.text('C'));
    await tester.pump(const Duration(milliseconds: 600));
    final after = tester.getTopLeft(find.text('C'));
    expect(after, isNot(before));
    expect(moving, isNot(after));

    await tester.tap(
      find.byIcon(Icons.close_rounded).last,
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(log.last, 'delete D');
    expect(find.text('D'), findsNothing);
  });

  testWidgets('编辑模式拖动到其他卡片上会调整顺序', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(_Harness(editing: true, log: log));
    await tester.pump();
    final gesture = await tester.startGesture(tester.getCenter(find.text('A')));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(10, 10));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('D').first));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 600));
    expect(log, contains('move A>D'));
  });

  testWidgets('不可移动项既不能被拖动、也不能被拖到其上（T153）', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(_Harness(editing: true, log: log));
    await tester.pump();

    // Dragging another tile onto the immovable one must not move it.
    final onto = await tester.startGesture(tester.getCenter(find.text('B')));
    await tester.pump(const Duration(milliseconds: 600));
    await onto.moveBy(const Offset(10, 10));
    await tester.pump();
    await onto.moveTo(tester.getCenter(find.text('C').first));
    await tester.pump(const Duration(milliseconds: 100));
    await onto.up();
    await tester.pump(const Duration(milliseconds: 600));
    expect(log.where((entry) => entry.startsWith('move')), isEmpty);

    // The immovable tile itself cannot be picked up.
    final from = await tester.startGesture(tester.getCenter(find.text('C')));
    await tester.pump(const Duration(milliseconds: 600));
    await from.moveBy(const Offset(10, 10));
    await tester.pump();
    await from.moveTo(tester.getCenter(find.text('B').first));
    await tester.pump(const Duration(milliseconds: 100));
    await from.up();
    await tester.pump(const Duration(milliseconds: 600));
    expect(log.where((entry) => entry.startsWith('move')), isEmpty);
  });

  testWidgets('编辑态：合并卡无删除叉无缩放柄，其它部件两者俱在（T153）', (tester) async {
    // Wired with the same predicate expressions DashboardView uses.
    const tiles = <DashboardTile>[
      (widget: DashboardWidget.profileMode, size: DashboardTileSize.large),
      (widget: DashboardWidget.memoryInfo, size: DashboardTileSize.small),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: EditableGrid<DashboardTile>(
              items: tiles,
              editing: true,
              crossAxisCount: 8,
              mainAxisExtent: 108,
              keyOf: (tile) => tile.widget.family,
              crossAxisCellCountOf: (tile) => tile.size.cross * 4,
              itemBuilder: (_, tile) => ColoredBox(
                color: Colors.blueGrey,
                child: Center(child: Text(tile.widget.name)),
              ),
              canResize: (tile) => tile.widget.resizable,
              onResize: (_) {},
              canDelete: (tile) => tile.widget.widget.isDeletable,
              onDelete: (_) {},
              canMove: (tile) => !tile.widget.pinned,
              onMove: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Exactly one of each badge exists, and both sit on the memory
    // tile's row (below the merged card's label), not on the merged
    // card.
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);
    final mergedLabelY = tester.getCenter(find.text('profileMode')).dy;
    expect(
      tester.getCenter(find.byIcon(Icons.close_rounded)).dy,
      greaterThan(mergedLabelY),
    );
    expect(
      tester.getCenter(find.byIcon(Icons.open_in_full_rounded)).dy,
      greaterThan(mergedLabelY),
    );
  });

  test('仪表盘组件按组归并并提供可选尺寸', () {
    expect(
      DashboardWidget.networkSpeedSmall.family,
      DashboardWidget.networkSpeed,
    );
    expect(DashboardWidget.profileMode.family, DashboardWidget.profileMode);
    // T153: the merged card is pinned — fixed native size, not
    // resizable, not deletable; other widgets keep their affordances.
    expect(DashboardWidget.profileMode.sizes, [DashboardTileSize.large]);
    expect(DashboardWidget.profileMode.resizable, isFalse);
    expect(DashboardWidget.profileMode.pinned, isTrue);
    expect(DashboardWidget.profileMode.widget.isDeletable, isFalse);
    expect(DashboardWidget.memoryInfo.pinned, isFalse);
    expect(DashboardWidget.memoryInfo.widget.isDeletable, isTrue);
    expect(DashboardWidget.networkSpeed.sizes, [
      DashboardTileSize.small,
      DashboardTileSize.wide,
      DashboardTileSize.tall,
      DashboardTileSize.large,
    ]);
    expect(
      DashboardWidget.networkSpeed.variantFor(DashboardTileSize.small),
      DashboardWidget.networkSpeedSmall,
    );
    expect(
      DashboardWidget.networkSpeed.variantFor(DashboardTileSize.wide),
      DashboardWidget.networkSpeed,
    );
    expect(DashboardWidget.trafficUsage.sizes, [
      DashboardTileSize.tall,
      DashboardTileSize.wide,
    ]);
    expect(DashboardWidget.memoryInfo.resizable, isTrue);
    expect(DashboardWidget.ipv6Switch.resizable, isFalse);
  });
}
