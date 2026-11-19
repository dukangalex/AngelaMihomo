import 'dart:convert';

import 'package:angelamihomo/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _configJsonWithDevice(String device) {
  final json =
      jsonDecode(jsonEncode(Config(themeProps: defaultThemeProps).toJson()))
          as Map<String, Object?>;
  final patch = json['patchClashConfig'] as Map<String, Object?>;
  (patch['tun'] as Map<String, Object?>)['device'] = device;
  return json;
}

void main() {
  group('stored TUN device name is read as-is (T260)', () {
    test('any stored value passes through unchanged', () {
      for (final device in ['Bettbox', 'AngelaMihomo', 'MyTun']) {
        expect(
          Config.compatibleFromJson(
            _configJsonWithDevice(device),
          ).patchClashConfig.tun.device,
          device,
        );
      }
    });
  });
}
