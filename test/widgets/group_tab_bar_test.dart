import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/widgets/group_tab_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppSetting extends AppSetting {
  @override
  AppSettingProps build() => const AppSettingProps();
}

// T334 batch 3: the proxies group switcher is an orbit-dot rail —
// one dot per group on a shared line, the group name under its dot.
// These tests pin the rail's geometry contract and that tapping a
// dot drives the very same TabController the tab view swipes with
// (the switch logic and state source did not change, only the
// presentation).
void main() {
  testWidgets('rail renders every group label at the token height', (
    tester,
  ) async {
    final controller = TabController(length: 3, vsync: tester);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingProvider.overrideWith(_FakeAppSetting.new),
          isMobileViewProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          home: Material(
            child: Align(
              alignment: Alignment.topLeft,
              child: GroupTabBar(
                controller: controller,
                labels: const ['全局', 'Media', '直连'],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('全局'), findsOneWidget);
    expect(find.text('Media'), findsOneWidget);
    expect(find.text('直连'), findsOneWidget);
    expect(
      tester.getSize(find.byType(GroupTabBar)).height,
      GroupTabBar.height,
    );
    expect(GroupTabBar.height, 48);
  });

  testWidgets('tapping a dot selects its group on the same controller', (
    tester,
  ) async {
    final controller = TabController(length: 3, vsync: tester);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingProvider.overrideWith(_FakeAppSetting.new),
          isMobileViewProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          home: Material(
            child: Align(
              alignment: Alignment.topLeft,
              child: GroupTabBar(
                controller: controller,
                labels: const ['全局', 'Media', '直连'],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('直连'));
    await tester.pumpAndSettle();
    expect(controller.index, 2);

    await tester.tap(find.text('全局'));
    await tester.pumpAndSettle();
    expect(controller.index, 0);
  });
}
