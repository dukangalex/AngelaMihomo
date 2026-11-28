import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppSetting extends AppSetting {
  _FakeAppSetting(this.widgets);

  final List<DashboardWidget> widgets;

  @override
  AppSettingProps build() => AppSettingProps(
    mobileDashboardWidgets: widgets,
    desktopDashboardWidgets: widgets,
  );
}

DashboardState _readState(List<DashboardWidget> widgets) {
  final container = ProviderContainer(
    overrides: [
      appSettingProvider.overrideWith(() => _FakeAppSetting(widgets)),
      viewWidthProvider.overrideWith((ref) => 400),
    ],
  );
  addTearDown(container.dispose);
  return container.read(dashboardStateProvider);
}

void main() {
  group('dashboardState', () {
    // T337: the state presents the saved layout exactly as it is.
    // The start-button tile it used to force-append was retired
    // into the hero core, so nothing is synthesized any more.
    test('presents the saved layout exactly, in order', () {
      final state = _readState([
        DashboardWidget.memoryInfo,
        DashboardWidget.networkDetection,
        DashboardWidget.connectionsCount,
      ]);
      expect(state.dashboardWidgets, [
        DashboardWidget.memoryInfo,
        DashboardWidget.networkDetection,
        DashboardWidget.connectionsCount,
      ]);
    });

    test('appends nothing when the layout is short', () {
      final state = _readState([DashboardWidget.memoryInfo]);
      expect(state.dashboardWidgets, [DashboardWidget.memoryInfo]);
    });

    test('an empty layout stays empty', () {
      final state = _readState(const []);
      expect(state.dashboardWidgets, isEmpty);
    });
  });
}
