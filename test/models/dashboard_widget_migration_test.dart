import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/views/dashboard/widgets/tile.dart';
import 'package:flutter_test/flutter_test.dart';

/// T147: layouts saved before the profile/mode merge name the old
/// widgets. Decoding must synthesize the merged widget exactly once,
/// at the position of the first old widget, keep every other widget,
/// and carry the size over with the documented mapping.
void main() {
  test('旧部件名解码为合并部件，取首个旧部件的位置且只出现一次', () {
    final widgets = dashboardWidgetsSafeFromJson([
      'networkSpeed',
      'profileInfo',
      'memoryInfo',
      'outboundModeV2',
      'outboundMode',
    ]);
    expect(widgets, [
      DashboardWidget.networkSpeed,
      DashboardWidget.profileMode,
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

  test('未知名称丢弃、其余部件不受影响', () {
    expect(dashboardWidgetsSafeFromJson(['bogus', 'memoryInfo']), [
      DashboardWidget.memoryInfo,
    ]);
  });

  test('新名称正常解码且不重复合成', () {
    expect(dashboardWidgetsSafeFromJson(['profileMode', 'profileInfo']), [
      DashboardWidget.profileMode,
    ]);
  });

  test('尺寸迁移：配置卡 tall 沿用，旧键删除，其它部件尺寸保留', () {
    final props = AppSettingProps.safeFromJson({
      'mobileDashboardSizes': {
        'profileInfo': 'tall',
        'networkSpeed': 'wide',
      },
      'desktopDashboardSizes': {'outboundModeV2': 'tall'},
    });
    expect(props.mobileDashboardSizes, {
      'networkSpeed': 'wide',
      'profileMode': 'tall',
    });
    expect(props.desktopDashboardSizes, {'profileMode': 'tall'});
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
}
