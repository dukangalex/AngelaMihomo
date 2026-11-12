import 'dart:convert';

import 'package:bett_box/models/config.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('配色存量降级（T102 砍配色方案后）', () {
    test('存量自定义配色键被安全忽略，其余主题设置原样保留', () {
      final json = jsonDecode(
        jsonEncode({
          'themeProps': {
            'primaryColor': 0xFF123456,
            'primaryColors': [0xFF1E293B, 0xFF123456],
            'schemeVariant': 'expressive',
            'themeMode': 'dark',
            'pureBlack': true,
          },
        }),
      ) as Map<String, Object?>;
      final config = Config.compatibleFromJson(json);
      expect(config.themeProps.themeMode, ThemeMode.dark);
      expect(config.themeProps.pureBlack, isTrue);
    });

    test('默认主题配置往返稳定且不再写出配色键', () {
      final json =
          jsonDecode(jsonEncode(Config(themeProps: ThemeProps()).toJson()))
              as Map<String, Object?>;
      final restored = Config.compatibleFromJson(json);
      expect(restored.themeProps, ThemeProps());
      expect(
        (json['themeProps'] as Map<String, Object?>).keys,
        isNot(anyOf(contains('primaryColor'), contains('primaryColors'))),
      );
    });
  });
}
