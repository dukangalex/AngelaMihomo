import 'package:bett_box/common/common.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/profiles/edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// T73 C3: on the new-profile form the Age key, update interval and
// script entries fold into an "Advanced Settings" section that starts
// collapsed; the required path (name, URL, auto-update switch) stays
// on the main layer. The edit form keeps its flat layout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppLocalizations.load(const Locale('en'));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => '/tmp',
        );
  });

  setUp(() {
    globalState.config = Config(
      themeProps: defaultThemeProps,
      patchClashConfig: defaultClashConfig,
    );
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
  });

  Future<void> pumpForm(
    WidgetTester tester, {
    required Profile profile,
    required bool isNew,
  }) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: mui.MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...mui.GlobalMaterialLocalizations.delegates,
          ],
          locale: const Locale('en'),
          home: mui.Scaffold(
            body: Builder(
              builder: (context) => EditProfileView(
                context: context,
                profile: profile,
                isNew: isNew,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('new profile: advanced fields start collapsed', (
    tester,
  ) async {
    await pumpForm(tester, profile: Profile.normal(), isNew: true);

    // Main layer: the required path is all visible.
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('URL'), findsOneWidget);
    expect(find.text('Auto Update'), findsOneWidget);
    expect(find.text('Advanced Settings'), findsOneWidget);

    // Advanced fields are mounted but hidden while collapsed.
    expect(find.text('Age Secret Key (Optional)'), findsNothing);
    expect(find.text('Auto update interval (min)'), findsNothing);
    expect(find.text('Override Script'), findsNothing);

    await tester.tap(find.text('Advanced Settings'));
    await tester.pump();

    expect(find.text('Age Secret Key (Optional)'), findsOneWidget);
    expect(find.text('Auto update interval (min)'), findsOneWidget);
    expect(find.text('Override Script'), findsOneWidget);

    await tester.tap(find.text('Advanced Settings'));
    await tester.pump();

    expect(find.text('Age Secret Key (Optional)'), findsNothing);
    expect(find.text('Override Script'), findsNothing);
  });

  testWidgets('edit profile: fields stay flat, no advanced section', (
    tester,
  ) async {
    await pumpForm(
      tester,
      profile: const Profile(
        id: 'edit-1',
        url: 'https://example.com/sub',
        autoUpdateDuration: Duration(minutes: 720),
      ),
      isNew: false,
    );

    expect(find.text('Advanced Settings'), findsNothing);
    expect(find.text('Age Secret Key (Optional)'), findsOneWidget);
    expect(find.text('Auto update interval (min)'), findsOneWidget);
    expect(find.text('Override Script'), findsOneWidget);
  });
}
