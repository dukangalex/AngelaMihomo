import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Control style (T62 → T64). The keycap-future skin was retired by
/// the user's 2026-11-08 visual ruling: liquid glass is the only
/// control style now. The notifier and store stay as the single
/// style source so existing listeners keep working, and a stored
/// 'keycapFuture' value from an older build falls back to liquid
/// glass on load — no error, no dead option left on the books.
enum ControlStyle { liquidGlass }

final controlStyleNotifier = ValueNotifier<ControlStyle>(
  ControlStyle.liquidGlass,
);

class ControlStyleStore {
  static const _key = 'control_style.v1';

  static Future<ControlStyle> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    controlStyleNotifier.value = ControlStyle.liquidGlass;
    if (raw != null && raw != ControlStyle.liquidGlass.name) {
      // Retired value (or garbage): normalize the stored copy so the
      // fallback happens exactly once, silently.
      await prefs.setString(_key, ControlStyle.liquidGlass.name);
    }
    return ControlStyle.liquidGlass;
  }

  static Future<void> save(ControlStyle style) async {
    controlStyleNotifier.value = style;
    await (await SharedPreferences.getInstance()).setString(_key, style.name);
  }
}
