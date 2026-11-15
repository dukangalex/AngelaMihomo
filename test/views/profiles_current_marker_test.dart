import 'package:bett_box/common/common.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/profiles/profiles.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// T126: the current profile carries a triple signal — gradient bar at
/// the row start, a tinted wash, and a "当前" badge — in both brightness
/// variants; non-current profiles carry none of them.
void main() {
  const profile = Profile(
    id: 'p-current',
    label: 'Current Sub',
    autoUpdateDuration: Duration(hours: 1),
  );

  Future<void> pumpItem(
    WidgetTester tester, {
    required Brightness brightness,
    required String? groupValue,
  }) async {
    globalState.appState = AppState(
      brightness: brightness,
      version: 0,
      viewSize: const Size(400, 800),
      requests: FixedList(maxLength),
      logs: FixedList(maxLogLength),
      traffics: FixedList(30),
      totalTraffic: Traffic(),
      systemUiOverlayStyle: const SystemUiOverlayStyle(),
    );
    final zodiac = resolveZodiacTheme('sagittarius');
    final variant = zodiac.variant;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: AppLocalizations.delegate.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: ThemeData(
          // Single-set family: the zodiac scheme is always dark, so
          // ThemeData takes its brightness from the scheme; the loop's
          // brightness still drives AppState above.
          colorScheme: variant.toColorScheme(),
          extensions: [ZodiacThemeExtension.of(zodiac)],
        ),
        home: Scaffold(
          body: ProfileItem(
            profile: profile,
            groupValue: groupValue,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool hasGradientBar(WidgetTester tester) {
    return tester
        .widgetList(
          find.byWidgetPredicate((widget) {
            if (widget is! Container) return false;
            final decoration = widget.decoration;
            return widget.constraints?.minWidth == 5 &&
                decoration is BoxDecoration &&
                decoration.gradient != null;
          }),
        )
        .isNotEmpty;
  }

  for (final brightness in Brightness.values) {
    testWidgets('current profile shows badge and gradient bar ($brightness)', (
      tester,
    ) async {
      await pumpItem(tester, brightness: brightness, groupValue: 'p-current');
      expect(find.text('当前'), findsOneWidget);
      expect(hasGradientBar(tester), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('other profile shows no current signals ($brightness)', (
      tester,
    ) async {
      await pumpItem(tester, brightness: brightness, groupValue: 'p-other');
      expect(find.text('当前'), findsNothing);
      expect(hasGradientBar(tester), isFalse);
    });
  }
}
