import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/toolbox.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(WidgetTester tester, List<String> tiles) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  globalState.appState = AppState(
    brightness: Brightness.light,
    version: 0,
    viewSize: const Size(400, 900),
    requests: FixedList(maxLength),
    logs: FixedList(maxLogLength),
    traffics: FixedList(30),
    totalTraffic: Traffic(),
    systemUiOverlayStyle: const SystemUiOverlayStyle(),
  );
  globalState.config = Config(
    themeProps: defaultThemeProps,
    appSetting: AppSettingProps(toolboxTiles: tiles),
    proxiesStyle: const ProxiesStyle(layout: ProxiesLayout.standard),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [viewWidthProvider.overrideWithValue(400)],
      child: MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Builder(
          builder: (context) {
            globalState.measure = Measure.of(context, 1);
            return const ToolboxView();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('默认布局：测速横跨两列，其余为小卡两列排布', (tester) async {
    await _pump(tester, const []);
    Rect card(String title) => tester.getRect(
      find.ancestor(of: find.text(title), matching: find.byType(CommonCard)),
    );
    final speed = card(appLocalizations.speedTest);
    final ip = card(appLocalizations.ipLookup);
    final dns = card(appLocalizations.dnsQuery);
    final nat = card(appLocalizations.natTest);
    final ping = card(appLocalizations.localPing);
    final age = card(appLocalizations.ageTool);
    expect(speed.width, greaterThan(ip.width * 1.9));
    expect(ip.top, greaterThan(speed.bottom));
    expect(dns.top, ip.top);
    expect(dns.left, greaterThan(ip.left));
    expect(nat.left, ip.left);
    expect(nat.top, greaterThan(ip.bottom));
    expect(ping.top, nat.top);
    expect(age.left, ip.left);
    expect(age.top, greaterThan(nat.bottom));
    expect(find.byIcon(Icons.speed_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.route_rounded), findsNothing);
    expect(find.byIcon(Icons.manage_search_rounded), findsNothing);
    expect(find.byIcon(Icons.dns_rounded), findsOneWidget);
  });

  testWidgets('按保存的布局排列并恢复尺寸', (tester) async {
    await _pump(tester, ['natTest:wide', 'speedTest:tall', 'unknown:wide']);
    final nat = tester.getSize(
      find.ancestor(
        of: find.text(appLocalizations.natTest),
        matching: find.byType(CommonCard),
      ),
    );
    final speed = tester.getSize(
      find.ancestor(
        of: find.text(appLocalizations.speedTest),
        matching: find.byType(CommonCard),
      ),
    );
    final age = tester.getSize(
      find.ancestor(
        of: find.text(appLocalizations.ageTool),
        matching: find.byType(CommonCard),
      ),
    );
    expect(nat.width, greaterThan(age.width * 1.9));
    expect(speed.height, greaterThan(age.height * 1.9));
    expect(
      tester.getTopLeft(find.text(appLocalizations.natTest)).dy,
      lessThan(tester.getTopLeft(find.text(appLocalizations.speedTest)).dy),
    );
  });

  testWidgets('编辑模式下点按卡片依次切换尺寸并保存', (tester) async {
    await _pump(tester, const []);
    final tip = system.isDesktop
        ? appLocalizations.toolboxEditTipDesktop
        : appLocalizations.toolboxEditTip;
    await tester.tap(find.byIcon(Icons.dashboard_customize_outlined));
    await tester.pump(const Duration(milliseconds: 500));
    tester.takeException();
    expect(find.text(tip), findsOneWidget);

    await tester.tap(find.text(appLocalizations.dnsQuery));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      globalState.config.appSetting.toolboxTiles,
      contains('dnsQuery:wide'),
    );
    await tester.tap(find.text(appLocalizations.dnsQuery));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      globalState.config.appSetting.toolboxTiles,
      contains('dnsQuery:tall'),
    );

    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();
    tester.takeException();
    expect(find.text(tip), findsNothing);
  });
}
