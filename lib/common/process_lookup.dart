import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/plugins/app.dart';

/// Looks up the owning package of one connection flow. The platform
/// implementation is [ConnectionProcessResolver.platformLookup];
/// tests inject a fake.
typedef ConnectionOwnerLookup = Future<String?> Function(Metadata metadata);

/// T309: backfill for find-process-mode=strict on Android.
///
/// In strict mode the kernel resolves a connection's process lazily —
/// only when a rule actually asks — so the connections page mostly
/// sees an empty process. The platform can still attribute a live
/// flow on demand (ConnectivityManager.getConnectionOwnerUid, API
/// 29+, available to the active VPN app), which is exactly the
/// granularity needed here: one query per visible flow, answered by
/// the system, nothing polled and nothing scanned.
///
/// Results (including "cannot attribute") are cached per flow
/// four-tuple, so a flow is queried at most once while it is on
/// screen; the cache is FIFO-capped because source ports rotate.
class ConnectionProcessResolver {
  ConnectionProcessResolver({ConnectionOwnerLookup? lookup})
    : _lookup = lookup ?? platformLookup;

  static final ConnectionProcessResolver instance =
      ConnectionProcessResolver();

  static const int _cacheCap = 512;

  final ConnectionOwnerLookup _lookup;
  final Map<String, String?> _cache = {};
  final Map<String, Future<String?>> _pending = {};

  static Future<String?> platformLookup(Metadata metadata) {
    final protocol = switch (metadata.network.toLowerCase()) {
      'tcp' => 6, // IPPROTO_TCP
      'udp' => 17, // IPPROTO_UDP
      _ => -1,
    };
    if (protocol < 0) return Future.value(null);
    return app.getConnectionOwnerPackage(
      protocol: protocol,
      sourceIp: metadata.sourceIP,
      sourcePort: int.tryParse(metadata.sourcePort) ?? 0,
      destinationIp: metadata.destinationIP,
      destinationPort: int.tryParse(metadata.destinationPort) ?? 0,
    );
  }

  String keyFor(Metadata metadata) =>
      '${metadata.network}|${metadata.sourceIP}|${metadata.sourcePort}'
      '|${metadata.destinationIP}|${metadata.destinationPort}';

  bool hasCached(Metadata metadata) => _cache.containsKey(keyFor(metadata));

  String? cached(Metadata metadata) => _cache[keyFor(metadata)];

  Future<String?> resolve(Metadata metadata) {
    final key = keyFor(metadata);
    if (_cache.containsKey(key)) return Future.value(_cache[key]);
    return _pending[key] ??= _lookup(metadata)
        .then((package) {
          _store(key, package);
          _pending.remove(key);
          return package;
        })
        .catchError((Object _) {
          _store(key, null);
          _pending.remove(key);
          return null;
        });
  }

  void _store(String key, String? package) {
    _cache[key] = package;
    while (_cache.length > _cacheCap) {
      _cache.remove(_cache.keys.first);
    }
  }

  void clear() {
    _cache.clear();
    _pending.clear();
  }
}
