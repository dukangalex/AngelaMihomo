import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/state.dart';
import 'package:flutter_test/flutter_test.dart';

// T111 B-05/B-06/C-06: the re-assembly fingerprint must move for
// every assembly input the older channels missed, and only for
// those (hot-projection fields like mode must not double-trigger).
void main() {
  String fingerprint(
    ClashConfig config, {
    bool overrideNtp = false,
    bool overrideSniffer = false,
    bool overrideExperimental = false,
    String? locale,
  }) {
    return needSetupExtraFingerprint(
      patchConfig: config,
      overrideNtp: overrideNtp,
      overrideSniffer: overrideSniffer,
      overrideExperimental: overrideExperimental,
      locale: locale,
    );
  }

  const base = ClashConfig();

  test('override section edits register only while the switch is on', () {
    final edited = base.copyWith(
      ntp: base.ntp.copyWith(server: 'ntp.example.com'),
    );
    expect(fingerprint(edited, overrideNtp: false), fingerprint(base));
    expect(
      fingerprint(edited, overrideNtp: true),
      isNot(fingerprint(base, overrideNtp: true)),
    );
    // Flipping the switch itself must register.
    expect(
      fingerprint(base, overrideNtp: true),
      isNot(fingerprint(base, overrideNtp: false)),
    );
  });

  test('sniffer and experimental sections register while on', () {
    final snifferEdited = base.copyWith(
      sniffer: base.sniffer.copyWith(forceDnsMapping: false),
    );
    expect(
      fingerprint(snifferEdited, overrideSniffer: true),
      isNot(fingerprint(base, overrideSniffer: true)),
    );
    final experimentalEdited = base.copyWith(
      experimental: base.experimental.copyWith(quicGoDisableGso: false),
    );
    expect(
      fingerprint(experimentalEdited, overrideExperimental: true),
      isNot(fingerprint(base, overrideExperimental: true)),
    );
  });

  test('tunnels and hosts edits register', () {
    final withTunnel = base.copyWith(
      tunnels: const [
        TunnelEntry(
          id: 't1',
          network: ['tcp'],
          address: '127.0.0.1:1080',
          target: '127.0.0.1:1081',
        ),
      ],
    );
    expect(fingerprint(withTunnel), isNot(fingerprint(base)));
    final withHost = base.copyWith(
      hosts: const {
        'example.com': '1.2.3.4',
      },
    );
    expect(fingerprint(withHost), isNot(fingerprint(base)));
  });

  test('general extras register: ports, keep-alive, UA, auth', () {
    expect(
      fingerprint(base.copyWith(port: 7891)),
      isNot(fingerprint(base)),
    );
    expect(
      fingerprint(base.copyWith(socksPort: 7892)),
      isNot(fingerprint(base)),
    );
    expect(
      fingerprint(base.copyWith(keepAliveInterval: 15)),
      isNot(fingerprint(base)),
    );
    expect(
      fingerprint(base.copyWith(globalUa: 'Custom/1.0')),
      isNot(fingerprint(base)),
    );
    expect(
      fingerprint(base.copyWith(authentication: const ['user:pass'])),
      isNot(fingerprint(base)),
    );
  });

  test('locale changes register (derived rule variants)', () {
    expect(
      fingerprint(base, locale: 'ru'),
      isNot(fingerprint(base, locale: 'en')),
    );
  });

  test('hot-projection fields do not register', () {
    expect(
      fingerprint(base.copyWith(mode: Mode.global)),
      fingerprint(base),
    );
    expect(
      fingerprint(base.copyWith(mixedPort: 7899)),
      fingerprint(base),
    );
    expect(
      fingerprint(base.copyWith(logLevel: LogLevel.info)),
      fingerprint(base),
    );
  });
}
