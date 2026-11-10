import 'dart:io';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// T81 R-1a regression: group selections used to have two persistent
// stores — the App's Profile.selectedMap and the kernel cachefile
// (profile.store-selected defaults to true in the kernel and the App
// never sent the field). The two could fork: a selection made in an
// external controller was recorded by the kernel cache, then silently
// reverted by the App's map at the next setup (and vice versa for
// groups missing from the map). The general patch must now send
// store-selected: false on every setup, leaving selectedMap as the
// single authority. On the pre-fix code the profile map has no
// store-selected key at all, so the first test fails.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory home;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    home = await Directory.systemTemp.createTemp('angelamihomo_t81_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => home.path,
        );
    await appPath.dataDir.future;
  });

  tearDownAll(() => home.delete(recursive: true));

  const profile = Profile(
    id: 't81-store-selected',
    autoUpdateDuration: Duration(hours: 1),
  );

  test('general patch pins store-selected off', () async {
    final params = await globalState.buildPatchParams(
      patchConfig: const ClashConfig(),
      profile: profile,
    );
    final general = params['general'] as Map<String, dynamic>;
    final profilePatch = general['profile'] as Map<String, dynamic>;
    expect(profilePatch['store-selected'], isFalse);
  });

  test('store-fake-ip still follows the setting next to it', () async {
    final params = await globalState.buildPatchParams(
      patchConfig: const ClashConfig(storeFakeIp: true),
      profile: profile,
    );
    final general = params['general'] as Map<String, dynamic>;
    final profilePatch = general['profile'] as Map<String, dynamic>;
    expect(profilePatch['store-fake-ip'], isTrue);
    expect(profilePatch['store-selected'], isFalse);
  });
}
