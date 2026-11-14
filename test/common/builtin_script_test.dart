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

  group('no default binding (T95 revised default)', () {
    test('a fresh profile starts with the bundled script unbound', () {
      final profile = Profile.normal(label: 'fresh');
      expect(profile.useScriptOverride, isFalse);
      expect(profile.scriptId, isNull);
    });

    test('a stock profile is never auto-bound, whatever its shape', () {
      // Seeding maintains only the library copy; profiles keep whatever
      // script choice they already have (including none).
      final untouched = Profile.normal(label: 'stock');
      expect(untouched.scriptId, isNull);
      final chosen = untouched.copyWith(
        useScriptOverride: true,
        scriptId: 'other',
      );
      expect(chosen.scriptId, 'other');
      final bundle = untouched.copyWith(
        bundle: const ProfileBundle(members: []),
      );
      expect(bundle.scriptId, isNull);
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
