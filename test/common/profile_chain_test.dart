import 'package:angelamihomo/common/profile_chain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const entryTargets = {'proxy\u0000Entry', 'group\u0000Entry group'};
  const landingTargets = {'proxy\u0000Exit', 'group\u0000Exit group'};
  const bothTargets = {...entryTargets, ...landingTargets};

  test('disabled choices can be prepared before enabling', () {
    expect(
      ProfileChain().selectionIssue(
        currentProfileId: 'p',
        entryTargets: entryTargets,
        landingTargetsByProfile: {'other': landingTargets},
      ),
      isNull,
    );
    expect(
      ProfileChain(entry: 'old').selectionIssue(
        currentProfileId: 'p',
        entryTargets: entryTargets,
        landingTargetsByProfile: {'other': landingTargets},
      ),
      isNull,
    );
  });

  test('enabled chain accepts proxy and group selections', () {
    final chain = ProfileChain(
      enabled: true,
      entry: 'Entry group',
      entryKind: ChainTargetKind.group,
      landing: 'Exit group',
      landingKind: ChainTargetKind.group,
      landingProfileId: 'other',
    );
    expect(
      chain.selectionIssue(
        currentProfileId: 'p',
        entryTargets: entryTargets,
        landingTargetsByProfile: {'other': landingTargets},
      ),
      isNull,
    );
  });

  test('entry and exit must be complete, available and distinct', () {
    expect(
      ProfileChain(enabled: true).selectionIssue(
        currentProfileId: 'p',
        entryTargets: entryTargets,
        landingTargetsByProfile: {'other': landingTargets},
      ),
      ProfileChainIssue.incomplete,
    );
    expect(
      ProfileChain(
        enabled: true,
        entry: 'Entry',
        landing: 'Entry',
      ).selectionIssue(
        currentProfileId: 'p',
        entryTargets: entryTargets,
        landingTargetsByProfile: {'other': landingTargets},
      ),
      ProfileChainIssue.otherProfileRequired,
    );
    expect(
      ProfileChain(
        enabled: true,
        entry: 'Entry group',
        entryKind: ChainTargetKind.group,
        landing: 'Exit group',
        landingKind: ChainTargetKind.group,
        landingProfileId: 'other',
      ).selectionIssue(
        currentProfileId: 'p',
        entryTargets: entryTargets,
        landingTargetsByProfile: {'other': const {'proxy\u0000Exit'}},
      ),
      ProfileChainIssue.unavailable,
    );
    expect(
      ProfileChain(
        enabled: true,
        entry: 'Entry group',
        entryKind: ChainTargetKind.group,
        landing: 'Entry group',
        landingKind: ChainTargetKind.group,
      ).selectionIssue(
        currentProfileId: 'p',
        entryTargets: entryTargets,
        landingTargetsByProfile: {'other': bothTargets},
      ),
      ProfileChainIssue.otherProfileRequired,
    );
    expect(
      ProfileChain(
        enabled: true,
        entry: 'Entry group',
        entryKind: ChainTargetKind.group,
        landing: 'Entry group',
        landingKind: ChainTargetKind.group,
        landingProfileId: 'other',
      ).selectionIssue(
        currentProfileId: 'p',
        entryTargets: entryTargets,
        landingTargetsByProfile: {'other': bothTargets},
      ),
      isNull,
    );
  });

  test('legacy JSON reads as a same-profile proxy selection', () {
    final legacy = ProfileChain.fromJson({
      'enabled': true,
      'entry': 'Entry',
      'landing': 'Exit',
    });
    expect(legacy.entryKind, ChainTargetKind.proxy);
    expect(legacy.landingKind, ChainTargetKind.proxy);
    expect(legacy.resolvedLandingProfileId('p'), 'p');
    expect(ProfileChain.fromJson(legacy.toJson()).toJson(), legacy.toJson());
  });

  test('editing candidate does not mutate last saved choice', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ProfileChainStore.instance;
    await store.ensureLoaded();
    final original = ProfileChain(
      enabled: true,
      entry: 'Entry',
      landing: 'Exit',
      landingProfileId: 'other',
    );
    store.byProfile['p'] = original;
    await store.save();
    final candidate = original.copyWith(landing: 'Entry');
    expect(
      candidate.selectionIssue(
        currentProfileId: 'p',
        entryTargets: entryTargets,
        landingTargetsByProfile: {'other': landingTargets},
      ),
      ProfileChainIssue.unavailable,
    );
    expect(store.of('p').landing, 'Exit');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile_chain_v1'), contains('"landing":"Exit"'));
    expect(
      ProfileChain.fromJson(original.toJson()).toJson(),
      original.toJson(),
    );
  });
  test('enabled chain requires exit from another profile', () {
    final chain = ProfileChain(
      enabled: true,
      entry: 'Entry',
      landing: 'Exit',
      landingProfileId: '',
    );
    expect(
      chain.selectionIssue(
        currentProfileId: 'active',
        entryTargets: {chainTargetKey(ChainTargetKind.proxy, 'Entry')},
        landingTargetsByProfile: {'p': {chainTargetKey(ChainTargetKind.proxy, 'Exit')}},
      ),
      ProfileChainIssue.otherProfileRequired,
    );
  });

  multiExitMain();
}

