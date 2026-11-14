import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T113 翻转（2026-11-14 用户定版）：全局测速只测不选。
///
/// 原「测完自动优选」断言整件撤销，改为守卫：全量测速的执行路径
/// 不得写任何分组的当前选择——选择只能来自用户手动操作。
/// runGlobalDelayTest 依赖运行中的核心与全局控制器，无法在单测里
/// 端到端驱动，故按本仓守卫单测先例，直接对其源码区域做断言：
/// 区域内出现任何选择写入 API 即失败，迫使改动者人工复核。
void main() {
  final commonSource = File(
    'lib/views/proxies/common.dart',
  ).readAsStringSync();
  final detectionSource = File(
    'lib/views/dashboard/widgets/network_detection.dart',
  ).readAsStringSync();

  String regionOf(String source, String startMarker, String endMarker) {
    final start = source.indexOf(startMarker);
    expect(start, isNonNegative, reason: '未找到起始标记 $startMarker');
    final end = source.indexOf(endMarker, start);
    expect(end, isNonNegative, reason: '未找到结束标记 $endMarker');
    return source.substring(start, end);
  }

  String stripComments(String region) {
    return region
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('//'))
        .join('\n');
  }

  final runRegion = stripComments(
    regionOf(
      commonSource,
      'Future<GlobalDelayTestResult> runGlobalDelayTest(',
      '\ndouble getScrollToSelectedOffset(',
    ),
  );

  group('全量测速后各组选择不变 (T113 只测不选)', () {
    test('测速路径不写当前选择映射', () {
      expect(runRegion.contains('updateCurrentSelectedMap'), isFalse);
      expect(runRegion.contains('selectedMap'), isFalse);
    });

    test('测速路径不调用核心换节点', () {
      expect(runRegion.contains('changeProxy'), isFalse);
      expect(runRegion.contains('ForceSet'), isFalse);
    });

    test('自动优选函数已整件移除', () {
      expect(commonSource.contains('pickFastestAvailableProxy'), isFalse);
      expect(detectionSource.contains('pickFastestAvailableProxy'), isFalse);
    });

    test('结果契约只剩测量与可用计数（展示用）', () {
      final resultClass = regionOf(
        commonSource,
        'class GlobalDelayTestResult',
        '/// T113: global delay test',
      );
      expect(resultClass.contains('optimizedSelections'), isFalse);
      expect(resultClass.contains('noAvailableGroups'), isFalse);
      expect(resultClass.contains('totalNodes'), isTrue);
      expect(resultClass.contains('availableNodes'), isTrue);
    });

    test('测速与进度/计数路径保留', () {
      expect(runRegion.contains('delayTest('), isTrue);
      expect(runRegion.contains('onProgress'), isTrue);
      expect(runRegion.contains('availableNodes'), isTrue);
    });
  });
}
