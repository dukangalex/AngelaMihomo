import 'dart:convert';

import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/views/dashboard/widgets/tile.dart';
import 'package:flutter_test/flutter_test.dart';

/// T337 (fusion): every readout is a tile again and the catalog
/// is complete — but two shapes stay retired. profileMode (the
/// T147 merge of profileInfo / outboundMode / outboundModeV2)
/// was fused away into separate tiles (exitNode, outboundMode,
/// subscription), and startButton's home is the hero's power
/// core. Layouts saved with any of those names decode by
/// dropping them; every surviving widget — including the
/// restored networkSpeed / trafficUsage tiles — keeps its saved
/// relative order. (This supersedes the T147/T153 expectations,
/// under which the merged card was synthesized and pinned.)
void main() {
  test('退役部件名解码时丢弃，保留部件原序不变', () {
    final widgets = dashboardWidgetsSafeFromJson([
      'networkSpeed',
      'profileInfo',
      'memoryInfo',
      'outboundModeV2',
      'outboundMode',
      'profileMode',
      'startButton',
      'trafficUsage',
      'connectionsCount',
    ]);
    expect(widgets, [
      DashboardWidget.networkSpeed,
      DashboardWidget.memoryInfo,
      DashboardWidget.trafficUsage,
      DashboardWidget.connectionsCount,
    ]);
  });

  test('只有退役名时解码为空布局，不再合成任何部件', () {
    expect(dashboardWidgetsSafeFromJson(['profileMode']), isEmpty);
    expect(dashboardWidgetsSafeFromJson(['outboundMode']), isEmpty);
    expect(dashboardWidgetsSafeFromJson(['startButton']), isEmpty);
  });

  test('未知名称丢弃、其余部件不受影响', () {
    expect(dashboardWidgetsSafeFromJson(['bogus', 'memoryInfo']), [
      DashboardWidget.memoryInfo,
    ]);
  });

  test('尺寸归一化：退役键删除，保留部件尺寸原样', () {
    final props = AppSettingProps.safeFromJson({
      'mobileDashboardSizes': {
        'profileInfo': 'tall',
        'profileMode': 'tall',
        'networkSpeed': 'wide',
        'networkDetection': 'tall',
      },
      'desktopDashboardSizes': {
        'outboundModeV2': 'tall',
        'startButton': 'small',
        'memoryInfo': 'wide',
      },
    });
    expect(props.mobileDashboardSizes, {
      'networkSpeed': 'wide',
      'networkDetection': 'tall',
    });
    expect(props.desktopDashboardSizes, {'memoryInfo': 'wide'});
    // Surviving widgets' saved sizes still resolve as saved.
    expect(
      resolveDashboardSize(
        DashboardWidget.networkSpeed,
        props.mobileDashboardSizes,
      ),
      DashboardTileSize.wide,
    );
  });

  test('无退役键时尺寸表原样保留', () {
    final props = AppSettingProps.safeFromJson({
      'mobileDashboardSizes': {'networkSpeed': 'wide'},
    });
    expect(props.mobileDashboardSizes, {'networkSpeed': 'wide'});
  });

  test('幂等：解码结果再解码不变', () {
    final once = dashboardWidgetsSafeFromJson([
      'networkSpeed',
      'profileInfo',
      'memoryInfo',
      'profileMode',
    ]);
    final twice = dashboardWidgetsSafeFromJson([
      for (final widget in once) widget.name,
    ]);
    expect(twice, once);
    expect(once, [DashboardWidget.networkSpeed, DashboardWidget.memoryInfo]);

    final propsOnce = AppSettingProps.safeFromJson({
      'mobileDashboardWidgets': ['memoryInfo', 'profileMode'],
      'mobileDashboardSizes': {'profileMode': 'tall', 'networkSpeed': 'wide'},
    });
    // Round-trip through real JSON, as the persisted config does.
    final propsTwice = AppSettingProps.safeFromJson(
      jsonDecode(jsonEncode(propsOnce.toJson())) as Map<String, Object?>,
    );
    expect(propsTwice.mobileDashboardWidgets, propsOnce.mobileDashboardWidgets);
    expect(propsTwice.mobileDashboardSizes, propsOnce.mobileDashboardSizes);
    expect(propsOnce.mobileDashboardWidgets, [DashboardWidget.memoryInfo]);
    expect(propsOnce.mobileDashboardSizes, {'networkSpeed': 'wide'});
  });

  test('默认布局：每项读数只出现一次，按利于显示的顺序', () {
    expect(defaultDashboardWidgets, [
      DashboardWidget.exitNode,
      DashboardWidget.networkSpeed,
      DashboardWidget.todayTraffic,
      DashboardWidget.subscriptionRemaining,
      DashboardWidget.outboundMode,
      DashboardWidget.subscription,
      DashboardWidget.systemProxyButton,
      DashboardWidget.tunButton,
      DashboardWidget.networkDetection,
      DashboardWidget.intranetIp,
      DashboardWidget.memoryInfo,
      DashboardWidget.connectionsCount,
    ]);
    expect(defaultAndroidDashboardWidgets, [
      DashboardWidget.exitNode,
      DashboardWidget.networkSpeed,
      DashboardWidget.todayTraffic,
      DashboardWidget.subscriptionRemaining,
      DashboardWidget.outboundMode,
      DashboardWidget.subscription,
    ]);
    // The standalone traffic tile is an option, not a default:
    // its numbers already show inside the subscription card.
    expect(
      defaultDashboardWidgets,
      isNot(contains(DashboardWidget.trafficUsage)),
    );
    expect(
      defaultAndroidDashboardWidgets,
      isNot(contains(DashboardWidget.trafficUsage)),
    );
    expect(dashboardWidgetsSafeFromJson(null), isNotEmpty);
  });
}
