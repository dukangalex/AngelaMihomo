import 'package:bett_box/common/common.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/patrol_detail.dart';
import 'package:bett_box/views/patrol_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:shared_preferences/shared_preferences.dart';

/// T69 regression lock for the field report that showed the
/// "what to do" block twice on the subscription-failure detail
/// page (with the probe button mixed into the first copy).
/// Source inspection says the section is built exactly once — the
/// duplication was a long-screenshot stitching artifact — so this
/// test pins the structure: the advice section title, the advice
/// text, the fix row and the probe button each appear exactly
/// once. If a future change ever renders the section twice for
/// real, this fails.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLocalizations.load(const Locale('en'));
  });

  setUp(() {
    globalState.config = Config(themeProps: defaultThemeProps);
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

  testWidgets('fetch-failure detail renders each block exactly once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const issue = PatrolIssue(
      id: 'subscription.fetch',
      section: PatrolIssueSection.logs,
      severity: PatrolSeverity.problem,
      cause: PatrolCause.fetchFailed,
      stage: PatrolFetchStage.http,
      httpStatus: 502,
      action: PatrolAction.updateSubscription,
      facts: [
        PatrolFact.occurrences(count: 3),
        PatrolFact.recordedError('DioException: status code 502'),
      ],
      probePlan: [PatrolProbeKind.dnsLookup, PatrolProbeKind.directFetch],
      probeUrl: 'https://example.com/sub.yaml',
    );

    PatrolReport report() => PatrolReport.build(
      now: DateTime(2026, 11, 9),
      logs: const [],
      subscription: const PatrolSubscriptionInput(
        hasProfile: true,
        isRemote: true,
        lastUpdateFailed: true,
      ),
      nodes: const [],
      link: const PatrolLinkInput(mode: 'rule'),
      core: const PatrolCoreInput(versionLabel: 'test'),
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: mui.MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...mui.GlobalMaterialLocalizations.delegates,
            ],
            locale: const Locale('en'),
            home: PatrolDetailView(
              issue: issue,
              profile: null,
              aiConfig: null,
              nodeNames: const [],
              coreRunning: false,
              proxyPort: 7890,
              readReport: report,
              refreshConfigCheck: () async {},
              reloadUpdateFailure: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    expect(
      find.text(appLocalizations.patrolDetailAdvice),
      findsOneWidget,
      reason: 'the "what to do" section title must render once',
    );
    expect(
      find.text(patrolIssueAdvice(issue)),
      findsOneWidget,
      reason: 'the advice text must render once',
    );
    expect(
      find.text(appLocalizations.patrolFix),
      findsOneWidget,
      reason: 'the fix button must render once',
    );
    expect(
      find.text(patrolActionLabel(PatrolAction.updateSubscription)),
      findsOneWidget,
      reason: 'the fix row must render once',
    );
    expect(
      find.text(appLocalizations.patrolDetailRunProbes),
      findsOneWidget,
      reason: 'the probe button must render once, outside the advice',
    );
  });
}
