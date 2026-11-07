import 'package:bett_box/common/ai_client.dart';
import 'package:bett_box/models/patrol.dart';
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
}
