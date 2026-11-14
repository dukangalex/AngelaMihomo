import 'dart:convert';

import 'package:bett_box/common/builtin_script.dart';
import 'package:bett_box/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scriptA = Script(id: 'a', label: 'Script A');
  const scriptB = Script(id: 'b', label: 'Script B');
  const props = ScriptProps(currentId: 'a', scripts: [scriptA, scriptB]);

  group('ScriptProps.resolveScript', () {
    test('override off means no script, even with a chosen scriptId', () {
      expect(
        props.resolveScript(useScriptOverride: false, scriptId: 'b'),
        isNull,
      );
      expect(props.resolveScript(useScriptOverride: false), isNull);
    });

    test('override on without a scriptId follows the global script', () {
      expect(props.resolveScript(useScriptOverride: true), scriptA);
    });

    test('override on with a scriptId picks that script', () {
      expect(
        props.resolveScript(useScriptOverride: true, scriptId: 'b'),
        scriptB,
      );
      expect(
        props.resolveScript(useScriptOverride: true, scriptId: 'a'),
        scriptA,
      );
    });

    test('a deleted chosen script falls back to the global script', () {
      expect(
        props.resolveScript(useScriptOverride: true, scriptId: 'gone'),
        scriptA,
      );
    });

    test('no global script and no choice resolves to null', () {
      const empty = ScriptProps(scripts: [scriptA, scriptB]);
      expect(empty.resolveScript(useScriptOverride: true), isNull);
      expect(
        empty.resolveScript(useScriptOverride: true, scriptId: 'b'),
        scriptB,
      );
    });

    test('bundled script sits in the library unbound until chosen', () {
      const builtin = Script(id: BuiltinScript.id, label: 'HiClash 内置脚本');
      const library = ScriptProps(scripts: [builtin]);
      final fresh = Profile.normal(label: 'fresh');
      // Present in the library, but a fresh profile does not resolve it.
      expect(
        library.resolveScript(
          useScriptOverride: fresh.useScriptOverride,
          scriptId: fresh.scriptId,
        ),
        isNull,
      );
      // Only the user's own per-profile choice activates it.
      expect(
        library.resolveScript(
          useScriptOverride: true,
          scriptId: BuiltinScript.id,
        ),
        builtin,
      );
    });
  });

  group('Profile scriptId persistence', () {
    test('scriptId round-trips through JSON and defaults to null', () {
      Profile decode(Profile profile) => Profile.fromJson(
        jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>,
      );
      final profile = Profile.normal(label: 'x').copyWith(scriptId: 'b');
      expect(decode(profile).scriptId, 'b');
      // T95 (revised): fresh profiles start unbound — the bundled
      // HiClash script only applies once the user picks it.
      expect(Profile.normal(label: 'y').scriptId, isNull);
      expect(Profile.normal(label: 'y').useScriptOverride, isFalse);
      final legacyJson =
          jsonDecode(jsonEncode(Profile.normal(label: 'z').toJson()))
              as Map<String, dynamic>
            ..remove('scriptId')
            ..remove('useScriptOverride');
      final legacy = Profile.fromJson(legacyJson);
      expect(legacy.scriptId, isNull);
      expect(legacy.useScriptOverride, isFalse);
    });
  });
}
