import 'package:bett_box/controller.dart';
import 'package:bett_box/state.dart';
import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'T54 defect 1: AppController resolves a dialog context under the navigator',
    (tester) async {
      // Regression test for the Rule -> Global crash: AppController is
      // built with a context captured above MaterialApp (application
      // initState), which has no Navigator ancestor, so passing it to
      // showDialog crashed with Navigator.of == null. The controller
      // must resolve the navigator's own context at call time.
      late BuildContext outerContext;
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          child: Builder(
            builder: (context) {
              outerContext = context;
              return mui.MaterialApp(
                navigatorKey: globalState.navigatorKey,
                home: Consumer(
                  builder: (context, ref, _) {
                    capturedRef = ref;
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Reverse control: the captured context itself has no Navigator
      // (the defect's precondition — this is what changeMode used to
      // pass to showDialog).
      expect(Navigator.maybeOf(outerContext), isNull);

      final controller = AppController(outerContext, capturedRef);
      // ... but the controller's dialog context resolves under it.
      final dialogContext = controller.context;
      expect(dialogContext, isNot(outerContext));
      expect(Navigator.maybeOf(dialogContext), isNotNull);
      expect(dialogContext.mounted, isTrue);
    },
  );
}
