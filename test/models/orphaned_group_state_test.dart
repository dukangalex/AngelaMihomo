import 'package:bett_box/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

// T81 S-5 regression: groupOverrides and selectedMap are keyed by
// group name; a subscription-side rename (or a hand edit in the
// full-text editor) used to orphan the stored state silently — the
// override and the selection simply stopped applying. The controller
// now warns with the names this helper computes. If the helper stops
// flagging true orphans (or starts flagging living groups), the
// warning either goes silent again or cries wolf.
void main() {
  Profile profile({
    Map<String, ProxyGroupOverride> overrides = const {},
    SelectedMap selected = const {},
  }) => Profile(
    id: 'p1',
    autoUpdateDuration: const Duration(hours: 24),
    groupOverrides: overrides,
    selectedMap: selected,
  );

  test('override and selection on a vanished group are flagged', () {
    final p = profile(
      overrides: const {
        'OldName': ProxyGroupOverride(interval: 60),
        'Alive': ProxyGroupOverride(timeout: 3000),
      },
      selected: const {'OldName': 'node-a', 'Alive': 'node-b'},
    );
    expect(orphanedGroupStateNames(p, {'Alive', 'NewName'}), ['OldName']);
  });

  test('no orphans when every stored name still exists', () {
    final p = profile(
      overrides: const {'Alive': ProxyGroupOverride(interval: 60)},
      selected: const {'Alive': 'node-a'},
    );
    expect(orphanedGroupStateNames(p, {'Alive'}), isEmpty);
  });

  test('GLOBAL is never an orphan (bridge-synthesized)', () {
    final p = profile(selected: const {'GLOBAL': 'Alive'});
    expect(orphanedGroupStateNames(p, {'Alive'}), isEmpty);
  });

  test('empty state has no orphans', () {
    expect(orphanedGroupStateNames(profile(), {'Alive'}), isEmpty);
  });

  test('multiple orphans come back sorted, deduplicated', () {
    final p = profile(
      overrides: const {
        'Zeta': ProxyGroupOverride(interval: 60),
        'Alpha': ProxyGroupOverride(interval: 90),
      },
      selected: const {'Zeta': 'node-a', 'Mid': 'node-b'},
    );
    expect(orphanedGroupStateNames(p, <String>{}), ['Alpha', 'Mid', 'Zeta']);
  });
}
