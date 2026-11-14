import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/views/dashboard/widgets/node_health.dart';
import 'package:flutter_test/flutter_test.dart';

Group _group(String name, {String? now, String? testUrl}) {
  return Group(type: GroupType.Selector, name: name, now: now, testUrl: testUrl);
}

void main() {
  group('resolveNodeHealth', () {
    test('measured good delay is available', () {
      expect(
        resolveNodeHealth(coreRunning: true, delay: 123),
        NodeHealth.available,
      );
    });

    test('measured failure is unavailable', () {
      expect(
        resolveNodeHealth(coreRunning: true, delay: -1),
        NodeHealth.unavailable,
      );
    });

    test('no measurement yet is unknown', () {
      expect(
        resolveNodeHealth(coreRunning: true, delay: null),
        NodeHealth.unknown,
      );
      expect(
        resolveNodeHealth(coreRunning: true, delay: 0),
        NodeHealth.unknown,
      );
    });

    test('stopped core is unknown even with a stale delay', () {
      expect(
        resolveNodeHealth(coreRunning: false, delay: 123),
        NodeHealth.unknown,
      );
      expect(
        resolveNodeHealth(coreRunning: false, delay: -1),
        NodeHealth.unknown,
      );
    });
  });

  group('resolveCurrentExitNode', () {
    test('resolves the GLOBAL pick', () {
      final exit = resolveCurrentExitNode(
        groups: [_group('GLOBAL', testUrl: 'https://example.com')],
        selectedMap: {'GLOBAL': 'NodeA'},
      );
      expect(exit?.name, 'NodeA');
      expect(exit?.testUrl, 'https://example.com');
    });

    test('walks through nested groups to the leaf', () {
      final exit = resolveCurrentExitNode(
        groups: [
          _group('GLOBAL'),
          _group('Auto', now: 'LeafB', testUrl: 'https://auto.example.com'),
        ],
        selectedMap: {'GLOBAL': 'Auto'},
      );
      expect(exit?.name, 'LeafB');
      expect(exit?.testUrl, 'https://auto.example.com');
    });

    test('DIRECT pick and missing GLOBAL have no exit node', () {
      expect(
        resolveCurrentExitNode(
          groups: [_group('GLOBAL')],
          selectedMap: {'GLOBAL': 'DIRECT'},
        ),
        isNull,
      );
      expect(
        resolveCurrentExitNode(groups: [_group('Other')], selectedMap: {}),
        isNull,
      );
    });
  });
}
