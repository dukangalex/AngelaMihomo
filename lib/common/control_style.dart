import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Control style choice (T62): the app's controls come in two
/// switchable skins — the liquid glass from T38 (default) and the
/// futuristic keycap style the user approved from the sample.
/// Switching is instant and app-wide via [controlStyleNotifier].
enum ControlStyle { liquidGlass, keycapFuture }

final controlStyleNotifier = ValueNotifier<ControlStyle>(
  ControlStyle.liquidGlass,
);

class ControlStyleStore {
  static const _key = 'control_style.v1';

  static Future<ControlStyle> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    final style = ControlStyle.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => ControlStyle.liquidGlass,
    );
    controlStyleNotifier.value = style;
    return style;
  }

  static Future<void> save(ControlStyle style) async {
    controlStyleNotifier.value = style;
    await (await SharedPreferences.getInstance()).setString(_key, style.name);
  }
}
