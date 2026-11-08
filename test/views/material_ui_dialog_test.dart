import 'dart:async';

import 'package:bett_box/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLocalizations.load(const Locale('en'));
  });

  Future<void> pumpApp(WidgetTester tester, Widget child) async {
    // The app's exact delegate list: AppLocalizations plus only the
    // fork's GlobalMaterialLocalizations (see ai_config_test.dart).
    // The Scaffold supplies the Material ancestor TextField requires;
    // without it both variants would fail on debugCheckHasMaterial
    // instead of on the localizations lookup under test.
    await tester.pumpWidget(
      mui.MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...mui.GlobalMaterialLocalizations.delegates,
        ],
        locale: const Locale('en'),
        home: mui.Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'T30 class: material_ui showDialog renders under the app delegates',
    (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              await mui.showDialog<void>(
                context: context,
                builder: (_) =>
                    const mui.AlertDialog(title: Text('dialog body')),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(ErrorWidget), findsNothing);
      expect(find.text('dialog body'), findsOneWidget);
    },
  );

  testWidgets(
    'reverse control: Flutter showDialog throws under the app delegates',
    (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () {
              unawaited(
                showDialog<void>(
                  context: context,
                  builder: (_) =>
                      const AlertDialog(title: Text('dialog body')),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      expect(find.text('dialog body'), findsNothing);
      expect(tester.takeException(), isNotNull);
    },
  );

  testWidgets(
    'reverse control: Flutter TextField throws under the app delegates',
    (tester) async {
      await pumpApp(tester, const TextField());
      expect(find.byType(ErrorWidget), findsOneWidget);
      expect(tester.takeException(), isNotNull);
    },
  );

  testWidgets(
    'material_ui TextField renders under the app delegates',
    (tester) async {
      await pumpApp(tester, const mui.TextField());
      expect(find.byType(ErrorWidget), findsNothing);
      expect(find.byType(mui.TextField), findsOneWidget);
    },
  );
}
