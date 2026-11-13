import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// T110 guard: the app lock covers the UI only. Its files must never
// gain a reference to a core/VPN stop path — the T88/T110 audits
// established that the lock has no stop path by construction, and
// this test pins that invariant as a regression assertion instead of
// relying on re-audits. Source-level on purpose: the property is
// "these files do not reference stop machinery at all".
void main() {
  group('app lock stays UI-only (T110 guard)', () {
    const lockFiles = <String>[
      'lib/common/app_lock.dart',
      'lib/views/app_lock.dart',
    ];

    const forbiddenSymbols = <String>[
      'handleStop',
      'handleExit',
      'updateStatus',
      'clashCore',
      'clashLibHandler',
      'stopService',
      'killProcess',
    ];

    for (final path in lockFiles) {
      test('$path references no core/service stop symbol', () {
        final file = File(path);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'guard expects $path relative to the package root',
        );
        final source = file.readAsStringSync();
        for (final symbol in forbiddenSymbols) {
          expect(
            source.contains(symbol),
            isFalse,
            reason: '$path must not reference $symbol',
          );
        }
      });
    }
  });
}
