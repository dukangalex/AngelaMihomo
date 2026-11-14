import 'package:bett_box/models/patrol.dart';
import 'package:flutter_test/flutter_test.dart';

PatrolLogEntry entry(String level, String payload) => PatrolLogEntry(
  level: level,
  payload: payload,
  time: DateTime(2026, 10, 31),
);

void main() {
  group('log classification', () {
    test('classifies connection failures', () {
      final section = classifyLogs([
        entry(
          'error',
          '[TCP] dial GLOBAL 203.0.113.1:443 error: dial tcp '
              '203.0.113.1:443: connect: connection refused',
        ),
        entry('warning', '[UDP] dial DIRECT error: network is unreachable'),
      ]);
      expect(section.totalIssues, 2);
      expect(section.groupOf(PatrolLogIssueKind.connection)?.count, 2);
      expect(section.severity, PatrolSeverity.problem);
    });

    test('dns failures are their own class, not connection failures', () {
      final section = classifyLogs([
        entry('error', '[DNS] resolve example.com error: no such host'),
        entry(
          'warning',
          'dial tcp: lookup api.example.com on 223.5.5.5:53: '
              'failed to resolve',
        ),
      ]);
      expect(section.groupOf(PatrolLogIssueKind.dns)?.count, 2);
      expect(section.groupOf(PatrolLogIssueKind.connection), isNull);
    });

    test('timeout wins over the dial failure it rides on', () {
      final section = classifyLogs([
        entry(
          'error',
          '[TCP] dial PROXY 198.51.100.2:443 error: dial tcp '
              '198.51.100.2:443: i/o timeout',
        ),
      ]);
      expect(section.groupOf(PatrolLogIssueKind.timeout)?.count, 1);
      expect(section.groupOf(PatrolLogIssueKind.connection), isNull);
    });

    test('rule provider problems are classified as rule issues', () {
      final section = classifyLogs([
        entry('error', 'initial rule provider [geoip] failed: mmdb invalid'),
        entry('warning', 'failed to load geosite database'),
      ]);
      expect(section.groupOf(PatrolLogIssueKind.rule)?.count, 2);
    });

    test('info and debug entries never count, even with scary words', () {
      final section = classifyLogs([
        entry('info', '[TCP] 192.0.2.1:1234 --> example.com:443 connect ok'),
        entry('debug', 'dns cache hit for example.com'),
      ]);
      expect(section.totalIssues, 0);
      expect(section.hasIssues, isFalse);
      expect(section.severity, PatrolSeverity.ok);
    });

    test('sample is the most recent payload of the group', () {
      final section = classifyLogs([
        entry('error', 'dial tcp 192.0.2.1:443: connect: connection refused'),
        entry('error', 'dial tcp 192.0.2.2:443: connect: connection refused'),
      ]);
      expect(
        section.groupOf(PatrolLogIssueKind.connection)?.sample,
        contains('192.0.2.2'),
      );
    });
  });

  group('subscription freshness', () {
    final now = DateTime(2026, 10, 31, 12);

    PatrolSubscriptionSection evaluate(PatrolSubscriptionInput input) =>
        evaluateSubscription(input, now);

    test('fresh remote profile is ok', () {
      final section = evaluate(
        PatrolSubscriptionInput(
          hasProfile: true,
          isRemote: true,
          lastUpdateDate: now.subtract(const Duration(hours: 2)),
          autoUpdateEnabled: true,
          autoUpdateDuration: const Duration(hours: 24),
        ),
      );
      expect(section.severity, PatrolSeverity.ok);
    });

    test('expired subscription is a problem', () {
      final section = evaluate(
        PatrolSubscriptionInput(
          hasProfile: true,
          isRemote: true,
          lastUpdateDate: now.subtract(const Duration(hours: 2)),
          expiresAt: now.subtract(const Duration(days: 1)),
        ),
      );
      expect(section.isExpired, isTrue);
      expect(section.severity, PatrolSeverity.problem);
    });

    test('overdue auto-update is stale (notice, not problem)', () {
      final section = evaluate(
        PatrolSubscriptionInput(
          hasProfile: true,
          isRemote: true,
          lastUpdateDate: now.subtract(const Duration(days: 3)),
          autoUpdateEnabled: true,
          autoUpdateDuration: const Duration(hours: 24),
        ),
      );
      expect(section.isStale, isTrue);
      expect(section.severity, PatrolSeverity.notice);
    });

    test('never updated remote profile is a notice', () {
      final section = evaluate(
        const PatrolSubscriptionInput(hasProfile: true, isRemote: true),
      );
      expect(section.neverUpdated, isTrue);
      expect(section.severity, PatrolSeverity.notice);
    });

    test('recorded update failure is a problem', () {
      final section = evaluate(
        PatrolSubscriptionInput(
          hasProfile: true,
          isRemote: true,
          lastUpdateDate: now.subtract(const Duration(hours: 1)),
          lastUpdateFailed: true,
        ),
      );
      expect(section.severity, PatrolSeverity.problem);
    });

    test('local profile never goes stale or expires', () {
      final section = evaluate(
        PatrolSubscriptionInput(
          hasProfile: true,
          isRemote: false,
          lastUpdateDate: now.subtract(const Duration(days: 365)),
          expiresAt: now.subtract(const Duration(days: 1)),
        ),
      );
      expect(section.isExpired, isFalse);
      expect(section.isStale, isFalse);
      expect(section.severity, PatrolSeverity.ok);
    });

    test('no profile selected is a notice', () {
      final section = evaluate(
        const PatrolSubscriptionInput(hasProfile: false, isRemote: false),
      );
      expect(section.severity, PatrolSeverity.notice);
    });
  });

  group('node health aggregation', () {
    PatrolNodeSample node(String name, int? delay) =>
        PatrolNodeSample(name: name, delay: delay);

    test('all alive is ok', () {
      final section = evaluateNodes([
        node('a', 50),
        node('b', 120),
        node('c', null),
      ]);
      expect(section.alive, 2);
      expect(section.untested, 1);
      expect(section.severity, PatrolSeverity.ok);
    });

    test('a few dead nodes are a notice, not an outage', () {
      final section = evaluateNodes([
        node('a', 50),
        node('b', 90),
        node('c', 0),
        node('d', 200),
      ]);
      expect(section.dead, 1);
      expect(section.widespreadOutage, isFalse);
      expect(section.severity, PatrolSeverity.notice);
    });

    test('most nodes down is a widespread outage (problem)', () {
      final samples = [
        for (var i = 0; i < 7; i++) node('dead$i', 0),
        for (var i = 0; i < 3; i++) node('alive$i', 80),
      ];
      final section = evaluateNodes(samples);
      expect(section.widespreadOutage, isTrue);
      expect(section.severity, PatrolSeverity.problem);
    });

    test('all tested nodes dead is a problem even below outage samples', () {
      final section = evaluateNodes([node('a', 0), node('b', -1)]);
      expect(section.severity, PatrolSeverity.problem);
    });

    test('no test data yet is a notice', () {
      final section = evaluateNodes([node('a', null), node('b', null)]);
      expect(section.tested, 0);
      expect(section.severity, PatrolSeverity.notice);
    });

    test('no nodes at all is a notice', () {
      final section = evaluateNodes(const []);
      expect(section.total, 0);
      expect(section.severity, PatrolSeverity.notice);
    });
  });

  group('config check translation', () {
    test('empty core answer means the check passed', () {
      expect(translateConfigCheck(''), PatrolConfigCheck.passed);
    });

    test('empty profile path means the check could not run yet', () {
      // The exact string the Go core returns when the runtime has no
      // profile path yet (service never started): not a config failure.
      expect(
        translateConfigCheck('profile path is empty'),
        PatrolConfigCheck.unavailable,
      );
    });

    test('the not-ready signature is matched inside a longer message', () {
      expect(
        translateConfigCheck('setup failed: profile path is empty'),
        PatrolConfigCheck.unavailable,
      );
    });

    test('any other core answer is a genuine failure', () {
      expect(
        translateConfigCheck('proxy 1: missing field'),
        PatrolConfigCheck.failed,
      );
      expect(
        translateConfigCheck('yaml: line 3: mapping values not allowed'),
        PatrolConfigCheck.failed,
      );
    });

    test('unavailable check is a notice and never counts as a problem', () {
      final now = DateTime(2026, 10, 31, 12);
      final report = PatrolReport.build(
        now: now,
        logs: const [],
        subscription: PatrolSubscriptionInput(
          hasProfile: true,
          isRemote: true,
          lastUpdateDate: now,
        ),
        nodes: const [PatrolNodeSample(name: 'a', delay: 42)],
        link: const PatrolLinkInput(mode: 'rule'),
        core: const PatrolCoreInput(
          versionLabel: '1.19.7',
          configCheck: PatrolConfigCheck.unavailable,
        ),
      );
      expect(report.core.severity, PatrolSeverity.notice);
      expect(report.problemCount, 0);
      expect(report.hasProblems, isFalse);
      expect(report.noticeCount, 1);
    });
  });

  group('report headline', () {
    test('counts problem and notice sections separately', () {
      final now = DateTime(2026, 10, 31, 12);
      final report = PatrolReport.build(
        now: now,
        logs: [entry('error', 'dial tcp 192.0.2.1:443: connection refused')],
        subscription: const PatrolSubscriptionInput(
          hasProfile: false,
          isRemote: false,
        ),
        nodes: const [PatrolNodeSample(name: 'a', delay: 42)],
        link: const PatrolLinkInput(mode: 'rule'),
        core: const PatrolCoreInput(
          versionLabel: '1.19.7',
          configCheck: PatrolConfigCheck.passed,
        ),
      );
      expect(report.problemCount, 1);
      expect(report.noticeCount, 1);
      expect(report.attentionCount, 2);
      expect(report.hasProblems, isTrue);
    });

    test('chain hop down and invalid config are problems', () {
      final now = DateTime(2026, 10, 31, 12);
      final report = PatrolReport.build(
        now: now,
        logs: const [],
        subscription: PatrolSubscriptionInput(
          hasProfile: true,
          isRemote: true,
          lastUpdateDate: now,
        ),
        nodes: const [PatrolNodeSample(name: 'a', delay: 42)],
        link: const PatrolLinkInput(
          mode: 'rule',
          chainEnabled: true,
          chainEntry: 'entry-node',
          chainLanding: 'landing-node',
          chainEntryAlive: false,
        ),
        core: const PatrolCoreInput(
          versionLabel: '1.19.7',
          configCheck: PatrolConfigCheck.failed,
          configError: 'proxy 1: missing field',
        ),
      );
      expect(report.link.chainHopDown, isTrue);
      expect(report.problemCount, 2);
    });
  });
}
