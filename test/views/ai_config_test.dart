import 'package:bett_box/common/common.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/ai_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:material_ui/material_ui.dart' as mui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLocalizations.load(const Locale('en'));
  });
  setUp(() {
    globalState.config = Config(themeProps: defaultThemeProps);
    // globalState.appState is late-initialized by app startup; mirror
    // the GlobalState.init construction so providers that read it
    // (e.g. isMobileViewProvider via CommonScaffold) resolve.
    globalState.appState = AppState(
      brightness: Brightness.light,
      version: 0,
      viewSize: const Size(360, 640),
      requests: FixedList(maxLength),
      logs: FixedList(maxLogLength),
      traffics: FixedList(30),
      totalTraffic: Traffic(),
      systemUiOverlayStyle: const services.SystemUiOverlayStyle(),
    );
  });

  testWidgets(
    'T30: BYOK fields render under the app localization setup',
    (tester) async {
      // Regression test for the chain.15 grey screen: the app runs
      // on the material_ui fork — its MaterialApp registers only
      // the fork's GlobalMaterialLocalizations delegates. A page
      // that imports Flutter's material instead gets Flutter's
      // TextField, whose _getEffectiveDecoration calls Flutter's
      // MaterialLocalizations.of, which resolves to null here, so
      // every field throws and is replaced by a 100000px-tall
      // release-grey RenderErrorBox. Pumping the page under the
      // app's exact delegate list must therefore show all three
      // fields and no ErrorWidget.
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            child: mui.MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...mui.GlobalMaterialLocalizations.delegates,
              ],
              locale: const Locale('en'),
              home: const AiConfigView(),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.byType(ErrorWidget), findsNothing);
      expect(find.byType(mui.TextField), findsNWidgets(3));
      expect(find.text(appLocalizations.save), findsOneWidget);
      expect(find.text(appLocalizations.aiTestConnection), findsOneWidget);
    },
  );
}
