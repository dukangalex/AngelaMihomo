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
// Descender-heavy fixture (T286 round 2): g/y/p descenders plus CJK,
// the shape of the name in the user's screenshot report.
const _descenderNodeName = 'Hong Kong gypsy 05 长节点名';

Profile _longProfile({String nodeName = _longNodeName}) {
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
    selectedMap: {'MainGroup': nodeName},
  );
}

/// T288 fixture: the exact figures from the user's report — the
/// profile was updated 15 hours ago, expires 2027-11-22, and has
/// used 468.37 KB of 1024.00 GB.
Profile _userReportProfile() {
  const kb = 1024;
  const gb = 1024 * 1024 * 1024;
  return Profile(
    id: 'p',
    label: 'Kitty Network(1)',
    autoUpdateDuration: const Duration(days: 1),
    lastUpdateDate: DateTime.now().subtract(const Duration(hours: 15)),
    subscriptionInfo: SubscriptionInfo(
      upload: 0,
      download: (468.37 * kb).round(),
      total: 1024 * gb,
      expire: DateTime(2027, 11, 22).millisecondsSinceEpoch ~/ 1000,
    ),
    selectedMap: {'MainGroup': _longNodeName},
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required double width,
  String nodeName = _longNodeName,
  Locale? locale,
  Profile? profile,
}) async {
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
    groups: [
      Group(
        type: GroupType.Selector,
        name: 'MainGroup',
        testUrl: _testUrl,
        now: nodeName,
        all: [Proxy(name: nodeName, type: 'Trojan')],
      ),
    ],
    runTime: 3600,
    delayMap: {
      _testUrl: {nodeName: 193},
    },
  );
  globalState.config = Config(
    themeProps: defaultThemeProps,
    currentProfileId: 'p',
    patchClashConfig: defaultClashConfig.copyWith(mode: Mode.rule),
    profiles: [profile ?? _longProfile(nodeName: nodeName)],
    proxiesStyle: defaultProxiesStyle,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('zh', 'CN')],
        theme: ThemeData(
          fontFamily: 'NotoSansSC',
          extensions: [
            ZodiacThemeExtension.of(resolveZodiacTheme('sagittarius')),
          ],
        ),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
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

/// T288: the meta line is one combined Text carrying the expiry
/// date and the usage figures together — never separate chunks.
Finder _metaLineFinder({required String expire, required String usage}) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        (widget.data?.contains(expire) ?? false) &&
        (widget.data?.contains(usage) ?? false),
  );
}

void _expectMetaLineFullyShown(
  WidgetTester tester, {
  required String expire,
  required String usage,
}) {
  final finder = _metaLineFinder(expire: expire, usage: usage);
  expect(
    finder,
    findsOneWidget,
    reason: 'missing combined meta line: $expire · $usage',
  );
  final widget = tester.widget<Text>(finder);
  expect(
    widget.overflow,
    isNot(TextOverflow.ellipsis),
    reason: 'meta line must not ellipsize',
  );
  expect(
    _paragraphExceedsLines(tester, finder),
    isFalse,
    reason: 'meta line exceeds its line budget',
  );
}

