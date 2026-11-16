import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// T125: pushed pages carry their own zodiac backdrop, and on desktop
/// the phased content fades never show two pages' contents at once.
class _FixedPageLabel extends CurrentPageLabel {
  @override
  PageLabel build() => PageLabel.dashboard;
}

void main() {
  // The backdrop's name plate (T159) reads the global localizations,
  // which the app loads before any page builds.
  setUp(() async {
    await AppLocalizations.load(const Locale('en'));
  });

  ThemeData theme() {
    return ThemeData(
      extensions: [ZodiacThemeExtension.of(resolveZodiacTheme('sagittarius'))],
    );
  }

  Widget app({required Widget home}) {
    // The backdrop's guardian layers (T159) read the current page
    // label, so the harness runs under a ProviderScope like the app.
    return ProviderScope(
      overrides: [
        currentPageLabelProvider.overrideWith(() => _FixedPageLabel()),
      ],
      child: MaterialApp(
        theme: theme(),
        builder: (_, child) => Stack(
          fit: StackFit.expand,
          children: [const ZodiacBackdrop(), child!],
        ),
        home: home,
      ),
    );
  }

  double effectiveOpacity(WidgetTester tester, Finder target) {
    var opacity = 1.0;
    final fades = tester.widgetList<FadeTransition>(
      find.ancestor(of: target, matching: find.byType(FadeTransition)),
    );
    for (final fade in fades) {
      opacity *= fade.opacity.value;
    }
    return opacity;
  }

  testWidgets('desktop route: page carries backdrop, contents never overlap', (
    tester,
  ) async {
    await tester.pumpWidget(app(home: const Scaffold(body: Text('pageA'))));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      CommonDesktopRoute<void>(
        builder: (_) => const Scaffold(body: Text('pageB')),
      ),
    );
    await tester.pump();

    var sawBackdropInTopPage = false;
    // Sample only inside the 260ms transition window; once settled,
    // page A legitimately rests beneath page B's opaque backdrop.
    for (var step = 0; step <= 12; step++) {
      await tester.pump(const Duration(milliseconds: 20));
      final aOpacity = effectiveOpacity(tester, find.text('pageA'));
      final bOpacity = effectiveOpacity(tester, find.text('pageB'));
      expect(
        aOpacity > 0.05 && bOpacity > 0.05,
        isFalse,
        reason: 'ghosting at step $step: A=$aOpacity B=$bOpacity both visible',
      );
      // Root backdrop + the pushed page's own backdrop.
      if (tester.widgetList(find.byType(ZodiacBackdrop)).length >= 2) {
        sawBackdropInTopPage = true;
      }
    }
    await tester.pumpAndSettle();
    expect(sawBackdropInTopPage, isTrue);
    expect(find.text('pageB'), findsOneWidget);
    expect(effectiveOpacity(tester, find.text('pageB')), 1.0);
  });

  testWidgets('mobile route: pushed page carries its own backdrop', (
    tester,
  ) async {
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
    await tester.pumpWidget(
      app(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => BaseNavigator.push(
                context,
                const Scaffold(body: Text('pageB')),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    // Mid-slide: root backdrop + pushed page's own backdrop.
    expect(
      tester.widgetList(find.byType(ZodiacBackdrop)).length,
      greaterThanOrEqualTo(2),
    );
    await tester.pumpAndSettle();
    expect(find.text('pageB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
