import 'package:bett_box/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

// T75 第 0 步回归：内核字段为 exclude-filter（GroupCommonOption），
// Dart 模型曾误写为 expected-filter，导致带 exclude-filter 的组配置
// 在 App 解析→再生成内核配置时该过滤被静默丢弃。
void main() {
  test('ProxyGroup 解析 exclude-filter 并回写同名字段', () {
    final group = ProxyGroup.fromJson(const {
      'name': 'Auto',
      'type': 'url-test',
      'use': ['provider1'],
      'filter': 'HK|SG',
      'exclude-filter': '过期|失效',
    });
    expect(group.excludeFilter, '过期|失效');
    final out = group.toJson();
    expect(out['exclude-filter'], '过期|失效');
    expect(out.containsKey('expected-filter'), isFalse);
  });
}
