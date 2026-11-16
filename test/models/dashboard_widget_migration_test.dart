import 'dart:convert';

import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/views/dashboard/widgets/tile.dart';
import 'package:flutter_test/flutter_test.dart';

/// T147: layouts saved before the profile/mode merge name the old
/// widgets. Decoding must synthesize the merged widget exactly once
/// and keep every other widget.
/// T153: the merged widget is pinned — decoding normalizes every
/// layout to exactly one merged widget at the head, at its fixed
/// native size, whatever state the saved layout was left in. The
/// T147-era expectations about position (first legacy slot) and size
/// (tall carried over) are superseded by the pin and updated here.
void main() {
  test('旧部件名解码为合并部件，只出现一次且归位首位（T153）', () {
    final widgets = dashboardWidgetsSafeFromJson([
      'networkSpeed',
      'profileInfo',
      'memoryInfo',
      'outboundModeV2',
      'outboundMode',
    ]);
    expect(widgets, [
      DashboardWidget.profileMode,
      DashboardWidget.networkSpeed,
      DashboardWidget.memoryInfo,
    ]);
  });

  test('只有模式旧部件时同样合成为合并部件', () {
    expect(dashboardWidgetsSafeFromJson(['outboundMode']), [
      DashboardWidget.profileMode,
    ]);
    expect(dashboardWidgetsSafeFromJson(['outboundModeV2']), [
      DashboardWidget.profileMode,
    ]);
  });

  test('未知名称丢弃、其余部件不受影响（合并卡按 T153 补回首位）', () {
    expect(dashboardWidgetsSafeFromJson(['bogus', 'memoryInfo']), [
      DashboardWidget.profileMode,
      DashboardWidget.memoryInfo,
    ]);
  });

  test('新名称正常解码且不重复合成', () {
    expect(dashboardWidgetsSafeFromJson(['profileMode', 'profileInfo']), [
      DashboardWidget.profileMode,
    ]);
  });

  test('尺寸归一化：旧键删除、合并卡不写尺寸条目，其它部件尺寸保留（T153）', () {
    final props = AppSettingProps.safeFromJson({
      'mobileDashboardSizes': {
        'profileInfo': 'tall',
        'networkSpeed': 'wide',
      },
      'desktopDashboardSizes': {'outboundModeV2': 'tall'},
    });
    expect(props.mobileDashboardSizes, {'networkSpeed': 'wide'});
    expect(props.desktopDashboardSizes, isEmpty);
    expect(
      resolveDashboardSize(
        DashboardWidget.profileMode,
        props.mobileDashboardSizes,
      ),
      DashboardTileSize.large,
    );
  });

  test('尺寸迁移：wide 无合并对应尺寸，回退原生 large（不写条目）', () {
    final props = AppSettingProps.safeFromJson({
      'mobileDashboardSizes': {'profileInfo': 'wide'},
      'desktopDashboardSizes': {'outboundModeV2': 'wide'},
    });
    expect(props.mobileDashboardSizes, isEmpty);
    expect(props.desktopDashboardSizes, isEmpty);
    expect(
      resolveDashboardSize(
        DashboardWidget.profileMode,
        props.mobileDashboardSizes,
      ),
      DashboardTileSize.large,
    );
  });

  test('无旧键时尺寸表原样保留', () {
    final props = AppSettingProps.safeFromJson({
      'mobileDashboardSizes': {'networkSpeed': 'wide'},
    });
    expect(props.mobileDashboardSizes, {'networkSpeed': 'wide'});
  });

  group('T153 归一化四用例', () {
    test('缺失：合并卡补回首位，其余顺序不变', () {
      expect(
        dashboardWidgetsSafeFromJson(['networkSpeed', 'memoryInfo']),
        [
          DashboardWidget.profileMode,
          DashboardWidget.networkSpeed,
          DashboardWidget.memoryInfo,
        ],
      );
      expect(
        mobileDashboardWidgetsSafeFromJson(['memoryInfo']),
        [DashboardWidget.profileMode, DashboardWidget.memoryInfo],
      );
      expect(
        desktopDashboardWidgetsSafeFromJson(['memoryInfo']),
        [DashboardWidget.profileMode, DashboardWidget.memoryInfo],
      );
    });

    test('重复：只留一张且居首', () {
      expect(
        dashboardWidgetsSafeFromJson([
          'profileMode',
          'memoryInfo',
          'profileMode',
        ]),
        [DashboardWidget.profileMode, DashboardWidget.memoryInfo],
      );
    });

    test('错位：归位首位，其余相对顺序不变', () {
      expect(
        dashboardWidgetsSafeFromJson([
          'networkSpeed',
          'memoryInfo',
          'profileMode',
          'connectionsCount',
        ]),
        [
          DashboardWidget.profileMode,
          DashboardWidget.networkSpeed,
          DashboardWidget.memoryInfo,
          DashboardWidget.connectionsCount,
        ],
      );
    });

    test('被缩放：存量 profileMode 尺寸条目被清除、解析回固定 large', () {
      final props = AppSettingProps.safeFromJson({
        'mobileDashboardSizes': {
          'profileMode': 'tall',
          'networkSpeed': 'wide',
        },
        'desktopDashboardSizes': {'profileMode': 'tall'},
      });
      expect(props.mobileDashboardSizes, {'networkSpeed': 'wide'});
      expect(props.desktopDashboardSizes, isEmpty);
      expect(
        resolveDashboardSize(
          DashboardWidget.profileMode,
          props.mobileDashboardSizes,
        ),
        DashboardTileSize.large,
      );
      // Other widgets' saved sizes resolve untouched.
      expect(
        resolveDashboardSize(
          DashboardWidget.networkSpeed,
          props.mobileDashboardSizes,
        ),
        DashboardTileSize.wide,
      );
    });

    test('幂等：归一化结果再解码不变', () {
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

      final propsOnce = AppSettingProps.safeFromJson({
        'mobileDashboardWidgets': ['memoryInfo', 'profileMode'],
        'mobileDashboardSizes': {
          'profileMode': 'tall',
          'networkSpeed': 'wide',
        },
      });
      // Round-trip through real JSON, as the persisted config does.
      final propsTwice = AppSettingProps.safeFromJson(
        jsonDecode(jsonEncode(propsOnce.toJson())) as Map<String, Object?>,
      );
      expect(
        propsTwice.mobileDashboardWidgets,
        propsOnce.mobileDashboardWidgets,
      );
      expect(propsTwice.mobileDashboardSizes, propsOnce.mobileDashboardSizes);
      expect(propsOnce.mobileDashboardWidgets.first, DashboardWidget.profileMode);
      expect(propsOnce.mobileDashboardSizes, {'networkSpeed': 'wide'});
    });

    test('默认布局：合并卡居首', () {
      expect(defaultDashboardWidgets.first, DashboardWidget.profileMode);
      expect(
        defaultAndroidDashboardWidgets.first,
        DashboardWidget.profileMode,
      );
      expect(dashboardWidgetsSafeFromJson(null).first, DashboardWidget.profileMode);
    });
  });
}
