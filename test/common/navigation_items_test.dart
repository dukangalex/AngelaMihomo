import 'package:bett_box/common/navigation.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:flutter_test/flutter_test.dart';

/// T122: the AI patrol page is gone. The navigation table must contain
/// exactly the surviving pages — no patrol entry anywhere, and the four
/// primary pages (dashboard / proxies / profiles / tools) intact.
void main() {
  test('navigation items are exactly the surviving pages', () {
    final labels = navigation
        .getItems(hasProxies: true)
        .map((item) => item.label)
        .toSet();
    expect(labels, {
      PageLabel.dashboard,
      PageLabel.proxies,
      PageLabel.profiles,
      PageLabel.tools,
      PageLabel.logs,
      PageLabel.resources,
      PageLabel.script,
      PageLabel.toolbox,
      PageLabel.connections,
    });
  });
}
