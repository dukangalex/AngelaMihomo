import 'dart:io';

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/common/theme.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/l10n/l10n.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/dashboard/dashboard.dart';
import 'package:angelamihomo/widgets/widgets.dart';
import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// T343 regression guard for the add-widget panel: every preview
/// is the tile widget itself, composed once into the panel grid —
/// its title (and values) must be painted exactly once, never
/// doubled by a second, panel-side copy. This pumps the panel's
/// real composition pieces (the enum's own GridItems, the real
/// packGridItems packing, the real Grid, the same metrics the
/// modal installs) for the three previews the user's recording
/// showed, in the same provider/font setup as the dashboard
/// layout tests.
bool _fontLoaded = false;

Future<void> _loadRealFont(WidgetTester tester) async {
  if (_fontLoaded) return;
  _fontLoaded = true;
  await tester.runAsync(() async {
    final bytes = await File(
      'assets/fonts/NotoSansSC-Regular.ttf',
    ).readAsBytes();
    final loader = FontLoader('NotoSansSC')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });
}

/// Mirrors _AddDashboardWidgetModal's per-item frame (the modal
/// itself is private): the preview tile under an add button.
class _PreviewFrame extends StatelessWidget {
  final Widget child;

  const _PreviewFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ActivateBox(child: child),
        Positioned(
          top: -8,
          right: -8,
          child: DeferPointer(
            child: SizedBox(
              width: 24,
              height: 24,
              child: IconButton.filled(
                iconSize: 20,
                padding: const EdgeInsets.all(2),
                onPressed: () {},
                icon: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('添加面板预览：每张卡的标题只出现一次（T343）', (tester) async {
    // The tiles read the intl singleton, not the ambient locale;
    // its load only lands in a real-async zone.
    await tester.runAsync(
      () => AppLocalizations.load(const Locale('zh', 'CN')),
    );
    await _loadRealFont(tester);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(393, 1200);
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    globalState.appState = AppState(
      brightness: Brightness.dark,
      version: 0,
      viewSize: const Size(393, 1200),
      requests: FixedList(maxLength),
      logs: FixedList(maxLogLength),
      traffics: FixedList(30),
      totalTraffic: Traffic(),
      systemUiOverlayStyle: const SystemUiOverlayStyle(),
    );
    globalState.config = Config(
      themeProps: const ThemeProps(themeMode: ThemeMode.system),
      currentProfileId: null,
      profiles: const [],
      proxiesStyle: defaultProxiesStyle,
    );
    const spacing = 12.0;
    const columns = 8;
    final items = [
      DashboardWidget.trafficUsage.widget,
      DashboardWidget.intranetIp.widget,
      DashboardWidget.connectionsCount.widget,
    ];
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          supportedLocales: AppLocalizations.delegate.supportedLocales,
          theme: ThemeData(
            fontFamily: 'NotoSansSC',
            extensions: [
              ZodiacThemeExtension.of(
                resolveZodiacTheme('sagittarius'),
                Brightness.dark,
              ),
            ],
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                globalState.theme = CommonTheme.of(context, 1);
                globalState.measure = Measure.of(context, 1);
                return DashboardWidgetMetrics(
                  unitHeight: 84,
                  spacing: spacing,
                  columns: columns,
                  child: DeferredPointerHandler(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Grid(
                        crossAxisCount: columns,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        children: [
                          for (final item in packGridItems(items, columns))
                            item.wrap(
                              builder: (child) => _PreviewFrame(child: child),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    // One title per preview — the tile's own header, and no
    // second copy contributed by the panel composition. (Card
    // headers render as rich text, hence findRichText.)
    expect(find.text('流量统计', findRichText: true), findsOneWidget);
    expect(find.text('内网 IP', findRichText: true), findsOneWidget);
    expect(find.text('活跃连接', findRichText: true), findsOneWidget);
  });
}
