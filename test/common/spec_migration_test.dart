import 'package:bett_box/common/spec_migration.dart';
import 'package:bett_box/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

// T81 batch 3 (P-2) regression: the one-time inheritance migration
// that runs before the dns/ntp/sniffer/experimental takeover.
// Per section: legacy gate ON keeps the App model (it was already
// authoritative); gate OFF inherits the subscription section when the
// current profile carries one; gate OFF without a subscription
// section keeps the model (factory defaults for untouched users).
// On the pre-batch code this file does not compile (no migration, no
// geosite/ipv6-timeout/cache-max-size/fingerprints carriers).
void main() {
  const subscription = <String, dynamic>{
    'dns': {
      'enable': true,
      'listen': '0.0.0.0:1053',
      'nameserver': ['9.9.9.9'],
      'cache-max-size': 12345,
      'ipv6-timeout': 7,
      'listen-routing-mark': 99,
      'fallback-filter': {
        'geoip': true,
        'geosite': ['gfw'],
      },
      'nameserver-policy': {
        'geosite:cn': ['1.1.1.1', '8.8.8.8'],
      },
    },
    'ntp': {
      'enable': true,
      'server': 'ntp.example.com',
      'port': 124,
      'interval': 30,
      'write-to-system': true,
    },
    'sniffer': {
      'enable': true,
      'force-domain': ['+.example.com'],
      'port-whitelist': ['80'],
      'sniff': {
        'TLS': {'ports': ['8443']},
      },
    },
    'experimental': {
      'quic-go-disable-gso': false,
      'fingerprints': ['fp-a'],
    },
  };

  group('LegacySectionGates.fromRawConfig', () {
    test('reads the legacy flags, missing means off', () {
      final gates = LegacySectionGates.fromRawConfig({
        'overrideDns': true,
        'overrideSniffer': true,
      });
      expect(gates.dns, isTrue);
      expect(gates.ntp, isFalse);
      expect(gates.sniffer, isTrue);
      expect(gates.experimental, isFalse);
    });

    test('null raw config means all gates off', () {
      final gates = LegacySectionGates.fromRawConfig(null);
      expect(gates.dns, isFalse);
      expect(gates.ntp, isFalse);
      expect(gates.sniffer, isFalse);
      expect(gates.experimental, isFalse);
    });
  });

  group('seedSectionsFromSubscription', () {
    test('gate off inherits all four sections from the subscription', () {
      final seeded = seedSectionsFromSubscription(
        model: const ClashConfig(),
        gates: const LegacySectionGates(),
        subscription: subscription,
      );
      expect(seeded.dns.nameserver, ['9.9.9.9']);
      expect(seeded.dns.listen, '0.0.0.0:1053');
      expect(seeded.dns.fallbackFilter.geosite, ['gfw']);
      expect(seeded.dns.cacheMaxSize, 12345);
      expect(seeded.dns.ipv6Timeout, 7);
      expect(seeded.dns.listenRoutingMark, 99);
      // YAML list policy values are joined into the App representation.
      expect(seeded.dns.nameserverPolicy['geosite:cn'], '1.1.1.1,8.8.8.8');
      expect(seeded.ntp.server, 'ntp.example.com');
      expect(seeded.ntp.port, 124);
      expect(seeded.ntp.interval, 30);
      expect(seeded.ntp.writeToSystem, isTrue);
      expect(seeded.sniffer.forceDomain, ['+.example.com']);
      expect(seeded.sniffer.port, ['80']);
      expect(seeded.sniffer.sniff['TLS']?.ports, ['8443']);
      expect(seeded.experimental.quicGoDisableGso, isFalse);
      expect(seeded.experimental.fingerprints, ['fp-a']);
    });

    test('gate on keeps the App model section exactly', () {
      const model = ClashConfig(
        dns: Dns(nameserver: ['5.5.5.5']),
        ntp: Ntp(server: 'model.example.com'),
        sniffer: Sniffer(forceDomain: ['+.model.com']),
        experimental: Experimental(quicGoDisableGso: true),
      );
      final seeded = seedSectionsFromSubscription(
        model: model,
        gates: const LegacySectionGates(
          dns: true,
          ntp: true,
          sniffer: true,
          experimental: true,
        ),
        subscription: subscription,
      );
      expect(seeded.dns.nameserver, ['5.5.5.5']);
      expect(seeded.ntp.server, 'model.example.com');
      expect(seeded.sniffer.forceDomain, ['+.model.com']);
      expect(seeded.experimental.quicGoDisableGso, isTrue);
    });

    test('gates are per-section: dns gated, ntp inherited', () {
      final seeded = seedSectionsFromSubscription(
        model: const ClashConfig(dns: Dns(nameserver: ['5.5.5.5'])),
        gates: const LegacySectionGates(dns: true),
        subscription: subscription,
      );
      expect(seeded.dns.nameserver, ['5.5.5.5']);
      expect(seeded.ntp.server, 'ntp.example.com');
    });

    test('gate off without a subscription section keeps the model', () {
      final seeded = seedSectionsFromSubscription(
        model: const ClashConfig(),
        gates: const LegacySectionGates(),
        subscription: const {
          'dns': {'nameserver': ['9.9.9.9']},
        },
      );
      expect(seeded.dns.nameserver, ['9.9.9.9']);
      // No ntp/sniffer/experimental in the subscription: defaults stay.
      expect(seeded.ntp, const Ntp());
      expect(seeded.sniffer, const Sniffer());
      expect(seeded.experimental, const Experimental());
    });

    test('no subscription at all keeps the model untouched', () {
      const model = ClashConfig();
      final seeded = seedSectionsFromSubscription(
        model: model,
        gates: const LegacySectionGates(),
        subscription: null,
      );
      expect(seeded, model);
    });
  });
}
