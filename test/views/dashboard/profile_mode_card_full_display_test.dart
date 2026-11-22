import 'dart:async';

import 'package:angelamihomo/clash/clash.dart';
import 'package:angelamihomo/clash/interface.dart';
import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/common/theme.dart';
import 'package:angelamihomo/controller.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/l10n/l10n.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/views/dashboard/widgets/node_status_light.dart';
import 'package:angelamihomo/views/dashboard/widgets/profile_mode.dart';
import 'package:angelamihomo/widgets/text.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// T286 acceptance suite: on a phone-width surface, the merged home
/// card must show every item in full — a 30+ character profile name,
/// a 40+ character node name and three-digit-GB usage numbers —
/// without ellipsizing any of them and without layout overflow.
class _FakeHandler extends ClashHandlerInterface {
  Object? channel = Object();

  @override
  Future<Object?> sendMessage(String message) async => channel;

  @override
  Future<bool> preload() async => true;

  @override
  FutureOr<void> reStart() {}

  @override
  FutureOr<bool> destroy() => true;
}

const _testUrl = 'https://example.com/204';
const _longProfileName = 'Kitty Premium Plan Plus Family';
const _longNodeName = 'United States 03 · Los Angeles Premium Line';

Profile _longProfile() {
  const gb = 1024 * 1024 * 1024;
  return Profile(
    id: 'p',
    label: _longProfileName,
    autoUpdateDuration: const Duration(days: 1),
    lastUpdateDate: DateTime.now().subtract(const Duration(minutes: 4)),
    subscriptionInfo: SubscriptionInfo(
      upload: 0,
      download: (150.75 * gb).round(),
      total: 999 * gb,
      expire: DateTime(2027, 1, 29).millisecondsSinceEpoch ~/ 1000,
    ),
    selectedMap: const {'MainGroup': _longNodeName},
  );
}

Future<void> _pumpCard(WidgetTester tester, {required double width}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  globalState.appState = AppState(
    brightness: Brightness.light,
    version: 0,
    viewSize: Size(width, 800),
    requests: FixedList(maxLength),
    logs: FixedList(maxLogLength),
    traffics: FixedList(30),
    totalTraffic: Traffic(),
    systemUiOverlayStyle: const SystemUiOverlayStyle(),
    groups: const [
      Group(
        type: GroupType.Selector,
        name: 'MainGroup',
        testUrl: _testUrl,
        now: _longNodeName,
        all: [Proxy(name: _longNodeName, type: 'Trojan')],
      ),
    ],
    runTime: 3600,
    delayMap: const {
      _testUrl: {_longNodeName: 193},
    },
  );
  globalState.config = Config(
    themeProps: defaultThemeProps,
    currentProfileId: 'p',
    patchClashConfig: defaultClashConfig.copyWith(mode: Mode.rule),
    profiles: [_longProfile()],
    proxiesStyle: defaultProxiesStyle,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(
          extensions: [
            ZodiacThemeExtension.of(resolveZodiacTheme('sagittarius')),
          ],
        ),
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              globalState.appController = AppController(context, ref);
              globalState.theme = CommonTheme.of(context, 1);
              globalState.measure = Measure.of(context, 1);
              ref.watch(groupsProvider);
              ref.watch(selectedMapProvider);
              ref.watch(delayDataSourceProvider);
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: width, child: const ProfileModeCard()),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The render-level fact of truncation: the paragraph backing the
/// text reports whether its content exceeded the line budget.
bool _paragraphExceedsLines(WidgetTester tester, Finder textFinder) {
  final richText = find.descendant(
    of: textFinder,
    matching: find.byType(RichText),
  );
  expect(richText, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(richText);
  return paragraph.didExceedMaxLines;
}

/// Asserts the EmojiText rendering [text] is not truncated: it must
/// not ellipsize, and its paragraph must fit within the line budget.
void _expectEmojiTextFullyShown(
  WidgetTester tester,
  String text, {
  required int maxLines,
}) {
  final finder = find.byWidgetPredicate(
    (widget) => widget is EmojiText && widget.text == text,
  );
  expect(finder, findsOneWidget, reason: 'missing text: $text');
  final widget = tester.widget<EmojiText>(finder);
  expect(
    widget.overflow,
    isNot(TextOverflow.ellipsis),
    reason: 'text must not ellipsize: $text',
  );
  expect(widget.maxLines, maxLines);
  expect(
    _paragraphExceedsLines(tester, finder),
    isFalse,
    reason: 'text needs more than $maxLines lines at its width: $text',
  );
}

void _expectPlainTextFullyShown(WidgetTester tester, String text) {
  final finder = find.text(text);
  expect(finder, findsOneWidget, reason: 'missing text: $text');
  final widget = tester.widget<Text>(finder);
  expect(
    widget.overflow,
    isNot(TextOverflow.ellipsis),
    reason: 'text must not ellipsize: $text',
  );
  expect(
    _paragraphExceedsLines(tester, finder),
    isFalse,
    reason: 'text exceeds its line budget at its width: $text',
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SystemExplicitStore.instance.ensureLoaded();
  });

  testWidgets(
    'long profile name, node name and usage all render in full at phone width',
    (tester) async {
      ClashCore.setHandlerForTesting(_FakeHandler());
      await _pumpCard(tester, width: 400);

      // No layout overflow anywhere in the card.
      expect(tester.takeException(), isNull);

      // Profile name: full string, up to two lines, never ellipsized.
      _expectEmojiTextFullyShown(tester, _longProfileName, maxLines: 2);

      // Usage numbers: both ends of "used / total" present in full.
      final usageText = ProfileUsage.of(_longProfile())!.usageText;
      expect(usageText, contains('999'));
      _expectPlainTextFullyShown(tester, usageText);

      // Node name + delay, status light, chips and the three modes.
      // (The light is a pre-existing component whose label layout is
      // unchanged by T286; in the user's zh locale the label is five
      // characters and always fits — here it is asserted present.)
      _expectEmojiTextFullyShown(tester, _longNodeName, maxLines: 2);
      _expectPlainTextFullyShown(tester, '193 ms');
      expect(find.byType(NodeStatusLight), findsOneWidget);
      expect(find.text('Current node available'), findsOneWidget);
      expect(find.text('System Proxy'), findsOneWidget);
      expect(find.text('Rule'), findsOneWidget);
      expect(find.text('Global'), findsOneWidget);
      expect(find.text('Direct'), findsOneWidget);

      // The card keeps its two-row floor height and grows past it
      // rather than clipping the stacked rows.
      final cardSize = tester.getSize(find.byType(ProfileModeCard));
      expect(cardSize.height, greaterThanOrEqualTo(180));
    },
  );

  testWidgets('long content also fits at a narrower phone width', (
    tester,
  ) async {
    ClashCore.setHandlerForTesting(_FakeHandler());
    await _pumpCard(tester, width: 360);

    expect(tester.takeException(), isNull);
    _expectEmojiTextFullyShown(tester, _longProfileName, maxLines: 2);
    _expectEmojiTextFullyShown(tester, _longNodeName, maxLines: 2);
    _expectPlainTextFullyShown(
      tester,
      ProfileUsage.of(_longProfile())!.usageText,
    );
  });
}
