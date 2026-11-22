import 'dart:convert';
import 'dart:io';

import 'package:angelamihomo/common/helper_auth.dart';
import 'package:angelamihomo/common/path.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// AM-02/T278: on POSIX platforms the persisted helper auth key is only
// base64-encoded, so its file mode is the access control. New key files
// must be 0600, an app-created parent directory 0700, and pre-existing
// looser key files must be tightened when read back.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final isPosix = Platform.isLinux || Platform.isMacOS;

  group('helper auth key file permissions', () {
    late Directory home;
    late String supportPath;
    late File keyFile;

    setUpAll(() async {
      home = await Directory.systemTemp.createTemp('angelamihomo_authkey_');
      supportPath = p.join(home.path, 'support');
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => supportPath);
      keyFile = File(await appPath.helperAuthKeyPath);
    });

    tearDownAll(() async {
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await home.delete(recursive: true);
    });

    test(
      'newly persisted key file is 0600 and its new parent directory 0700',
      () async {
        await HelperAuthManager.ensureAuthKey();

        expect(await keyFile.exists(), isTrue);
        expect((await keyFile.stat()).mode & 0x1FF, 0x180);
        expect((await keyFile.parent.stat()).mode & 0x1FF, 0x1C0);
      },
      skip: !isPosix,
    );

    test('a pre-existing looser key file is tightened to 0600 on read', () async {
      await HelperAuthManager.clearAuthKey();

      const plantedKey =
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      await keyFile.writeAsString(base64Encode(utf8.encode(plantedKey)));
      final loosen = await Process.run('chmod', ['644', keyFile.path]);
      expect(loosen.exitCode, 0);
      expect((await keyFile.stat()).mode & 0x1FF, 0x1A4);

      await HelperAuthManager.ensureAuthKey();

      expect(HelperAuthManager.getAuthKey(), plantedKey);
      expect((await keyFile.stat()).mode & 0x1FF, 0x180);
    }, skip: !isPosix);
  });
}
