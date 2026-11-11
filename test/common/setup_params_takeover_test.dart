import 'dart:io';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// T81 batch 3 (P-2/R-2/R-4) regression: buildPatchParams after the
// section takeover.
// - ntp / sniffer / experimental are always sent (previously null
//   unless the matching override gate was on, which let the
//   subscription section win instead).
// - No 'override-dns' key remains in the params.
// - external-ui-url/name and geodata-loader/mode come from the model
//   (previously hardcoded literals that shadowed the model fields).
// On the pre-batch code the gate-off cases send null sections and the
// model-value cases return the hardcoded literals, so these fail.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory home;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    home = await Directory.systemTemp.createTemp('angelamihomo_t81b3_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => home.path,
        );
    await appPath.dataDir.future;
  });

  tearDownAll(() => home.delete(recursive: true));

  const profile = Profile(
    id: 't81b3-takeover',
    autoUpdateDuration: Duration(hours: 1),
  );

  test('all four sections are always sent, no gate key remains', () async {
    const patchConfig = ClashConfig(
      ntp: Ntp(server: 'ntp.example.com'),
      sniffer: Sniffer(forceDomain: ['+.example.com']),
      experimental: Experimental(quicGoDisableGso: false),
    );
    final params = await globalState.buildPatchParams(
      patchConfig: patchConfig,
      profile: profile,
    );
    expect(params.containsKey('override-dns'), isFalse);
    expect(params['dns'], isNotNull);
    expect(params['ntp'], patchConfig.ntp.toJson());
    expect(params['sniffer'], patchConfig.sniffer.toJson());
    expect(params['experimental'], patchConfig.experimental.toJson());
  });

  test('external-ui and geodata values come from the model', () async {
    const patchConfig = ClashConfig(
      externalUiUrl: 'https://example.com/ui.zip',
      externalUiName: 'my-ui',
      geodataLoader: GeodataLoader.standard,
      geodataMode: true,
    );
    final params = await globalState.buildPatchParams(
      patchConfig: patchConfig,
      profile: profile,
    );
    final general = params['general'] as Map<String, dynamic>;
    expect(general['external-ui-url'], 'https://example.com/ui.zip');
    expect(general['external-ui-name'], 'my-ui');
    expect(general['geodata-loader'], 'standard');
    expect(general['geodata-mode'], isTrue);
  });

  test('defaults preserve the pre-takeover hardcoded values', () async {
    final params = await globalState.buildPatchParams(
      patchConfig: const ClashConfig(),
      profile: profile,
    );
    final general = params['general'] as Map<String, dynamic>;
    expect(general['external-ui-url'], defaultExternalUiUrl);
    expect(general['external-ui-name'], defaultExternalUiName);
    expect(general['geodata-loader'], 'memconservative');
    expect(general['geodata-mode'], isFalse);
  });
}
