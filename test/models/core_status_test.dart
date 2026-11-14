import 'package:bett_box/models/core.dart';
import 'package:flutter_test/flutter_test.dart';

/// T128: the core status payload carries the core's self-reported
/// version (stamped into the core at build time); the About page shows
/// it next to the app version instead of any hardcoded string.
void main() {
  test('CoreStatus 解析核心自报版本', () {
    final status = CoreStatus.fromJson(const {
      'physical': 1024,
      'version': '1.19.34',
    });
    expect(status.version, '1.19.34');
  });

  test('旧核心无 version 字段时默认为空', () {
    final status = CoreStatus.fromJson(const {'physical': 1024});
    expect(status.version, '');
  });
}
