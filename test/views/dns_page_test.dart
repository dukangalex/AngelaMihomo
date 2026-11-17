import 'dart:convert';

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/l10n/l10n.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/config/dns.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// T129: the restored DNS page renders the full capability set in the
/// app's own section layout, and its switches write back into the single
/// sources of truth — the 覆写 DNS flag into Config (which the setup
/// params forward to the core as `override-dns`) and the DNS fields into
/// patchClashConfig.dns (which the setup params emit as the `dns` section).
void main() {
  setUpAll(() async {
    await AppLocalizations.load(const Locale('zh', 'CN'));
  });

  setUp(() {
    globalState.appState = AppState(
      brightness: Brightness.light,
      version: 0,
      viewSize: Size.zero,
      requests: FixedList(maxLength),
      logs: FixedList(maxLogLength),
      traffics: FixedList(30),
      totalTraffic: Traffic(),
      systemUiOverlayStyle: const SystemUiOverlayStyle(),
    );
    globalState.config = Config(themeProps: defaultThemeProps);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: DnsListView())),
      ),
    );
    await tester.pump();
  }

  testWidgets('DNS 页含覆写开关、选项段与 Fallback 过滤段', (tester) async {
    await pumpPage(tester);
    expect(find.text('覆写 DNS'), findsOneWidget);
    expect(find.text('选项'), findsOneWidget);
    expect(find.text('状态'), findsOneWidget);
    expect(find.text('监听'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('域名服务器'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('域名服务器'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Fallback过滤'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Fallback过滤'), findsOneWidget);
  });

  testWidgets('覆写开关写回 Config.overrideDns', (tester) async {
    await pumpPage(tester);
    expect(globalState.config.overrideDns, isFalse);
    final toggle = find.descendant(
      of: find.byType(OverrideDnsItem),
      matching: find.byType(Switch),
    );
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pump();
    expect(globalState.config.overrideDns, isTrue);
  });

  testWidgets('状态开关写回 patchClashConfig.dns.enable', (tester) async {
    globalState.config = globalState.config.copyWith(
      patchClashConfig: defaultClashConfig.copyWith(
        dns: defaultDns.copyWith(enable: false),
      ),
    );
    await pumpPage(tester);
    final toggle = find.descendant(
      of: find.byType(StatusItem),
      matching: find.byType(Switch),
    );
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pump();
    expect(globalState.config.patchClashConfig.dns.enable, isTrue);
  });

  test('Config 的 overrideDns 参与 JSON 往返', () {
    final config = Config(
      themeProps: defaultThemeProps,
    ).copyWith(overrideDns: true);
    expect(config.toJson()['overrideDns'], isTrue);
    final restored = Config.fromJson(
      jsonDecode(jsonEncode(config.toJson())) as Map<String, dynamic>,
    );
    expect(restored.overrideDns, isTrue);
  });
}
