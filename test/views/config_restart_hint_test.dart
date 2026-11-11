import 'package:bett_box/common/common.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/config/config.dart';
import 'package:bett_box/views/config/experimental.dart';
import 'package:bett_box/views/config/ntp.dart';
import 'package:bett_box/views/config/sniffer.dart';
import 'package:bett_box/views/config/tunnel.dart';
import 'package:bett_box/widgets/info_hint.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// T89 D-01: the ntp / sniffer / experimental sections, tunnels, and
// hosts are outside the hot-update projection and the needSetup watch,
// so their editing surfaces must carry the same coreRestartHint
// annotation the general page uses for its non-projected fields (P-5).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => AppLocalizations.load(const Locale('zh', 'CN')));

  setUp(() {
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

  List<InfoTitle> infoTitles(WidgetTester tester) =>
      tester.widgetList<InfoTitle>(find.byType(InfoTitle)).toList();

  group('T89 D-01 section pages carry the restart annotation', () {
    testWidgets('every NTP item is annotated', (tester) async {
      await pumpSurface(tester, const NtpListView());
      final titles = infoTitles(tester);
      expect(titles, hasLength(6));
      for (final title in titles) {
        expect(title.info, contains(appLocalizations.coreRestartHint));
      }
      // Items without their own info text carry exactly the hint.
      final status = titles.singleWhere(
        (title) => title.text == appLocalizations.ntpStatus,
      );
      expect(status.info, appLocalizations.coreRestartHint);
      // The dialer-proxy item appends the hint after its own info.
      final dialer = titles.singleWhere(
        (title) => title.text == appLocalizations.ntpDialerProxy,
      );
      expect(
        dialer.info,
        '${appLocalizations.ntpDialerProxyInfo}\n'
        '${appLocalizations.coreRestartHint}',
      );
      // The dialer-proxy item's one-shot core lookup leaves a pending
      // bridge timer in the test environment; flush it before teardown.
      await tester.pump(const Duration(minutes: 5));
    });

    testWidgets('every sniffer item is annotated', (tester) async {
      await pumpSurface(tester, const SnifferListView());
      final titles = infoTitles(tester);
      expect(titles, hasLength(12));
      for (final title in titles) {
        expect(title.info, contains(appLocalizations.coreRestartHint));
      }
      final whitelist = titles.singleWhere(
        (title) => title.text == appLocalizations.portWhitelist,
      );
      expect(
        whitelist.info,
        '${appLocalizations.portWhitelistInfo}\n'
        '${appLocalizations.coreRestartHint}',
      );
    });

    testWidgets('every experimental item is annotated', (tester) async {
      await pumpSurface(tester, const ExperimentalListView());
      final titles = infoTitles(tester);
      expect(titles, hasLength(3));
      for (final title in titles) {
        expect(title.info, appLocalizations.coreRestartHint);
      }
    });
  });

  group('T89 D-01 config index entry rows', () {
    testWidgets('only the hosts and tunnel rows are annotated', (tester) async {
      await pumpSurface(tester, const ConfigView());
      final titles = infoTitles(tester);
      expect(titles, hasLength(2));
      final texts = titles.map((title) => title.text).toSet();
      expect(texts, {'Hosts', appLocalizations.tunnel});
      for (final title in titles) {
        expect(title.info, appLocalizations.coreRestartHint);
      }
    });
  });

  group('T89 D-01 tunnel dialog', () {
    testWidgets('the add/edit dialog shows the restart note', (tester) async {
      await pumpSurface(tester, const TunnelListView());
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text(appLocalizations.coreRestartHint), findsOneWidget);
    });
  });
}
