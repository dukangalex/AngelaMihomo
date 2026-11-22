import 'dart:io';

import 'package:angelamihomo/common/update_installer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateInstaller.localAssetFileName (T284)', () {
    test('plain asset names pass through unchanged', () {
      expect(
        UpdateInstaller.localAssetFileName(
          'AngelaMihomo-1.19.8-chain.29-android-universal.apk',
        ),
        'AngelaMihomo-1.19.8-chain.29-android-universal.apk',
      );
    });

    test('forward-slash traversal is stripped to the file name', () {
      expect(UpdateInstaller.localAssetFileName('../../evil.apk'), 'evil.apk');
      expect(UpdateInstaller.localAssetFileName('/tmp/x/y.zip'), 'y.zip');
      expect(UpdateInstaller.localAssetFileName('a/b/c/pkg.dmg'), 'pkg.dmg');
    });

    test('backslash traversal is stripped to the file name', () {
      expect(
        UpdateInstaller.localAssetFileName(r'..\..\evil.exe'),
        'evil.exe',
      );
    });

    test('degenerate names fall back to a fixed file name', () {
      expect(UpdateInstaller.localAssetFileName(''), 'update-package');
      expect(UpdateInstaller.localAssetFileName('.'), 'update-package');
      expect(UpdateInstaller.localAssetFileName('..'), 'update-package');
      expect(UpdateInstaller.localAssetFileName('a/b/'), 'update-package');
    });

    test('the joined save path always stays inside the target directory', () {
      const dir = '/tmp/downloads';
      for (final name in [
        '../../evil.apk',
        r'..\..\evil.exe',
        '/etc/passwd',
        'normal.apk',
      ]) {
        final file = File('$dir/${UpdateInstaller.localAssetFileName(name)}');
        expect(file.parent.path, dir, reason: name);
      }
    });
  });
}
