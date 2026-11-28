import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/views/dashboard/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('尺寸表只对同组的主组件生效，无效值回退到原有尺寸', () {
    const sizes = {'networkSpeed': 'wide', 'memoryInfo': 'large'};
    expect(
      resolveDashboardSize(DashboardWidget.networkSpeed, sizes),
      DashboardTileSize.wide,
    );
    expect(
      resolveDashboardSize(DashboardWidget.networkSpeedSmall, sizes),
      DashboardTileSize.small,
    );
    expect(
      resolveDashboardSize(DashboardWidget.memoryInfo, sizes),
      DashboardTileSize.small,
    );
    expect(
      resolveDashboardSize(DashboardWidget.memoryInfo, const {
        'memoryInfo': 'tall',
      }),
      DashboardTileSize.tall,
    );
    expect(
      resolveDashboardSize(DashboardWidget.trafficUsage, const {}),
      DashboardTileSize.tall,
    );
  });

  test('原有尺寸沿用原组件，新尺寸才使用新排版', () {
    final small = buildDashboardTile((
      widget: DashboardWidget.networkSpeed,
      size: DashboardTileSize.small,
    ));
    expect(small, isA<NetworkSpeedSmall>());

    final large = buildDashboardTile((
      widget: DashboardWidget.networkSpeed,
      size: DashboardTileSize.large,
    ));
    expect(large, isA<NetworkSpeed>());
    expect((large as NetworkSpeed).size, isNull);

    final wide = buildDashboardTile((
      widget: DashboardWidget.networkSpeed,
      size: DashboardTileSize.wide,
    ));
    expect((wide as NetworkSpeed).size, DashboardTileSize.wide);

    final memory = buildDashboardTile((
      widget: DashboardWidget.memoryInfo,
      size: DashboardTileSize.small,
    ));
    expect((memory as MemoryInfo).size, isNull);

    final tallMemory = buildDashboardTile((
      widget: DashboardWidget.memoryInfo,
      size: DashboardTileSize.tall,
    ));
    expect((tallMemory as MemoryInfo).size, DashboardTileSize.tall);
  });

  test('T337：新读数卡按尺寸经 tile 构建，退役形态不在目录中', () {
    final exit = buildDashboardTile((
      widget: DashboardWidget.exitNode,
      size: DashboardTileSize.wide,
    ));
    expect(exit, isA<ExitNode>());

    final mode = buildDashboardTile((
      widget: DashboardWidget.outboundMode,
      size: DashboardTileSize.small,
    ));
    expect(mode, isA<OutboundModeCard>());

    final today = buildDashboardTile((
      widget: DashboardWidget.todayTraffic,
      size: DashboardTileSize.small,
    ));
    expect(today, isA<TodayTraffic>());

    final remaining = buildDashboardTile((
      widget: DashboardWidget.subscriptionRemaining,
      size: DashboardTileSize.small,
    ));
    expect(remaining, isA<SubscriptionRemaining>());

    final subscription = buildDashboardTile((
      widget: DashboardWidget.subscription,
      size: DashboardTileSize.wide,
    ));
    expect(subscription, isA<SubscriptionCard>());

    final names = {for (final item in DashboardWidget.values) item.name};
    // Retired shapes are gone from the catalog entirely.
    expect(names, isNot(contains('profileMode')));
    expect(names, isNot(contains('startButton')));
    // Every readout option exists as its own tile.
    expect(
      names,
      containsAll([
        'exitNode',
        'outboundMode',
        'networkSpeed',
        'networkSpeedSmall',
        'todayTraffic',
        'subscriptionRemaining',
        'subscription',
        'trafficUsage',
        'networkDetection',
        'intranetIp',
        'memoryInfo',
        'connectionsCount',
        'systemProxyButton',
        'tunButton',
      ]),
    );
  });
}
