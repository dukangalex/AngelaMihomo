import 'package:angelamihomo/common/chain_health.dart';
import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/l10n/l10n.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/profiles/profiles.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// T152: the profile card lists the profile's managed and chain status —
/// the managed badge shows only while managed mode is on (no color
/// semantics), the chain badge only while a chain is enabled, green when
/// both ends of the saved selection resolve and red when any end is
/// stale, in the current variant's semantic tokens. Markers are pure
/// display: card taps keep working and stale data renders normally.
void main() {
  final zodiac = resolveZodiacTheme('sagittarius');
  final variant = zodiac.dark;

  Future<void> pumpItem(
    WidgetTester tester, {
    required Profile profile,
    String? groupValue,
    ChainCardHealth? chainHealth,
    void Function(String?)? onChanged,
  }) async {
    globalState.appState = AppState(
      brightness: Brightness.dark,
      version: 0,
      viewSize: const Size(400, 800),
      requests: FixedList(maxLength),
      logs: FixedList(maxLogLength),
      traffics: FixedList(30),
      totalTraffic: Traffic(),
      systemUiOverlayStyle: const SystemUiOverlayStyle(),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: AppLocalizations.delegate.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          colorScheme: variant.toColorScheme(Brightness.dark),
          extensions: [ZodiacThemeExtension.of(zodiac, Brightness.dark)],
        ),
        home: Scaffold(
          body: ProfileItem(
            profile: profile,
            groupValue: groupValue,
            chainHealth: chainHealth,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Profile profile({bool managed = false, String label = 'Sub A'}) => Profile(
    id: 'p-1',
    label: label,
    autoUpdateDuration: const Duration(hours: 1),
    managed: managed,
  );

  /// The badge pill is the ancestor [Container] of its text whose
  /// decoration carries the expected tint (the card stacks other
  /// containers above it, so match by color rather than by position).
  void expectBadgeTint(WidgetTester tester, String text, Color tint) {
    final containers = tester.widgetList<Container>(
      find.ancestor(of: find.text(text), matching: find.byType(Container)),
    );
    final colors = containers
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.color)
        .toSet();
    expect(colors, contains(tint));
  }

  testWidgets('managed on shows the managed badge, off shows none', (
    tester,
  ) async {
    await pumpItem(tester, profile: profile(managed: true));
    expect(find.text('托管模式'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpItem(tester, profile: profile());
    expect(find.text('托管模式'), findsNothing);
  });

  testWidgets('no chain marker when not enabled or not yet computed', (
    tester,
  ) async {
    await pumpItem(tester, profile: profile(), chainHealth: null);
    expect(find.text('链式'), findsNothing);

    await pumpItem(
      tester,
      profile: profile(),
      chainHealth: ChainCardHealth.notEnabled,
    );
    expect(find.text('链式'), findsNothing);
  });

  testWidgets('healthy chain shows a green chain badge with link icon', (
    tester,
  ) async {
    await pumpItem(
      tester,
      profile: profile(),
      chainHealth: ChainCardHealth.healthy,
    );
    expect(find.text('链式'), findsOneWidget);
    expect(find.byIcon(Icons.link_rounded), findsOneWidget);
    expectBadgeTint(tester, '链式', variant.success.withValues(alpha: 0.14));
    final text = tester.widget<Text>(find.text('链式'));
    expect(text.style?.color, variant.success);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale chain shows a red chain badge', (tester) async {
    await pumpItem(
      tester,
      profile: profile(),
      chainHealth: ChainCardHealth.stale,
    );
    expect(find.text('链式'), findsOneWidget);
    expectBadgeTint(tester, '链式', variant.error.withValues(alpha: 0.14));
    final text = tester.widget<Text>(find.text('链式'));
    expect(text.style?.color, variant.error);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all markers together render without overflow', (tester) async {
    await pumpItem(
      tester,
      profile: profile(managed: true, label: 'A very long subscription name'),
      groupValue: 'p-1',
      chainHealth: ChainCardHealth.stale,
    );
    expect(find.text('当前'), findsOneWidget);
    expect(find.text('托管模式'), findsOneWidget);
    expect(find.text('链式'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('markers do not block the card tap', (tester) async {
    String? changed;
    await pumpItem(
      tester,
      profile: profile(managed: true),
      chainHealth: ChainCardHealth.healthy,
      onChanged: (value) => changed = value,
    );
    await tester.tap(find.text('Sub A'));
    await tester.pumpAndSettle();
    expect(changed, 'p-1');
    // The overflow menu entry point is still in place.
    expect(find.byIcon(Icons.more_vert), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