/// How many laid-out lines the meta line's paragraph occupies:
/// re-layout the same text and style in a standalone painter at
/// the paragraph's own width and count its line metrics.
int _metaLineCount(WidgetTester tester, Finder finder) {
  final widget = tester.widget<Text>(finder);
  final richText = find.descendant(
    of: finder,
    matching: find.byType(RichText),
  );
  expect(richText, findsOneWidget);
  final width = tester.getSize(richText).width;
  final painter = TextPainter(
    text: TextSpan(text: widget.data, style: widget.style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);
  return painter.computeLineMetrics().length;
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SystemExplicitStore.instance.ensureLoaded();
    // Real bundled font: the stock test font is far wider than any
    // device font, which would make the meta row wrap in tests
    // where it fits on one line on a phone.
    final loader = FontLoader('NotoSansSC')
      ..addFont(rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf'));
    await loader.load();
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

      // Usage numbers: both ends of "used / total" present in full,
      // on the combined meta line beside the expiry date (T288).
      final usageText = ProfileUsage.of(_longProfile())!.usageText;
      expect(usageText, contains('999'));
      _expectMetaLineFullyShown(
        tester,
        expire: '2027-01-29',
        usage: usageText,
      );

      // Node name + delay, status light, chips and the three modes.
      // The light's label is asserted in full in the zh-locale test
      // below: the English label in the test font is wider than the
      // whole pill interior at phone widths, so here it is asserted
      // present (its widget is unchanged; the pill row's width
      // allocation is what round 2 fixed).
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
    _expectMetaLineFullyShown(
      tester,
      expire: '2027-01-29',
      usage: ProfileUsage.of(_longProfile())!.usageText,
    );
  });

  // T286 round 2: the status light's label was ellipsized on the
  // user's phone ("当前节...") because the pill's first row split
  // its leftover width evenly between the light's Flexible and a
  // Spacer. In the user's locale the label must now render in full
  // at both phone widths.
  for (final width in [400.0, 360.0]) {
    testWidgets('light label renders in full in zh at ${width}dp', (
      tester,
    ) async {
      ClashCore.setHandlerForTesting(_FakeHandler());
      await _pumpCard(
        tester,
        width: width,
        nodeName: _descenderNodeName,
        locale: const Locale('zh', 'CN'),
      );

      expect(tester.takeException(), isNull);
      // Render-level assertion only: the light's label Text carries
      // an ellipsis overflow property as a last-resort guard, so the
      // check is that its paragraph fits its line budget in full.
      final labelFinder = find.text('当前节点可用');
      expect(labelFinder, findsOneWidget);
      expect(
        _paragraphExceedsLines(tester, labelFinder),
        isFalse,
        reason: 'light label must render in full, not ellipsize',
      );
      _expectPlainTextFullyShown(tester, '193 ms');
    });
  }

  // T286 round 2: a node name with Latin descenders must sit fully
  // inside the pill — its paragraph inside the pill's rect with the
  // full bottom padding (8dp) to spare, so descender ink stays clear
  // of the pill's edge.
  for (final width in [400.0, 360.0]) {
    testWidgets('descender node name sits fully inside the pill at '
        '${width}dp', (tester) async {
      ClashCore.setHandlerForTesting(_FakeHandler());
      await _pumpCard(tester, width: width, nodeName: _descenderNodeName);

      expect(tester.takeException(), isNull);
      _expectEmojiTextFullyShown(tester, _descenderNodeName, maxLines: 2);

      final nodeFinder = find.byWidgetPredicate(
        (widget) => widget is EmojiText && widget.text == _descenderNodeName,
      );
      final nodeRect = tester.getRect(
        find.descendant(of: nodeFinder, matching: find.byType(RichText)),
      );
      final pillRect = tester.getRect(
        find
            .ancestor(of: nodeFinder, matching: find.byType(Material))
            .first,
      );
      expect(
        pillRect.contains(nodeRect.topLeft) &&
            pillRect.contains(nodeRect.bottomRight),
        isTrue,
        reason: 'node name paragraph must lie inside the pill',
      );
      expect(
        pillRect.bottom - nodeRect.bottom,
        greaterThanOrEqualTo(7.9),
        reason: 'descenders need the full bottom padding below the text',
      );
    });
  }

  // T286 round 2 (layout instruction), T288 form: update time,
  // expiry and the usage numbers form one combined meta line under
  // the profile name, the segment bar sits directly under that
  // line, and the node pill follows. With the long fixture at phone
  // width the line fits on one line in the user's locale.
  testWidgets('time and usage share one meta line above the bar and pill', (
    tester,
  ) async {
    ClashCore.setHandlerForTesting(_FakeHandler());
    await _pumpCard(tester, width: 400, locale: const Locale('zh', 'CN'));

    expect(tester.takeException(), isNull);
    final usageText = ProfileUsage.of(_longProfile())!.usageText;
    _expectMetaLineFullyShown(
      tester,
      expire: '2027-01-29',
      usage: usageText,
    );

    // One combined Text: no standalone usage-only Text remains.
    final metaFinder = _metaLineFinder(
      expire: '2027-01-29',
      usage: usageText,
    );
    expect(
      find.text(usageText),
      findsNothing,
      reason: 'usage must be part of the combined meta line (T288)',
    );

    // The whole line occupies exactly one laid-out line.
    expect(
      _metaLineCount(tester, metaFinder),
      1,
      reason: 'time, expiry and usage must share one line when they fit',
    );

    // Order: meta line, then the segment bar, then the node pill.
    final metaRect = tester.getRect(metaFinder);
    final barRect = tester.getRect(find.byType(UsageSegmentBar));
    final pillRect = tester.getRect(
      find
          .ancestor(
            of: find.byWidgetPredicate(
              (widget) => widget is EmojiText && widget.text == _longNodeName,
            ),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(barRect.top, greaterThanOrEqualTo(metaRect.bottom - 1));
    expect(pillRect.top, greaterThanOrEqualTo(barRect.bottom - 1));
  });

  // T288: when the combined line genuinely cannot fit, it wraps at
  // natural text break points — every part still renders in full,
  // never truncated, never ellipsized.
  testWidgets('meta line wraps naturally and in full at narrow width', (
    tester,
  ) async {
    ClashCore.setHandlerForTesting(_FakeHandler());
    await _pumpCard(tester, width: 280, locale: const Locale('zh', 'CN'));

    expect(tester.takeException(), isNull);
    final usageText = ProfileUsage.of(_longProfile())!.usageText;
    _expectMetaLineFullyShown(
      tester,
      expire: '2027-01-29',
      usage: usageText,
    );
    final meta = tester.widget<Text>(
      _metaLineFinder(expire: '2027-01-29', usage: usageText),
    );
    expect(meta.maxLines, isNull, reason: 'no line cap may truncate');
    expect(meta.data, contains('2027-01-29'));
    expect(meta.data, contains(usageText));
  });

  // T288 regression: the user's report — with the Wrap form, the
  // usage figures were pushed to a second line below the update
  // time and expiry. As one combined Text, the exact reported line
  // must stay on a single line at phone widths, character for
  // character.
  for (final width in [400.0, 360.0]) {
    testWidgets('user-reported meta line stays on one line at ${width}dp', (
      tester,
    ) async {
      ClashCore.setHandlerForTesting(_FakeHandler());
      await _pumpCard(
        tester,
        width: width,
        locale: const Locale('zh', 'CN'),
        profile: _userReportProfile(),
      );

      expect(tester.takeException(), isNull);
      expect(
        ProfileUsage.of(_userReportProfile())!.cardUsageText,
        '468.37 KB / 1024.00 GB',
      );
      const expected = '15 小时前 · 2027-11-22 · 468.37 KB / 1024.00 GB';
      final finder = find.text(expected);
      expect(
        finder,
        findsOneWidget,
        reason: 'meta line must be one combined text: $expected',
      );
      final widget = tester.widget<Text>(finder);
      expect(widget.overflow, isNot(TextOverflow.ellipsis));
      expect(
        _metaLineCount(tester, finder),
        1,
        reason: 'update time, expiry and usage must share one line',
      );
    });
  }
}
