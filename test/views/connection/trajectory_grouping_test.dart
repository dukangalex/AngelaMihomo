import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/views/connection/trajectory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T334 batch 4: the trajectory grouping contract — groups appear
/// in first-appearance order, items keep their input order inside
/// each group, and flows the core did not attribute land in the
/// empty-process bucket instead of being dropped or invented.
TrackerInfo _info(String id, String process) {
  return TrackerInfo(
    id: id,
    start: DateTime(2026),
    metadata: Metadata(process: process),
    chains: const [],
    rule: '',
    rulePayload: '',
  );
}

void main() {
  test('groups keep first-appearance order and in-group order', () {
    final items = [
      _info('1', 'WeChat'),
      _info('2', 'Chrome'),
      _info('3', 'WeChat'),
      _info('4', 'Telegram'),
      _info('5', 'Chrome'),
    ];
    final groups = groupConnectionsByProcess(
      items,
      (info) => info.metadata.process,
    );
    expect(groups.map((g) => g.process), ['WeChat', 'Chrome', 'Telegram']);
    expect(groups[0].items.map((e) => e.id), ['1', '3']);
    expect(groups[1].items.map((e) => e.id), ['2', '5']);
    expect(groups[2].items.map((e) => e.id), ['4']);
  });

  test('unattributed flows form the empty-process group', () {
    final items = [_info('1', ''), _info('2', 'Chrome'), _info('3', '')];
    final groups = groupConnectionsByProcess(
      items,
      (info) => info.metadata.process,
    );
    expect(groups.map((g) => g.process), ['', 'Chrome']);
    expect(groups[0].items.map((e) => e.id), ['1', '3']);
  });

  test('empty input yields no groups', () {
    expect(
      groupConnectionsByProcess(<TrackerInfo>[], (info) => info.metadata.process),
      isEmpty,
    );
  });

  test('rail painter repaints only when its inputs change', () {
    const a = TrajectoryRailPainter(
      lineColor: Colors.white,
      nodeColor: Colors.teal,
    );
    const b = TrajectoryRailPainter(
      lineColor: Colors.white,
      nodeColor: Colors.teal,
    );
    const c = TrajectoryRailPainter(lineColor: Colors.white);
    expect(a.shouldRepaint(b), isFalse);
    expect(a.shouldRepaint(c), isTrue);
  });
}
