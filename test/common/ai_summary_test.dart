import 'package:bett_box/common/ai_client.dart';
import 'package:bett_box/models/patrol.dart';
import 'package:bett_box/models/patrol_diagnosis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('summary masks node names, subscription URLs and UUIDs', () {
    final report = PatrolReport.build(
      now: DateTime(2026),
      logs: [
        PatrolLogEntry(
          level: 'error',
          payload:
              'dial 香港故宫-01 failed via https://user:pass@sub.example.com:8443/api?token=abcdef '
              '550e8400-e29b-41d4-a716-446655440000',
          time: DateTime(2026),
        ),
      ],
      subscription: const PatrolSubscriptionInput(
        hasProfile: true,
        isRemote: true,
        lastUpdateFailed: true,
      ),
      nodes: const [PatrolNodeSample(name: '香港故宫-01', delay: 0)],
      link: const PatrolLinkInput(mode: 'rule'),
      core: const PatrolCoreInput(versionLabel: '1.19.7+1'),
    );
    final summary = buildPatrolSummary(report, nodeNames: ['香港故宫-01']);
    expect(summary, isNot(contains('香港故宫-01')));
    expect(summary, isNot(contains('token=abcdef')));
    expect(summary, isNot(contains('550e8400')));
    expect(summary, isNot(contains('user:pass')));
    expect(summary, contains('sub.example.com'));
    expect(summary, contains('lastUpdateFailed: true'));
  });

  test('maskPatrolName keeps only edge characters', () {
    expect(maskPatrolName('ab'), '•••');
    expect(maskPatrolName('abc'), 'a•••');
    expect(maskPatrolName('node-01'), 'n•••1');
  });

  group('sanitizeAiText (T69)', () {
    test('strips markdown emphasis, headings and br tags', () {
      final cleaned = sanitizeAiText(
        '## 结论\n**最可能的原因**是服务器故障。<br>请稍后再试。',
      );
      expect(cleaned, isNot(contains('**')));
      expect(cleaned, isNot(contains('<br>')));
      expect(cleaned, isNot(contains('##')));
      expect(cleaned, contains('最可能的原因'));
      expect(cleaned, contains('\n'));
    });

    test('markdown tables become plain cell lines', () {
      final cleaned = sanitizeAiText(
        '| 环节 | 结果 |\n| --- | --- |\n| DNS 解析 | 失败 |',
      );
      expect(cleaned, isNot(contains('|')));
      expect(cleaned, contains('环节 · 结果'));
      expect(cleaned, contains('DNS 解析 · 失败'));
    });

    test('html tags are removed but text survives', () {
      final cleaned = sanitizeAiText('<p>第一段</p><p>第二段</p>');
      expect(cleaned, isNot(contains('<')));
      expect(cleaned, contains('第一段'));
      expect(cleaned, contains('第二段'));
    });
  });

  test('issue summary carries the local diagnosis as a fact (T69)', () {
    const issue = PatrolIssue(
      id: 'subscription.fetch',
      section: PatrolIssueSection.logs,
      severity: PatrolSeverity.problem,
      cause: PatrolCause.fetchFailed,
      stage: PatrolFetchStage.http,
      httpStatus: 502,
    );
    final summary = buildPatrolIssueSummary(
      issue,
      nodeNames: const [],
      localConclusion: '服务商服务器故障（502），不是你的链接有问题。',
      localAdvice: '等服务商恢复后点更新重试。',
    );
    expect(summary, contains('established fact'));
    expect(summary, contains('服务商服务器故障（502）'));
    expect(summary, contains('等服务商恢复后点更新重试'));
  });

  test('report summary carries local conclusions as facts (T69)', () {
    final report = PatrolReport.build(
      now: DateTime(2026),
      logs: const [],
      subscription: const PatrolSubscriptionInput(
        hasProfile: true,
        isRemote: true,
      ),
      nodes: const [],
      link: const PatrolLinkInput(mode: 'rule'),
      core: const PatrolCoreInput(versionLabel: '1.19.7+1'),
    );
    final summary = buildPatrolSummary(
      report,
      nodeNames: const [],
      localConclusions: const ['配置校验尚未运行。'],
    );
    expect(summary, contains('established facts'));
    expect(summary, contains('配置校验尚未运行。'));
  });
}
