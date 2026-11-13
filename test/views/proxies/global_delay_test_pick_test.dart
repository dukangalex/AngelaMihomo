import 'package:bett_box/views/proxies/common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pickFastestAvailableProxy (T113 联动优选)', () {
    test('选延迟最低的正值节点', () {
      expect(
        pickFastestAvailableProxy({'node-a': 320, 'node-b': 85, 'node-c': 150}),
        'node-b',
      );
    });

    test('全部失败时返回 null（调用方据此保留原选择）', () {
      expect(pickFastestAvailableProxy({'node-a': -1, 'node-b': -1}), isNull);
    });

    test('无效值一律跳过：未测 null、测试中 0、失败负数', () {
      expect(
        pickFastestAvailableProxy({
          'node-a': null,
          'node-b': 0,
          'node-c': -1,
          'node-d': 210,
        }),
        'node-d',
      );
    });

    test('候选为空时返回 null', () {
      expect(pickFastestAvailableProxy({}), isNull);
    });
  });
}
