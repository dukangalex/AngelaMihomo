import 'dart:io';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// T79 regression: buildPatchParams used to always send
// 'lan-allowed-ips': [] / 'lan-disallowed-ips': [] when the user had
// not configured LAN lists. The explicit empty list overwrote the
// kernel's allow-all default in applyPatch, and the vendored listener
// gate then dropped every inbound connection — subscription updates
// through the mixed port died in CONNECT whenever the core was up.
// Unset lists must be sent as null ("do not override"), exactly like
// skip-auth-prefixes; on the pre-fix code the first test fails
// because the values are [] instead of null.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory home;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    home = await Directory.systemTemp.createTemp('angelamihomo_t79_');
    // AppPath resolves its directories through path_provider at
    // construction time; answer every call with the temp home (same
    // pattern as profile_save_test).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => home.path,
        );
    // AppPath completes dataDir itself from the mocked path_provider
    // answer; just wait for it instead of completing it here (a manual
    // complete races the constructor's own and throws).
    await appPath.dataDir.future;
  });

  tearDownAll(() => home.delete(recursive: true));

  const profile = Profile(
    id: 't79-lan',
    autoUpdateDuration: Duration(hours: 1),
  );

  test('unset lan lists are sent as null in the general patch', () async {
    final params = await globalState.buildPatchParams(
      patchConfig: const ClashConfig(),
      profile: profile,
    );
    final general = params['general'] as Map<String, dynamic>;
    expect(general['lan-allowed-ips'], isNull);
    expect(general['lan-disallowed-ips'], isNull);
  });

  test('configured lan lists are sent as-is', () async {
    final params = await globalState.buildPatchParams(
      patchConfig: const ClashConfig(
        lanAllowedIps: ['192.168.0.0/16'],
        lanDisallowedIps: ['192.168.9.0/24'],
      ),
      profile: profile,
    );
    final general = params['general'] as Map<String, dynamic>;
    expect(general['lan-allowed-ips'], ['192.168.0.0/16']);
    expect(general['lan-disallowed-ips'], ['192.168.9.0/24']);
  });
}
