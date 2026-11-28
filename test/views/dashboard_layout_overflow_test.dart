import 'dart:io';

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/common/theme.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/l10n/l10n.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/dashboard/widgets/widgets.dart';
import 'package:angelamihomo/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// T341 regression: on a real device the T337 exit-node and
/// subscription tiles rendered their content flush against the
/// card borders — the tile title touched the left edge and the
/// subscription card's usage value and speed-test button ran to
/// the card's right edge, reading as clipped / overflowing.
/// Root cause: those tiles pass their content inset as
/// CommonCard's `padding`, which CommonCard never applied.
///
/// This pumps the dashboard's default-layout grid in the same
/// composition DashboardView builds (scroll view with 16dp side
/// padding, stretch column, 8-column editable grid, 12dp
/// spacing) at common phone logical widths, with the app's
/// bundled NotoSansSC loaded so text metrics match a device,
/// and asserts: no layout overflow anywhere, every tile inside
/// the padded column, and the new tiles' content inset by the
/// padding they declare instead of flush with the card edge.
const _widths = [320.0, 360.0, 393.0, 412.0];

bool _fontLoaded = false;

/// Loads the bundled font with real async (testWidgets bodies run
/// in a fake-async zone where dart:io futures never complete).
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

Profile _profile() {
  return Profile(
    id: 'p1',
    label: 'Kitty Network(1)',
    url: 'https://example.com/sub',
    lastUpdateDate: DateTime(2026, 11, 28, 8, 0),
    autoUpdateDuration: defaultUpdateDuration,
    currentGroupName: 'GLOBAL',
    subscriptionInfo: SubscriptionInfo(
      upload: 977 * 1024,
      download: 2410 * 1024,
      total: 1024 * 1024 * 1024 * 1024,
      expire: DateTime(2027, 11, 22).millisecondsSinceEpoch ~/ 1000,
    ),
  );
}

Future<void> _pumpGrid(WidgetTester tester, double width) async {
  await _loadRealFont(tester);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 1400);
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  globalState.appState = AppState(
    brightness: Brightness.dark,
    version: 0,
    viewSize: Size(width, 1400),
    requests: FixedList(maxLength),
    logs: FixedList(maxLogLength),
    traffics: FixedList(30),
    totalTraffic: Traffic(),
    systemUiOverlayStyle: const SystemUiOverlayStyle(),
  );
  globalState.config = Config(
    themeProps: const ThemeProps(themeMode: ThemeMode.system),
    currentProfileId: 'p1',
    profiles: [_profile()],
    proxiesStyle: defaultProxiesStyle,
  );
  const spacing = 12.0;
  final tiles = <DashboardTile>[
    (widget: DashboardWidget.exitNode, size: DashboardTileSize.wide),
    (widget: DashboardWidget.networkSpeed, size: DashboardTileSize.large),
    (widget: DashboardWidget.todayTraffic, size: DashboardTileSize.small),
    (
      widget: DashboardWidget.subscriptionRemaining,
      size: DashboardTileSize.small,
    ),
    (widget: DashboardWidget.outboundMode, size: DashboardTileSize.small),
    (widget: DashboardWidget.subscription, size: DashboardTileSize.wide),
  ];
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('zh'),
        theme: ThemeData(
          fontFamily: 'NotoSansSC',
          extensions: [
            ZodiacThemeExtension.of(
              resolveZodiacTheme('sagittarius'),
              Brightness.dark,
            ),
          ],
        ),
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: Builder(
            builder: (context) {
              globalState.theme = CommonTheme.of(context, 1);
              globalState.measure = Measure.of(context, 1);
              return DashboardWidgetMetrics(
                unitHeight: 84,
                spacing: spacing,
                columns: 8,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EditableGrid<DashboardTile>(
                        items: tiles,
                        editing: false,
                        crossAxisCount: 8,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        keyOf: (tile) => tile.widget.family,
                        crossAxisCellCountOf: (tile) => tile.size.cross * 4,
                        itemBuilder: (_, tile) => buildDashboardTile(tile),
                      ),
                    ],
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
}

void main() {
  for (final width in _widths) {
    testWidgets('default layout fits at ${width}dp wide', (tester) async {
      await _pumpGrid(tester, width);
      expect(tester.takeException(), isNull);

      // Every tile stays inside the padded content column.
      for (final type in [ExitNode, SubscriptionCard]) {
        final tileRect = tester.getRect(find.byType(type));
        expect(tileRect.left, greaterThanOrEqualTo(16 - 0.5));
        expect(tileRect.right, lessThanOrEqualTo(width - 16 + 0.5));
      }

      // The exit-node tile's content is inset by the padding the
      // tile declares (16dp), not flush with the card's edge.
      final exitRect = tester.getRect(find.byType(ExitNode));
      final exitLabel = tester.getRect(
        find
            .descendant(of: find.byType(ExitNode), matching: find.byType(Text))
            .first,
      );
      expect(
        exitLabel.left,
        greaterThanOrEqualTo(exitRect.left + 16 - 0.5),
        reason: 'exit-node label must be inset from the card edge',
      );

      // The subscription card's content stays inside the card,
      // inset by its declared padding: the speed-test button and
      // the usage value must not reach the card's edges.
      final subRect = tester.getRect(find.byType(SubscriptionCard));
      final buttonRect = tester.getRect(
        find.descendant(
          of: find.byType(SubscriptionCard),
          matching: find.byType(FilledButton),
        ),
      );
      expect(buttonRect.left, greaterThanOrEqualTo(subRect.left + 16 - 0.5));
      expect(buttonRect.right, lessThanOrEqualTo(subRect.right - 16 + 0.5));
      for (final element in find
          .descendant(
            of: find.byType(SubscriptionCard),
            matching: find.byType(Text),
          )
          .evaluate()) {
        final rect = tester.getRect(find.byWidget(element.widget));
        expect(
          rect.left,
          greaterThanOrEqualTo(subRect.left - 0.5),
          reason: 'subscription text paints left of its card: $rect',
        );
        expect(
          rect.right,
          lessThanOrEqualTo(subRect.right + 0.5),
          reason: 'subscription text paints right of its card: $rect',
        );
      }

      // The new tiles' card faces are solid (T341): the guardian
      // watermark must not show through them.
      for (final element in find
          .descendant(
            of: find.byType(ExitNode),
            matching: find.byType(CommonCard),
          )
          .evaluate()) {
        expect((element.widget as CommonCard).solidSurface, isTrue);
      }
      for (final element in find
          .descendant(
            of: find.byType(SubscriptionCard),
            matching: find.byType(CommonCard),
          )
          .evaluate()) {
        expect((element.widget as CommonCard).solidSurface, isTrue);
      }
    });
  }
}
