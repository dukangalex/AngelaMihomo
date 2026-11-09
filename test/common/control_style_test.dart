import 'package:bett_box/common/control_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// T64: the keycap-future control style is retired. A device that
/// had it selected must land on liquid glass — value normalized in
/// the store, no error, no dead option.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a stored keycapFuture value falls back to liquid glass', () async {
    SharedPreferences.setMockInitialValues({
      'control_style.v1': 'keycapFuture',
    });
    final style = await ControlStyleStore.load();
    expect(style, ControlStyle.liquidGlass);
    expect(controlStyleNotifier.value, ControlStyle.liquidGlass);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('control_style.v1'), 'liquidGlass');
  });

  test('a stored liquidGlass value loads unchanged', () async {
    SharedPreferences.setMockInitialValues({
      'control_style.v1': 'liquidGlass',
    });
    expect(await ControlStyleStore.load(), ControlStyle.liquidGlass);
  });

  test('no stored value defaults to liquid glass', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await ControlStyleStore.load(), ControlStyle.liquidGlass);
    expect(controlStyleNotifier.value, ControlStyle.liquidGlass);
  });
}
