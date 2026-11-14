import 'package:bett_box/common/common.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/profiles/scripts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// T121: the scripts page shows exactly one built-in entry — the managed
/// mechanism's script under its own name — next to the user's scripts.
/// The mechanism name （托管模式） must not appear as a second entry.
void main() {
  setUpAll(() async {
    await AppLocalizations.load(const Locale('zh', 'CN'));
  });

  setUp(() {
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

  testWidgets('脚本页只有一条内置条目，名为 HiClash 内置脚本', (tester) async {
    final base = Config(themeProps: defaultThemeProps);
    globalState.config = base.copyWith(
      scriptProps: ScriptProps(
        scripts: const [Script(id: 'user-1', label: '我的脚本')],
      ),
    );
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: ScriptsView())),
      ),
    );
    await tester.pump();
    expect(find.text('HiClash 内置脚本'), findsOneWidget);
    expect(find.text('我的脚本'), findsOneWidget);
    expect(find.text('托管模式'), findsNothing);
  });
}
