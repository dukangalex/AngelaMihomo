import 'package:bett_box/models/patrol.dart';
import 'package:bett_box/models/patrol_diagnosis.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture clock used by [reportWith]; "healthy" fixtures must stamp their
/// last update at this instant so they are neither never-updated nor stale.
final _fixtureNow = DateTime(2026, 11, 8, 12);

PatrolReport reportWith({
  List<PatrolLogEntry> logs = const [],
  PatrolSubscriptionInput subscription = const PatrolSubscriptionInput(
    hasProfile: true,
    isRemote: true,
  ),
  List<PatrolNodeSample> nodes = const [],
  PatrolLinkInput link = const PatrolLinkInput(mode: 'rule'),
  PatrolCoreInput core = const PatrolCoreInput(versionLabel: 'test'),
}) {
  return PatrolReport.build(
    now: DateTime(2026, 11, 8, 12),
    logs: logs,
    subscription: subscription,
    nodes: nodes,
    link: link,
    core: core,
  );
}

PatrolLogEntry entry(String payload) => PatrolLogEntry(
  level: 'error',
  payload: payload,
  time: DateTime(2026, 11, 8, 11, 59),
);

void main() {
  group('classifyFetchFailure', () {
    test('the field instance stays honestly unknown', () {
      // The exact string from the user's device (T68): the record
      // alone cannot name a stage, and the classifier must not fake
      // one — live probes decide.
      final result = classifyFetchFailure('DioException [unknown]: null');
      expect(result.stage, PatrolFetchStage.unknown);
      expect(result.httpStatus, isNull);
    });

    test('dns failures', () {
      expect(
        classifyFetchFailure(
          'DioException [connection error]: SocketException: '
          'Failed host lookup: sub.example.com',
        ).stage,
        PatrolFetchStage.dns,
      );
      expect(
        classifyFetchFailure('SocketException: no such host').stage,
        PatrolFetchStage.dns,
      );
    });

    test('tcp failures', () {
      expect(
        classifyFetchFailure(
          'SocketException: Connection refused (OS Error: Connection '
          'refused, errno = 111)',
        ).stage,
        PatrolFetchStage.tcp,
      );
      expect(
        classifyFetchFailure(
          'DioException [connection error]: Connection reset by peer',
        ).stage,
        PatrolFetchStage.tcp,
      );
    });

    test('tls failures', () {
      expect(
        classifyFetchFailure(
          'HandshakeException: CERTIFICATE_VERIFY_FAILED',
        ).stage,
        PatrolFetchStage.tls,
      );
    });

    test('http failures carry the status', () {
      final bad = classifyFetchFailure(
        'DioException [bad response]: This exception was thrown '
        'because the response has a status code of 404',
      );
      expect(bad.stage, PatrolFetchStage.http);
      expect(bad.httpStatus, 404);
      final formatted = classifyFetchFailure(
        'Failed to import profile. Please check your network status '
        'or try resetting the subscription link ( HTTP error code: 503 )',
      );
      expect(formatted.stage, PatrolFetchStage.http);
      expect(formatted.httpStatus, 503);
    });

    test('real-device shapes 2026-11-08 (user phone log)', () {
      // Verbatim shapes from t68-real-device-log-2026-11-08.log:
      // the circled subscription failed 14 times in three shapes.
      // Shape 1: HTTP 502 — the path is fine, the provider's server
      // failed; it must classify as http/502 (the wording layer maps
      // 5xx to the server-fault conclusion, never to "bad link").
      final server = classifyFetchFailure(
        'Failed to import profile. Please check your network status '
        'or try resetting the subscription link ( HTTP error code: 502 )',
      );
      expect(server.stage, PatrolFetchStage.http);
      expect(server.httpStatus, 502);
      // Shape 2: DioException [unknown] wrapping a handshake that was
      // terminated mid-flight — the stage is TLS, not HTTP.
      final handshake = classifyFetchFailure(
        'DioException [unknown]: null\n'
        'Error: HandshakeException: Connection terminated during '
        'handshake',
      );
      expect(handshake.stage, PatrolFetchStage.tls);
      expect(handshake.httpStatus, isNull);
      // Shape 3: connection reset by peer — TCP stage.
      final reset = classifyFetchFailure(
        'DioException [connection error]: The connection errored: '
        'Connection reset by peer This indicates an error which most '
        'likely cannot be solved by the library.\n'
        'Error: SocketException: Connection reset by peer (OS Error: '
        'Connection reset by peer, errno = 104)',
      );
      expect(reset.stage, PatrolFetchStage.tcp);
    });

    test('timeouts', () {
      expect(
        classifyFetchFailure(
          'DioException [connectionTimeout]: connection timed out',
        ).stage,
        PatrolFetchStage.timeout,
      );
      expect(
        classifyFetchFailure('SocketException: i/o timeout').stage,
        PatrolFetchStage.timeout,
      );
    });

    test('proxy hop failures', () {
      expect(
        classifyFetchFailure(
          'HttpException: Proxy failed to establish tunnel',
        ).stage,
        PatrolFetchStage.proxy,
      );
    });

    test('bad content', () {
      expect(
        classifyFetchFailure(
          'FormatException: Configuration is empty. The existing '
          'profile was kept.',
        ).stage,
        PatrolFetchStage.badContent,
      );
    });
  });

  group('fetch log classification (T68)', () {
    test('missed-update lines are their own class', () {
      final section = classifyLogs([
        entry(
          '[MissedUpdate] Failed to update Hnekozgo: '
          'DioException [unknown]: null',
        ),
        entry('[AutoUpdate] Failed to update Other: timeout'),
      ]);
      final group = section.groupOf(PatrolLogIssueKind.subscriptionFetch);
      expect(group, isNotNull);
      expect(group!.count, 2);
      expect(section.groupOf(PatrolLogIssueKind.timeout), isNull);
      expect(section.suggestedAction, PatrolAction.updateSubscription);
    });

    test('a group keeps the three latest samples with a window', () {
      final section = classifyLogs([
        for (var i = 0; i < 5; i++)
          PatrolLogEntry(
            level: 'warning',
            payload: 'dial tcp 10.0.0.$i:443 error: connection refused',
            time: DateTime(2026, 11, 8, 10, i),
          ),
      ]);
      final group = section.groupOf(PatrolLogIssueKind.connection)!;
      expect(group.count, 5);
      expect(group.samples.length, 3);
      expect(group.samples.first, contains('10.0.0.2'));
      expect(group.samples.last, contains('10.0.0.4'));
      expect(group.firstAt, DateTime(2026, 11, 8, 10, 0));
      expect(group.lastAt, DateTime(2026, 11, 8, 10, 4));
    });
  });

  group('buildPatrolIssues', () {
    test('the field instance becomes one merged fetch diagnosis', () {
      final report = reportWith(
        logs: [
          entry(
            '[MissedUpdate] Failed to update Hnekozgo: '
            'DioException [unknown]: null',
          ),
        ],
        subscription: const PatrolSubscriptionInput(
          hasProfile: true,
          isRemote: true,
          lastUpdateFailed: true,
          lastUpdateError: 'DioException [unknown]: null',
        ),
      );
      final issues = buildPatrolIssues(
        report,
        coreRunning: true,
        subscriptionUrl: 'https://sub.example.com/feed?token=x',
      );
      final fetch = issues.where((i) => i.isFetch).toList();
      expect(fetch, hasLength(1));
      final issue = fetch.single;
      // Homed in the log section — that is where the user meets it.
      expect(issue.section, PatrolIssueSection.logs);
      expect(issue.stage, PatrolFetchStage.unknown);
      expect(issue.action, PatrolAction.updateSubscription);
      expect(
        issue.facts.where((f) => f.kind == PatrolFactKind.recordedError),
        hasLength(1),
      );
      expect(
        issue.facts.where((f) => f.kind == PatrolFactKind.occurrences),
        hasLength(1),
      );
      // Core running: the proxy hop is probed first.
      expect(issue.probePlan.first, PatrolProbeKind.proxyPort);
      expect(issue.probePlan, contains(PatrolProbeKind.proxyFetch));
      // The raw error survives for the 原始信息 fold.
      expect(issue.rawInfo, contains('DioException'));
    });

    test('a recorded failure without log lines homes in subscription', () {
      final report = reportWith(
        subscription: const PatrolSubscriptionInput(
          hasProfile: true,
          isRemote: true,
          lastUpdateFailed: true,
          lastUpdateError:
              'DioException [bad response]: status code of 404',
        ),
      );
      final issues = buildPatrolIssues(
        report,
        coreRunning: false,
        subscriptionUrl: 'https://sub.example.com/feed',
      );
      final issue = issues.singleWhere((i) => i.isFetch);
      expect(issue.section, PatrolIssueSection.subscription);
      expect(issue.stage, PatrolFetchStage.http);
      expect(issue.httpStatus, 404);
      // Core stopped: no proxy probes, the app fetches direct.
      expect(issue.probePlan, isNot(contains(PatrolProbeKind.proxyPort)));
      expect(issue.probePlan, contains(PatrolProbeKind.directFetch));
    });

    test('log classes become issues with evidence and fixes', () {
      final report = reportWith(
        logs: [
          entry('[DNS] resolve example.com error: no such host'),
          entry('dial tcp 198.51.100.2:443 error: i/o timeout'),
        ],
      );
      final issues = buildPatrolIssues(report, coreRunning: true);
      final dns = issues.singleWhere((i) => i.cause == PatrolCause.logDns);
      expect(dns.action, PatrolAction.flushDns);
      expect(
        dns.facts.where((f) => f.kind == PatrolFactKind.sample),
        hasLength(1),
      );
      final timeout = issues.singleWhere(
        (i) => i.cause == PatrolCause.logTimeout,
      );
      expect(timeout.action, PatrolAction.testNodes);
    });

    test('config failure carries the core message as evidence', () {
      final report = reportWith(
        core: const PatrolCoreInput(
          versionLabel: 'test',
          configCheck: PatrolConfigCheck.failed,
          configError: 'proxy 0: duplicate port 7890',
        ),
      );
      final issues = buildPatrolIssues(report, coreRunning: true);
      final issue = issues.singleWhere(
        (i) => i.cause == PatrolCause.configInvalid,
      );
      expect(issue.action, PatrolAction.reloadConfig);
      expect(issue.rawInfo, contains('duplicate port'));
    });

    test('widespread node outage is a problem with a retest fix', () {
      final report = reportWith(
        nodes: [
          for (var i = 0; i < 6; i++)
            PatrolNodeSample(name: 'n$i', delay: i == 0 ? 120 : 0),
        ],
      );
      final issues = buildPatrolIssues(report, coreRunning: true);
      final issue = issues.singleWhere(
        (i) => i.cause == PatrolCause.nodesWidespread,
      );
      expect(issue.severity, PatrolSeverity.problem);
      expect(issue.action, PatrolAction.testNodes);
    });

    test('a healthy report yields no issues', () {
      final report = reportWith(
        subscription: PatrolSubscriptionInput(
          hasProfile: true,
          isRemote: true,
          lastUpdateDate: _fixtureNow,
        ),
        nodes: const [PatrolNodeSample(name: 'a', delay: 100)],
        core: const PatrolCoreInput(
          versionLabel: 'test',
          configCheck: PatrolConfigCheck.passed,
        ),
      );
      expect(buildPatrolIssues(report, coreRunning: true), isEmpty);
    });
  });

  group('measuredStageFromProbes', () {
    test('proxy port down is the proxy stage', () {
      expect(
        measuredStageFromProbes({
          PatrolProbeKind.proxyPort: (ok: false, detail: 'refused'),
          PatrolProbeKind.dnsLookup: (ok: true, detail: ''),
        }),
        PatrolFetchStage.proxy,
      );
    });

    test('dns failure wins over later stages', () {
      expect(
        measuredStageFromProbes({
          PatrolProbeKind.dnsLookup: (ok: false, detail: 'no such host'),
          PatrolProbeKind.tcpConnect: (ok: false, detail: 'skipped'),
        }),
        PatrolFetchStage.dns,
      );
    });

    test('a proxied failure with a working direct path is proxy', () {
      expect(
        measuredStageFromProbes({
          PatrolProbeKind.directFetch: (ok: true, detail: 'HTTP 200'),
          PatrolProbeKind.proxyFetch: (ok: false, detail: 'HTTP 407'),
        }),
        PatrolFetchStage.proxy,
      );
    });

    test('all passing probes measure no failure', () {
      expect(
        measuredStageFromProbes({
          PatrolProbeKind.dnsLookup: (ok: true, detail: ''),
          PatrolProbeKind.directFetch: (ok: true, detail: 'HTTP 200'),
        }),
        isNull,
      );
    });

    test('a measured 502 keeps its status for the conclusion', () {
      // Regression: the measured-stage lookup used to drop the HTTP
      // status, so a live-measured 502 fell back to the 4xx wording.
      final measured = measuredDiagnosisFromProbes({
        PatrolProbeKind.dnsLookup: (ok: true, detail: '1 address'),
        PatrolProbeKind.tcpConnect: (ok: true, detail: 'reachable'),
        PatrolProbeKind.directFetch: (ok: false, detail: 'HTTP 502'),
      });
      expect(measured?.stage, PatrolFetchStage.http);
      expect(measured?.httpStatus, 502);
      // The app-path probe reports the DioException text instead of
      // a bare "HTTP nnn" detail; the status must survive that too.
      final viaAppPath = measuredDiagnosisFromProbes({
        PatrolProbeKind.proxyFetch: (
          ok: false,
          detail:
              'DioException [bad response]: status code of 502',
        ),
      });
      expect(viaAppPath?.stage, PatrolFetchStage.http);
      expect(viaAppPath?.httpStatus, 502);
    });
  });

  group('verifyPatrolFix', () {
    test('a subscription update verifies when the problem clears', () {
      final before = reportWith(
        subscription: const PatrolSubscriptionInput(
          hasProfile: true,
          isRemote: true,
          lastUpdateFailed: true,
        ),
      );
      final after = reportWith();
      expect(
        verifyPatrolFix(
          PatrolAction.updateSubscription,
          before,
          after,
          updateFailed: false,
        ),
        isTrue,
      );
      expect(
        verifyPatrolFix(
          PatrolAction.updateSubscription,
          before,
          before,
          updateFailed: true,
        ),
        isFalse,
      );
    });
  });
}
