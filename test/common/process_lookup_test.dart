import 'dart:async';

import 'package:angelamihomo/common/process_lookup.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Metadata flow({String sourcePort = '51000', String network = 'tcp'}) =>
    Metadata(
      network: network,
      sourceIP: '172.19.0.2',
      sourcePort: sourcePort,
      destinationIP: '1.1.1.1',
      destinationPort: '443',
    );

void main() {
  test('resolves once and serves repeats from the cache', () async {
    var calls = 0;
    final resolver = ConnectionProcessResolver(
      lookup: (_) async {
        calls++;
        return 'com.example.app';
      },
    );
    expect(await resolver.resolve(flow()), 'com.example.app');
    expect(await resolver.resolve(flow()), 'com.example.app');
    expect(calls, 1);
    expect(resolver.hasCached(flow()), isTrue);
    expect(resolver.cached(flow()), 'com.example.app');
  });

  test('concurrent resolves share one platform query', () async {
    var calls = 0;
    final gate = Completer<String?>();
    final resolver = ConnectionProcessResolver(
      lookup: (_) {
        calls++;
        return gate.future;
      },
    );
    final first = resolver.resolve(flow());
    final second = resolver.resolve(flow());
    gate.complete('com.example.app');
    expect(await first, 'com.example.app');
    expect(await second, 'com.example.app');
    expect(calls, 1);
  });

  test('an unattributable flow is cached as null, not re-queried', () async {
    var calls = 0;
    final resolver = ConnectionProcessResolver(
      lookup: (_) async {
        calls++;
        return null;
      },
    );
    expect(await resolver.resolve(flow()), isNull);
    expect(await resolver.resolve(flow()), isNull);
    expect(calls, 1);
    expect(resolver.hasCached(flow()), isTrue);
    expect(resolver.cached(flow()), isNull);
  });

  test('a failing lookup resolves to null instead of throwing', () async {
    final resolver = ConnectionProcessResolver(
      lookup: (_) async => throw StateError('platform gone'),
    );
    expect(await resolver.resolve(flow()), isNull);
    expect(resolver.hasCached(flow()), isTrue);
  });

  test('distinct flows are distinct cache entries', () async {
    final resolver = ConnectionProcessResolver(
      lookup: (metadata) async => 'pkg-${metadata.sourcePort}',
    );
    expect(await resolver.resolve(flow()), 'pkg-51000');
    expect(await resolver.resolve(flow(sourcePort: '51001')), 'pkg-51001');
    expect(
      resolver.keyFor(flow()),
      isNot(resolver.keyFor(flow(network: 'udp'))),
    );
  });
}
