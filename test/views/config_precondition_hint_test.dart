import 'package:bett_box/common/common.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/config/dns.dart';
import 'package:bett_box/views/config/general.dart';
import 'package:bett_box/widgets/info_hint.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// T89 D-02/D-03/D-04: settings whose effect is gated by a precondition
// elsewhere (allow-lan, the DNS mode, the direct nameserver list) must
// state that precondition in their implicit explanation, so a value
// that currently cannot take effect never looks silently broken.
//
// Widget tests assert the row composition against the localization
// getters (the material_ui harness resolves its own locale, like the
// D-01 tests); the shipped zh_CN/en literals are pinned separately in
// the catalog group below.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => AppLocalizations.load(const Locale('zh', 'CN')));

  setUp(() {
    globalState.config = Config(
      themeProps: defaultThemeProps,
      patchClashConfig: defaultClashConfig,
    );
    globalState.appState = AppState(
      brightness: Brightness.light,
      version: 0,
      viewSize: const Size(400, 800),
      requests: FixedList(maxLength),
      logs: FixedList(maxLogLength),
      traffics: FixedList(30),
      totalTraffic: Traffic(),
      systemUiOverlayStyle: const SystemUiOverlayStyle(),
    );
  });

  Future<void> pumpSurface(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: globalState.navigatorKey,
          localizationsDelegates: const [AppLocalizations.delegate],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                globalState.measure = Measure.of(context, 1);
                return child;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  InfoTitle singleTitle(WidgetTester tester, String text) {
    return tester
        .widgetList<InfoTitle>(find.byType(InfoTitle))
        .singleWhere((title) => title.text == text);
  }

  group('T89 D-02/D-03 general rows carry precondition explanations', () {
    testWidgets('bind address', (tester) async {
      await pumpSurface(tester, const BindAddressItem());
      final title = singleTitle(tester, appLocalizations.bindAddress);
      expect(
        title.info,
        '${appLocalizations.bindAddressInfo}\n'
        '${appLocalizations.coreRestartHint}',
      );
    });

    testWidgets('allowed IPs', (tester) async {
      await pumpSurface(tester, const LanAllowedIpsItem());
      final title = singleTitle(tester, appLocalizations.lanAllowedIps);
      expect(
        title.info,
        '${appLocalizations.lanAllowedIpsInfo}\n'
        '${appLocalizations.coreRestartHint}',
      );
    });

    testWidgets('disallowed IPs', (tester) async {
      await pumpSurface(tester, const LanDisallowedIpsItem());
      final title = singleTitle(tester, appLocalizations.lanDisallowedIps);
      expect(
        title.info,
        '${appLocalizations.lanDisallowedIpsInfo}\n'
        '${appLocalizations.coreRestartHint}',
      );
    });

    testWidgets('store-fake-ip', (tester) async {
      await pumpSurface(tester, const StoreFakeIpItem());
      final title = singleTitle(tester, appLocalizations.storeFakeIp);
      expect(
        title.info,
        '${appLocalizations.storeFakeIpInfo}\n'
        '${appLocalizations.coreRestartHint}',
      );
    });
  });

  group('T89 D-04 follow-policy states its object precondition', () {
    testWidgets('row carries the explanation once a direct server exists', (
      tester,
    ) async {
      globalState.config = Config(
        themeProps: defaultThemeProps,
        patchClashConfig: defaultClashConfig.copyWith.dns(
          directNameserver: const ['223.5.5.5'],
        ),
      );
      await pumpSurface(tester, const DirectNameserverFollowPolicyItem());
      final title = singleTitle(
        tester,
        appLocalizations.directNameserverFollowPolicy,
      );
      expect(title.info, appLocalizations.directNameserverFollowPolicyInfo);
    });

    testWidgets('row stays hidden while the direct list is empty', (
      tester,
    ) async {
      await pumpSurface(tester, const DirectNameserverFollowPolicyItem());
      expect(find.byType(InfoTitle), findsNothing);
    });
  });

  group('T89 D-02/D-03/D-04 shipped literals state the preconditions', () {
    test('zh_CN catalog', () async {
      await AppLocalizations.load(const Locale('zh', 'CN'));
      final l = appLocalizations;
      // D-02: LAN lists and bind address vs allow-lan / loopback bind.
      expect(l.bindAddressInfo, contains('局域网连接关闭时'));
      expect(l.lanAllowedIpsInfo, contains('局域网连接开启时生效'));
      expect(l.lanAllowedIpsInfo, contains('绑定地址选仅本机时'));
      expect(l.lanDisallowedIpsInfo, contains('局域网连接开启时生效'));
      // D-03: store-fake-ip only matters in FakeIP mode.
      expect(l.storeFakeIpInfo, contains('仅在 DNS 模式为 FakeIP 时有意义'));
      // D-04: follow-policy has no object while the list is empty.
      expect(l.directNameserverFollowPolicyInfo, contains('直连域名服务器为空时'));
    });

    test('en catalog', () async {
      await AppLocalizations.load(const Locale('en'));
      final l = appLocalizations;
      expect(l.bindAddressInfo, contains('LAN connections off'));
      expect(
        l.lanAllowedIpsInfo,
        contains('while LAN connections are enabled'),
      );
      expect(l.lanAllowedIpsInfo, contains('bind address is this device only'));
      expect(
        l.lanDisallowedIpsInfo,
        contains('while LAN connections are enabled'),
      );
      expect(
        l.storeFakeIpInfo,
        contains('Only meaningful when the DNS mode is Fake-IP'),
      );
      expect(
        l.directNameserverFollowPolicyInfo,
        contains('hidden while that list is empty'),
      );
    });
  });
}
