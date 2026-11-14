import 'package:bett_box/common/common.dart';
import 'package:bett_box/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// T121: stock cleanup for the scrapped chain.22 line's seeded duplicate
/// script. The purge must remove exactly that record and its bindings —
/// nothing else, and nothing when there is nothing to remove.
void main() {
  Profile profile(String id, {String? scriptId, bool managed = false}) =>
      Profile(
        id: id,
        autoUpdateDuration: Duration.zero,
      ).copyWith(scriptId: scriptId, managed: managed);

  Config configWith({
    List<Script> scripts = const [],
    List<Profile> profiles = const [],
  }) {
    final base = Config(themeProps: defaultThemeProps);
    return base.copyWith(
      scriptProps: ScriptProps(scripts: scripts),
      profiles: profiles,
    );
  }

  const legacy = Script(
    id: legacyBuiltinScriptId,
    label: 'HiClash 内置脚本',
  );
  const userScript = Script(id: 'user-1', label: '我的脚本');

  test('removes the legacy record and clears only its bindings', () {
    final config = configWith(
      scripts: [legacy, userScript],
      profiles: [
        profile('p1', scriptId: legacyBuiltinScriptId),
        profile('p2', scriptId: 'user-1'),
        profile('p3', managed: true),
        profile('p4'),
      ],
    );
    final purged = purgeLegacyBuiltinScript(config);
    expect(purged, isNotNull);
    expect(purged!.scriptProps.scripts, [userScript]);
    expect(purged.profiles[0].scriptId, isNull);
    expect(purged.profiles[1].scriptId, 'user-1');
    // The surviving managed mechanism's own opt-in is not a binding to
    // the legacy record and must stay exactly as the user left it.
    expect(purged.profiles[2].managed, isTrue);
    expect(purged.profiles[3].scriptId, isNull);
  });

  test('clears dangling bindings even when the record is already gone', () {
    final config = configWith(
      profiles: [profile('p1', scriptId: legacyBuiltinScriptId)],
    );
    final purged = purgeLegacyBuiltinScript(config);
    expect(purged, isNotNull);
    expect(purged!.profiles.single.scriptId, isNull);
  });

  test('returns null for a clean config', () {
    final config = configWith(
      scripts: [userScript],
      profiles: [profile('p1', scriptId: 'user-1'), profile('p2')],
    );
    expect(purgeLegacyBuiltinScript(config), isNull);
    expect(purgeLegacyBuiltinScript(configWith()), isNull);
  });

  test('the bundled entry carries the script name, not the mode name', () {
    expect(bundledScriptLabel, 'HiClash 内置脚本');
    expect(legacyBuiltinScriptId, 'builtin-hiclash');
  });
}
