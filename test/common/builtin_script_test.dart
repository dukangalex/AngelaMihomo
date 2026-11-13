import 'package:bett_box/common/builtin_script.dart';
import 'package:bett_box/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveBuiltinSeedAction', () {
    test('creates when missing', () {
      expect(
        resolveBuiltinSeedAction(
          existingDigest: null,
          factoryDigest: null,
          bundledDigest: 'b1',
        ),
        BuiltinSeedAction.create,
      );
    });

    test('keeps an already-current copy', () {
      expect(
        resolveBuiltinSeedAction(
          existingDigest: 'b1',
          factoryDigest: 'b1',
          bundledDigest: 'b1',
        ),
        BuiltinSeedAction.keep,
      );
    });

    test('refreshes an untouched copy when the bundle moved on', () {
      expect(
        resolveBuiltinSeedAction(
          existingDigest: 'b1',
          factoryDigest: 'b1',
          bundledDigest: 'b2',
        ),
        BuiltinSeedAction.refresh,
      );
    });

    test('keeps a user-edited copy even when the bundle moved on', () {
      expect(
        resolveBuiltinSeedAction(
          existingDigest: 'user-edit',
          factoryDigest: 'b1',
          bundledDigest: 'b2',
        ),
        BuiltinSeedAction.keep,
      );
      expect(
        builtinUpdateAvailable(
          existingDigest: 'user-edit',
          factoryDigest: 'b1',
          bundledDigest: 'b2',
        ),
        isTrue,
      );
    });
  });

  group('profileNeedsBuiltinBinding', () {
    Profile profile({
      String? scriptId,
      bool useScriptOverride = false,
      ProfileBundle? bundle,
    }) => Profile(
      id: 'p1',
      label: 'p',
      url: '',
      autoUpdateDuration: const Duration(hours: 6),
      scriptId: scriptId,
      useScriptOverride: useScriptOverride,
      bundle: bundle,
    );

    test('binds untouched stock profiles only', () {
      expect(profileNeedsBuiltinBinding(profile()), isTrue);
      expect(
        profileNeedsBuiltinBinding(profile(scriptId: 'other')),
        isFalse,
      );
      expect(
        profileNeedsBuiltinBinding(profile(useScriptOverride: true)),
        isFalse,
      );
      expect(
        profileNeedsBuiltinBinding(
          profile(bundle: const ProfileBundle(members: [])),
        ),
        isFalse,
      );
    });
  });

  test('host protocol declaration is read from the script head', () {
    expect(
      scriptDeclaresAngelaHost(
        'const Compatible_With_AngelaMihomo = { ruleOptionsEnable: true };\nfunction main(c) { return c }',
      ),
      isTrue,
    );
    expect(
      scriptDeclaresAngelaHost(
        'const Compatible_With_Mihomo = {};\nfunction main(c) { return c }',
      ),
      isFalse,
    );
  });
}
