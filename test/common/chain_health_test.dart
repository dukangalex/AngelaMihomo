import 'package:bett_box/common/chain_health.dart';
import 'package:bett_box/common/profile_chain.dart';
import 'package:flutter_test/flutter_test.dart';

/// T152: the profile-card chain health projection. Pure matrix over the
/// same existence facts the assembly consumes — profile list membership
/// plus the entry/landing target sets — and total: stale or malformed
/// data must yield a verdict, never a throw.
void main() {
  const currentId = 'p-current';
  const landingId = 'p-landing';

  Map<String, dynamic> configOf({
    List<String> proxies = const [],
    List<String> groups = const [],
  }) => {
    'proxies': [
      for (final name in proxies) {'name': name, 'type': 'ss'},
    ],
    'proxy-groups': [
      for (final name in groups) {'name': name, 'type': 'select'},
    ],
  };

  ProfileChain chain({
    bool enabled = true,
    String entry = 'EntryGroup',
    ChainTargetKind entryKind = ChainTargetKind.group,
    String landing = 'ExitGroup',
    ChainTargetKind landingKind = ChainTargetKind.group,
    String landingProfileId = landingId,
  }) => ProfileChain(
    enabled: enabled,
    entry: entry,
    entryKind: entryKind,
    landing: landing,
    landingKind: landingKind,
    landingProfileId: landingProfileId,
  );

  ChainCardHealth health(
    ProfileChain candidate, {
    bool landingExists = true,
    Map<String, dynamic>? entryConfig,
    Map<String, dynamic>? landingConfig,
  }) => chainCardHealth(
    chain: candidate,
    currentProfileId: currentId,
    landingProfileExists: landingExists,
    entryTargets: chainTargetKeysOf(
      entryConfig ?? configOf(groups: ['EntryGroup'], proxies: ['node-a']),
    ),
    landingTargets: chainTargetKeysOf(
      landingConfig ?? configOf(groups: ['ExitGroup'], proxies: ['exit-a']),
    ),
  );

  group('chainTargetsOf', () {
    test('extracts proxies and groups as keyed targets', () {
      final targets = chainTargetsOf(
        configOf(proxies: ['a', 'b'], groups: ['G']),
      );
      expect(targets.map((t) => t.key), {
        chainTargetKey(ChainTargetKind.proxy, 'a'),
        chainTargetKey(ChainTargetKind.proxy, 'b'),
        chainTargetKey(ChainTargetKind.group, 'G'),
      });
    });

    test('skips empty and reserved names and dedupes', () {
      final targets = chainTargetsOf({
        'proxies': [
          {'name': ''},
          {'name': 'DIRECT'},
          {'name': 'a'},
          {'name': 'a'},
          {'type': 'ss'},
          'not-a-map',
        ],
        'proxy-groups': [
          {'name': 'a'},
        ],
      });
      // 'a' survives once per kind: proxy and group are distinct keys.
      expect(targets.map((t) => t.key), {
        chainTargetKey(ChainTargetKind.proxy, 'a'),
        chainTargetKey(ChainTargetKind.group, 'a'),
      });
    });

    test('malformed sections yield no targets instead of throwing', () {
      expect(chainTargetsOf({}), isEmpty);
      expect(chainTargetsOf({'proxies': 'nope', 'proxy-groups': 42}), isEmpty);
      expect(chainTargetKeysOf({'proxies': null}), isEmpty);
    });
  });

  group('chainCardHealth', () {
    test('disabled chain is notEnabled regardless of the facts', () {
      expect(
        health(chain(enabled: false), landingExists: false),
        ChainCardHealth.notEnabled,
      );
    });

    test('both ends resolving is healthy (group entry, group exit)', () {
      expect(health(chain()), ChainCardHealth.healthy);
    });

    test('both ends resolving is healthy (node entry, node exit)', () {
      expect(
        health(
          chain(
            entry: 'node-a',
            entryKind: ChainTargetKind.proxy,
            landing: 'exit-a',
            landingKind: ChainTargetKind.proxy,
          ),
        ),
        ChainCardHealth.healthy,
      );
    });

    test('missing exit profile is stale', () {
      expect(health(chain(), landingExists: false), ChainCardHealth.stale);
    });

    test('missing exit group is stale', () {
      expect(
        health(chain(), landingConfig: configOf(groups: ['RenamedGroup'])),
        ChainCardHealth.stale,
      );
    });

    test('missing exit node is stale', () {
      expect(
        health(
          chain(landing: 'exit-a', landingKind: ChainTargetKind.proxy),
          landingConfig: configOf(proxies: ['other-node']),
        ),
        ChainCardHealth.stale,
      );
    });

    test('exit kind mismatch is stale (name exists only as other kind)', () {
      expect(
        health(
          chain(landing: 'exit-a', landingKind: ChainTargetKind.group),
          landingConfig: configOf(proxies: ['exit-a']),
        ),
        ChainCardHealth.stale,
      );
    });

    test('missing entry group is stale', () {
      expect(
        health(chain(), entryConfig: configOf(groups: ['OtherGroup'])),
        ChainCardHealth.stale,
      );
    });

    test('missing entry node is stale', () {
      expect(
        health(
          chain(entry: 'node-a', entryKind: ChainTargetKind.proxy),
          entryConfig: configOf(proxies: ['other-node']),
        ),
        ChainCardHealth.stale,
      );
    });

    test('exit pointing at the own profile is stale', () {
      // Legacy default: empty landing profile id resolves to the owner.
      expect(
        health(chain(landingProfileId: '')),
        ChainCardHealth.stale,
      );
      expect(
        health(chain(landingProfileId: currentId)),
        ChainCardHealth.stale,
      );
    });

    test('incomplete selections are stale', () {
      expect(health(chain(entry: '')), ChainCardHealth.stale);
      expect(health(chain(landing: '')), ChainCardHealth.stale);
      expect(health(chain(entry: '  ')), ChainCardHealth.stale);
    });

    test('stale garbage never throws', () {
      expect(
        chainCardHealth(
          chain: ProfileChain(enabled: true),
          currentProfileId: 'gone',
          landingProfileExists: false,
          entryTargets: const {},
          landingTargets: const {},
        ),
        ChainCardHealth.stale,
      );
    });
  });
}
