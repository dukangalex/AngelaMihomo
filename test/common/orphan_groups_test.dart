import 'package:bett_box/common/orphan_groups.dart';
import 'package:flutter_test/flutter_test.dart';

// T111 E-04: stored group state whose group vanished is detected
// (and kept); live groups never count as orphans.
void main() {
  test('returns stored keys missing from the live set', () {
    expect(
      orphanedGroupNames(
        storedKeys: ['A', 'B', 'C'],
        liveGroupNames: {'A', 'C', 'D'},
      ),
      {'B'},
    );
  });

  test('empty when everything is live', () {
    expect(
      orphanedGroupNames(storedKeys: ['A'], liveGroupNames: {'A'}),
      isEmpty,
    );
    expect(
      orphanedGroupNames(storedKeys: const [], liveGroupNames: const {}),
      isEmpty,
    );
  });
}
