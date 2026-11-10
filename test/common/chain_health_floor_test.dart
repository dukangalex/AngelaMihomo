import 'package:bett_box/common/profile_chain.dart';
import 'package:flutter_test/flutter_test.dart';

// T81 C-4 regression: the bridge raises chain-carrying groups'
// health-check parameters to sticky floors at setup (interval ≥ 180,
// tolerance ≥ 200, timeout ≥ 5000), and used to do so silently — a
// user who set interval 30 in the group editor saw the override saved
// while the core actually probed every 180 s. The editor now echoes
// the effective value via chainHealthFloorForGroup/chainFlooredValue;
// these tests pin which groups the floor applies to and when a value
// counts as raised. If the applicability rules drift from
// patchChainPolicy, the echo lies — fail here first.
void main() {
  ProfileChain chain({
    bool enabled = true,
    String entry = 'EntryGroup',
    ChainTargetKind entryKind = ChainTargetKind.group,
    String landing = 'ExitGroup',
    ChainTargetKind landingKind = ChainTargetKind.group,
    String landingProfileId = '',
  }) => ProfileChain(
    enabled: enabled,
    entry: entry,
    entryKind: entryKind,
    landing: landing,
    landingKind: landingKind,
    landingProfileId: landingProfileId,
  );

  group('chainHealthFloorForGroup', () {
    test('entry group of an enabled chain is floored', () {
      final floor = chainHealthFloorForGroup(
        chain(),
        currentProfileId: 'p1',
        groupName: 'EntryGroup',
      );
      expect(floor, chainHopHealthFloor);
      expect(floor!.interval, 180);
      expect(floor.tolerance, 200);
      expect(floor.timeout, 5000);
    });

    test('same-profile exit group is floored', () {
      final floor = chainHealthFloorForGroup(
        chain(),
        currentProfileId: 'p1',
        groupName: 'ExitGroup',
      );
      expect(floor, chainHopHealthFloor);
    });

    test('external exit group is not floored in the importing profile', () {
      final floor = chainHealthFloorForGroup(
        chain(landingProfileId: 'other'),
        currentProfileId: 'p1',
        groupName: 'ExitGroup',
      );
      expect(floor, isNull);
    });

    test('disabled chain floors nothing', () {
      expect(
        chainHealthFloorForGroup(
          chain(enabled: false),
          currentProfileId: 'p1',
          groupName: 'EntryGroup',
        ),
        isNull,
      );
    });

    test('proxy-kind targets and unrelated groups are not floored', () {
      final c = chain(entryKind: ChainTargetKind.proxy);
      expect(
        chainHealthFloorForGroup(
          c,
          currentProfileId: 'p1',
          groupName: 'EntryGroup',
        ),
        isNull,
      );
      expect(
        chainHealthFloorForGroup(
          chain(),
          currentProfileId: 'p1',
          groupName: 'SomeOtherGroup',
        ),
        isNull,
      );
    });
  });

  group('chainFlooredValue', () {
    test('value below the floor is raised to the floor', () {
      expect(chainFlooredValue(30, 180), 180);
      expect(chainFlooredValue(100, 200), 200);
      expect(chainFlooredValue(3000, 5000), 5000);
    });

    test('value at or above the floor is left alone', () {
      expect(chainFlooredValue(180, 180), isNull);
      expect(chainFlooredValue(600, 180), isNull);
    });

    test('absent value is left alone', () {
      expect(chainFlooredValue(null, 180), isNull);
    });
  });
}
