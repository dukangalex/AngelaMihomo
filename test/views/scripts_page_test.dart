import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/l10n/l10n.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/profiles/scripts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// T121 + T144: the scripts page shows exactly one built-in entry — the
/// managed mechanism's script — next to the user's scripts. Since T144
/// the entry presents under the mechanism's own name （托管模式）, tagged
/// 内置脚本， and the 自定义 capability tag stays; no third-party name
/// appears as a title anywhere on the page.
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

  testWidgets('脚本页只有一条内置条目，名为托管模式、标记内置脚本与自定义', (tester) async {
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
    expect(find.text('托管模式'), findsOneWidget);
    expect(find.text('内置脚本'), findsOneWidget);
    expect(find.text('自定义'), findsOneWidget);
    expect(find.text('我的脚本'), findsOneWidget);
    expect(find.text('HiClash 内置脚本'), findsNothing);
    for (final widget in tester.widgetList<Text>(find.byType(Text))) {
      expect(widget.data ?? '', isNot(contains('HiClash')));
    }
  });
}
