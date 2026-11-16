import 'package:bett_box/common/failure_notice.dart';
import 'package:bett_box/common/profile_chain.dart';
import 'package:bett_box/common/profile_chain_overlay.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => AppLocalizations.load(const Locale('zh', 'CN')));

  group('chainStaleReferenceOf', () {
    test('classifies every dedicated exception kind', () {
      expect(
        chainStaleReferenceOf(
          const ChainSelectionStaleException(
            ChainStaleReference.exitProfile,
            'The selected exit profile is no longer available.',
          ),
        ),
        ChainStaleReference.exitProfile,
      );
      expect(
        chainStaleReferenceOf(
          const ChainSelectionStaleException(
            ChainStaleReference.exitTarget,
            'The selected group is no longer in this profile.',
          ),
        ),
        ChainStaleReference.exitTarget,
      );
      expect(
        chainStaleReferenceOf(
          const ChainSelectionStaleException(
            ChainStaleReference.entry,
            'entry is gone',
          ),
        ),
        ChainStaleReference.entry,
      );
      expect(
        chainStaleReferenceOf(
          const ChainSelectionStaleException(
            ChainStaleReference.exitSameProfile,
            'The chain exit must be selected from another profile.',
          ),
        ),
        ChainStaleReference.exitSameProfile,
      );
    });

    test('classifies core entry/exit staleness strings', () {
      // patchChainPolicy (cross-profile entry resolution).
      expect(
        chainStaleReferenceOf(
          'entry "Node A" is not a directly verifiable node or group in the active profile',
        ),
        ChainStaleReference.entry,
      );
      // patchChainPolicy (same-profile tail checks).
      expect(
        chainStaleReferenceOf('entry "Node A" not found in this profile'),
        ChainStaleReference.entry,
      );
      expect(
        chainStaleReferenceOf('exit "Node B" not found in this profile'),
        ChainStaleReference.exitTarget,
      );
      // The core may wrap the wording; classification must still land.
      expect(
        chainStaleReferenceOf(
          'setup failed: entry "Node A" not found in this profile',
        ),
        ChainStaleReference.entry,
      );
    });

    test('leaves ambiguous and unrelated errors unclassified', () {
      // The legacy combined wording does not say which end is stale.
      expect(
        chainStaleReferenceOf(
          'entry "Node A" or exit "Node B" not found in this profile',
        ),
        isNull,
      );
      expect(chainStaleReferenceOf(StateError('boom')), isNull);
      expect(chainStaleReferenceOf('some core parse error'), isNull);
    });
  });

  group('profile chain overlay staleness', () {
    final source = <String, dynamic>{
      'proxies': [
        {'name': 'Node A', 'type': 'http', 'server': 'a.example', 'port': 80},
      ],
      'proxy-groups': [
        {
          'name': 'Outer',
          'type': 'select',
          'proxies': ['Inner', 'Node A'],
        },
        {
          'name': 'Inner',
          'type': 'select',
          'proxies': ['Node A'],
        },
      ],
    };

    test('missing exit target throws the dedicated exception', () {
      expect(
        () => ProfileChainOverlay.build(
          profileId: 'profile-1793192612',
          source: source,
          targetKind: ChainTargetKind.group,
          targetName: 'Renamed Away',
        ),
        throwsA(
          isA<ChainSelectionStaleException>()
              .having(
                (e) => e.reference,
                'reference',
                ChainStaleReference.exitTarget,
              )
              .having(
                (e) => e.message,
                'legacy wording',
                'The selected group is no longer in this profile.',
              ),
        ),
      );
    });

    test('missing nested exit group throws the dedicated exception', () {
      final broken = <String, dynamic>{
        'proxies': [
          {'name': 'Node A', 'type': 'http', 'server': 'a.example', 'port': 80},
        ],
        'proxy-groups': [
          {
            'name': 'Outer',
            'type': 'select',
            'proxies': ['Inner', 'Node A'],
          },
        ],
      };
      expect(
        () => ProfileChainOverlay.build(
          profileId: 'profile-1793192612',
          source: broken,
          targetKind: ChainTargetKind.group,
          targetName: 'Outer',
        ),
        throwsA(
          isA<ChainSelectionStaleException>().having(
            (e) => e.reference,
            'reference',
            ChainStaleReference.exitTarget,
          ),
        ),
      );
    });

    test('valid chain target still builds the overlay', () {
      final overlay = ProfileChainOverlay.build(
        profileId: 'profile-1793192612',
        source: source,
        targetKind: ChainTargetKind.group,
        targetName: 'Outer',
      );
      expect(overlay['external-target-kind'], 'group');
      expect((overlay['external-groups'] as List), hasLength(2));
      expect((overlay['external-proxies'] as List), hasLength(1));
    });
  });

  group('failure notices', () {
    test('switch failure with a stale exit profile selects the chain notice', () {
      final notice = profileSwitchFailureNotice(
        const ChainSelectionStaleException(
          ChainStaleReference.exitProfile,
          'The selected exit profile is no longer available.',
        ),
        rolledBack: true,
      );
      expect(notice, contains('链式出口所选的配置已不存在'));
      expect(notice, contains('重新选择出口配置'));
      expect(notice, isNot(contains('已切回原来的配置')));
    });

    test('switch failure with a stale exit group selects the chain notice', () {
      final notice = profileSwitchFailureNotice(
        'exit "Node B" not found in this profile',
        rolledBack: false,
      );
      expect(notice, contains('链式出口所选的分组或节点已不在出口配置中'));
      expect(notice, contains('重新选择出口'));
    });

    test('switch failure with a stale entry selects the entry chain notice', () {
      final notice = profileSwitchFailureNotice(
        'entry "Node A" is not a directly verifiable node or group in the active profile',
        rolledBack: true,
      );
      expect(notice, contains('链式入口所选的分组或节点已不在当前配置中'));
      expect(notice, contains('重新选择入口'));
      expect(notice, isNot(contains('链式出口')));
    });

    test('switch failure passes the reason through redacted, with a remedy', () {
      final notice = profileSwitchFailureNotice(
        'parse failed for https://example.com/sub?token=secret-token-value',
        rolledBack: true,
      );
      expect(notice, contains('已切回原来的配置'));
      expect(notice, contains('原因'));
      expect(notice, contains('重新导入'));
      // The reason is really interpolated, then redacted: the host
      // survives, the credential does not.
      expect(notice, contains('example.com'));
      expect(notice, isNot(contains('secret-token-value')));
      expect(notice, isNot(contains('token=')));
    });

    test('update failure names the profile, the reason and the remedy', () {
      final notice = profileUpdateFailureNotice(
        'Airport A',
        'dial failed https://example.com/feed?token=secret-token-value',
        automatic: false,
      );
      expect(notice, contains('Airport A'));
      expect(notice, contains('更新失败'));
      expect(notice, contains('订阅链接'));
      expect(notice, isNot(contains('secret-token-value')));
    });

    test('core restart failure appends the remedy to the reason', () {
      final notice = coreRestartFailureNotice(StateError('core gone'));
      expect(notice, contains('core gone'));
      expect(notice, contains('等几秒再试一次'));
      expect(notice, contains('完全退出应用'));
    });

    test('missing rule-set name is extracted from the core error', () {
      expect(missingRuleSetNameOf('not found rule-set: cn'), 'cn');
      expect(
        missingRuleSetNameOf('load failed: not found rule-set: cn_bettbox'),
        'cn_bettbox',
      );
      expect(missingRuleSetNameOf('some other failure'), isNull);
    });

    test('switch failure with a missing rule-set names what to check', () {
      final notice = profileSwitchFailureNotice(
        'not found rule-set: cn',
        rolledBack: true,
      );
      expect(notice, contains('规则集「cn」'));
      expect(notice, contains('rule-providers'));
      expect(notice, contains('fake-ip-filter'));
      expect(notice, contains('nameserver-policy'));
      // The dedicated notice replaces the generic rollback wording.
      expect(notice, isNot(contains('已切回原来的配置')));
    });

    test('service toggle failure with a missing rule-set is dedicated', () {
      final notice = serviceToggleFailureNotice('not found rule-set: cn');
      expect(notice, contains('规则集「cn」'));
      expect(notice, contains('删掉含「cn」的条目'));
    });
  });
}