/// T303 storage shape, T310 semantics: the landings list still parses
/// and round-trips, but only the first exit is in effect — validation
/// and generation ignore any stored extras.
void multiExitMain() {
  const entryTargets = {'proxy\u0000Entry'};
  final targetsByProfile = <String, Set<String>>{
    'other': {'group\u0000Exit group'},
    'third': {'proxy\u0000Solo exit'},
  };

  ProfileChain multi() => ProfileChain(
    enabled: true,
    entry: 'Entry',
    landings: [
      ChainLanding(
        profileId: 'other',
        kind: ChainTargetKind.group,
        name: 'Exit group',
      ),
      ChainLanding(
        profileId: 'third',
        kind: ChainTargetKind.proxy,
        name: 'Solo exit',
      ),
    ],
  );

  test('stored multi-exit list validates on its first exit', () {
    expect(
      multi().selectionIssue(
        currentProfileId: 'p',
        entryTargets: entryTargets,
        landingTargetsByProfile: targetsByProfile,
      ),
      isNull,
    );
  });

  test('only the first exit decides availability (T310)', () {
    final staleSecond = Map<String, Set<String>>.of(targetsByProfile)
      ..['third'] = {'proxy\u0000Renamed'};
    expect(
      multi().selectionIssue(
        currentProfileId: 'p',
        entryTargets: entryTargets,
        landingTargetsByProfile: staleSecond,
      ),
      isNull,
    );
    final staleFirst = Map<String, Set<String>>.of(targetsByProfile)
      ..['other'] = {'group\u0000Renamed'};
    expect(
      multi().selectionIssue(
        currentProfileId: 'p',
        entryTargets: entryTargets,
        landingTargetsByProfile: staleFirst,
      ),
      ProfileChainIssue.unavailable,
    );
  });

  test('an extra exit pointing at the own profile is ignored (T310)', () {
    final chain = multi();
    chain.landings.add(ChainLanding(profileId: '', name: 'Local'));
    expect(
      chain.selectionIssue(
        currentProfileId: 'p',
        entryTargets: entryTargets,
        landingTargetsByProfile: targetsByProfile,
      ),
      isNull,
    );
    final firstLocal = ProfileChain(
      enabled: true,
      entry: 'Entry',
      landings: [ChainLanding(profileId: '', name: 'Local')],
    );
    expect(
      firstLocal.selectionIssue(
        currentProfileId: 'p',
        entryTargets: entryTargets,
        landingTargetsByProfile: targetsByProfile,
      ),
      ProfileChainIssue.otherProfileRequired,
    );
  });

  test('landings JSON round-trips and mirrors the first exit', () {
    final json = multi().toJson();
    expect(json['landing'], 'Exit group');
    expect(json['landing-profile-id'], 'other');
    expect((json['landings'] as List).length, 2);
    expect(ProfileChain.fromJson(json).toJson(), json);
  });

  test('legacy single-exit JSON migrates to a one-element list', () {
    final migrated = ProfileChain.fromJson({
      'enabled': true,
      'entry': 'Entry',
      'landing': 'Exit',
      'landing-kind': 'group',
      'landing-profile-id': 'other',
    });
    expect(migrated.landings.length, 1);
    expect(migrated.landings.single.profileId, 'other');
    expect(migrated.landings.single.kind, ChainTargetKind.group);
    expect(migrated.landing, 'Exit');
  });
}
