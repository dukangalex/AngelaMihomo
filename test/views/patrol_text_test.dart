import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/patrol.dart';
import 'package:bett_box/models/patrol_diagnosis.dart';
import 'package:bett_box/views/patrol_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wording-layer checks for the real-device failure shapes
/// (t68-real-device-log-2026-11-08.log): an HTTP 5xx answer is the
/// provider's server failing — the conclusion must say exactly that
/// and must never blame the user's link or network, while a 4xx
/// keeps the "link refused" wording.
void main() {
  group('patrolHttpIsServerError', () {
    test('5xx only', () {
      expect(patrolHttpIsServerError(500), isTrue);
      expect(patrolHttpIsServerError(502), isTrue);
      expect(patrolHttpIsServerError(599), isTrue);
      expect(patrolHttpIsServerError(404), isFalse);
      expect(patrolHttpIsServerError(200), isFalse);
      expect(patrolHttpIsServerError(null), isFalse);
    });
  });

  group('patrolStageConclusion http wording', () {
    setUpAll(() async {
      await AppLocalizations.load(const Locale('en'));
    });

    PatrolIssue fetchIssue(int status) => PatrolIssue(
      id: 'subscription.fetch',
      section: PatrolIssueSection.logs,
      severity: PatrolSeverity.problem,
      cause: PatrolCause.fetchFailed,
      stage: PatrolFetchStage.http,
      httpStatus: status,
      action: PatrolAction.updateSubscription,
    );

    test('502 reads as a provider server fault', () {
      final text = patrolIssueConclusion(fetchIssue(502));
      expect(text, contains('502'));
      expect(text.toLowerCase(), contains('server itself failed'));
      expect(text.toLowerCase(), contains('not your network'));
      expect(text.toLowerCase(), isNot(contains('expired')));
      final advice = patrolIssueAdvice(fetchIssue(502));
      expect(advice.toLowerCase(), contains('do not replace your link'));
    });

    test('404 keeps the refused-link wording and advice', () {
      final text = patrolIssueConclusion(fetchIssue(404));
      expect(text, contains('404'));
      expect(text.toLowerCase(), contains('refused to serve'));
      final advice = patrolIssueAdvice(fetchIssue(404));
      expect(advice.toLowerCase(), contains('fresh subscription link'));
    });

    test('a live-measured status overrides the recorded one', () {
      // Recorded 404, but the live probe just measured 502: the
      // conclusion follows what the server answers now.
      final text = patrolIssueConclusion(
        fetchIssue(404),
        measuredStage: PatrolFetchStage.http,
        measuredHttpStatus: 502,
      );
      expect(text, contains('502'));
      expect(text.toLowerCase(), contains('server itself failed'));
    });
  });
}
