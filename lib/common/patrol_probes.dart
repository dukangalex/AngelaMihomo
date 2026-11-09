import 'dart:async';
import 'dart:io';

import 'package:bett_box/common/constant.dart';
import 'package:bett_box/common/request.dart';
import 'package:bett_box/models/patrol_diagnosis.dart';

/// Live probes for patrol issue details (T68).
///
/// The diagnosis layer decides WHAT to measure (the issue's probe
/// plan); this layer performs the measurements against the real
/// network path — system DNS, direct TCP/TLS to the subscription
/// host, the local core proxy port, and full fetches both direct and
/// through the app's own request path. Every outcome is a measured
/// fact with a short detail (counts, status codes, the failing
/// error's own text), never an assumption: this is what the detail
/// page's "凭什么" section shows, and what the measured stage is
/// derived from (bowel #1: 状态实测而非假设）.
///
/// Probes only ever READ: fetches stop at the response headers, and
/// nothing here mutates app or core state.
class PatrolProbeOutcome {
  final PatrolProbeKind kind;
  final bool ok;

  /// Short factual detail: "3 addresses", "HTTP 404", or the
  /// failing error's text (classified later into a stage).
  final String detail;

  const PatrolProbeOutcome({
    required this.kind,
    required this.ok,
    this.detail = '',
  });
}

typedef PatrolProbeResults = Map<PatrolProbeKind, PatrolProbeOutcome>;

extension PatrolProbeResultsX on PatrolProbeResults {
  Map<PatrolProbeKind, ({bool ok, String detail})> get byKind => {
    for (final entry in entries)
      entry.key: (ok: entry.value.ok, detail: entry.value.detail),
  };
}

const _dnsTimeout = Duration(seconds: 5);
const _connectTimeout = Duration(seconds: 5);
const _tlsTimeout = Duration(seconds: 8);
const _fetchTimeout = Duration(seconds: 12);

/// Runs [plan] against [url] (the subscription address) in order.
/// The direct chain descends stage by stage and stops at the first
/// failure — probing TCP after DNS failed measures nothing. The
/// proxy hop and the proxied fetch are independent of the direct
/// chain and always run when planned.
Future<PatrolProbeResults> runPatrolProbes(
  List<PatrolProbeKind> plan, {
  required Uri url,
  required int proxyPort,
}) async {
  final results = <PatrolProbeKind, PatrolProbeOutcome>{};
  final wants = plan.toSet();
  final host = url.host;
  final port = url.hasPort
      ? url.port
      : (url.scheme == 'https' ? 443 : 80);

  if (wants.contains(PatrolProbeKind.proxyPort)) {
    results[PatrolProbeKind.proxyPort] = await _probeProxyPort(proxyPort);
  }

  var chainAlive = true;
  List<InternetAddress>? addresses;
  if (wants.contains(PatrolProbeKind.dnsLookup)) {
    final outcome = await _probeDns(host);
    results[PatrolProbeKind.dnsLookup] = outcome;
    chainAlive = outcome.ok;
    if (outcome.ok) {
      addresses = await InternetAddress.lookup(host).catchError(
        (_) => <InternetAddress>[],
      );
    }
  }

  Socket? socket;
  if (wants.contains(PatrolProbeKind.tcpConnect)) {
    if (!chainAlive) {
      results[PatrolProbeKind.tcpConnect] = const PatrolProbeOutcome(
        kind: PatrolProbeKind.tcpConnect,
        ok: false,
        detail: 'skipped: earlier stage failed',
      );
    } else {
      final target = (addresses != null && addresses.isNotEmpty)
          ? addresses.first
          : host;
      final probed = await _probeTcp(target, port);
      results[PatrolProbeKind.tcpConnect] = probed.outcome;
      chainAlive = probed.outcome.ok;
      // The live socket is handed to the TLS probe: one connection,
      // measured once, then upgraded in place.
      socket = probed.socket;
    }
  }

  if (wants.contains(PatrolProbeKind.tlsHandshake)) {
    if (!chainAlive || socket == null) {
      results[PatrolProbeKind.tlsHandshake] = const PatrolProbeOutcome(
        kind: PatrolProbeKind.tlsHandshake,
        ok: false,
        detail: 'skipped: earlier stage failed',
      );
    } else {
      results[PatrolProbeKind.tlsHandshake] = await _probeTls(socket, host);
    }
  }
  socket?.destroy();

  if (wants.contains(PatrolProbeKind.directFetch)) {
    results[PatrolProbeKind.directFetch] = await _probeFetch(
      url,
      viaProxyPort: null,
    );
  }
  if (wants.contains(PatrolProbeKind.proxyFetch)) {
    results[PatrolProbeKind.proxyFetch] = await _probeFetchViaAppPath(url);
  }
  return results;
}

Future<PatrolProbeOutcome> _probeProxyPort(int proxyPort) async {
  try {
    final socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      proxyPort,
      timeout: const Duration(seconds: 3),
    );
    socket.destroy();
    return PatrolProbeOutcome(
      kind: PatrolProbeKind.proxyPort,
      ok: true,
      detail: '127.0.0.1:$proxyPort accepts connections',
    );
  } catch (error) {
    return PatrolProbeOutcome(
      kind: PatrolProbeKind.proxyPort,
      ok: false,
      detail: '$error',
    );
  }
}

Future<PatrolProbeOutcome> _probeDns(String host) async {
  // An IP literal needs no resolution; that IS the measured result.
  if (InternetAddress.tryParse(host) != null) {
    return const PatrolProbeOutcome(
      kind: PatrolProbeKind.dnsLookup,
      ok: true,
      detail: 'IP literal, no resolution needed',
    );
  }
  try {
    final addresses = await InternetAddress.lookup(
      host,
    ).timeout(_dnsTimeout);
    if (addresses.isEmpty) {
      return const PatrolProbeOutcome(
        kind: PatrolProbeKind.dnsLookup,
        ok: false,
        detail: 'no addresses returned',
      );
    }
    return PatrolProbeOutcome(
      kind: PatrolProbeKind.dnsLookup,
      ok: true,
      detail: '${addresses.length} address(es)',
    );
  } catch (error) {
    return PatrolProbeOutcome(
      kind: PatrolProbeKind.dnsLookup,
      ok: false,
      detail: '$error',
    );
  }
}

/// On success the open socket is returned with the outcome so the
/// TLS probe can upgrade the very connection that was measured.
Future<({PatrolProbeOutcome outcome, Socket? socket})> _probeTcp(
  Object address,
  int port,
) async {
  try {
    final socket = await Socket.connect(
      address,
      port,
      timeout: _connectTimeout,
    );
    return (
      outcome: PatrolProbeOutcome(
        kind: PatrolProbeKind.tcpConnect,
        ok: true,
        detail: '$address:$port reachable',
      ),
      socket: socket,
    );
  } catch (error) {
    return (
      outcome: PatrolProbeOutcome(
        kind: PatrolProbeKind.tcpConnect,
        ok: false,
        detail: '$error',
      ),
      socket: null,
    );
  }
}

Future<PatrolProbeOutcome> _probeTls(Socket socket, String host) async {
  try {
    final secure = await SecureSocket.secure(
      socket,
      host: host,
    ).timeout(_tlsTimeout);
    final peer = secure.peerCertificate;
    secure.destroy();
    return PatrolProbeOutcome(
      kind: PatrolProbeKind.tlsHandshake,
      ok: true,
      detail: peer == null ? 'handshake ok' : 'handshake ok · ${peer.subject}',
    );
  } catch (error) {
    return PatrolProbeOutcome(
      kind: PatrolProbeKind.tlsHandshake,
      ok: false,
      detail: '$error',
    );
  }
}

/// Header-only fetch. [viaProxyPort] null means forced DIRECT (the
/// device's own network path); otherwise the request goes through
/// the given local proxy port, mirroring the app's fetch path.
Future<PatrolProbeOutcome> _probeFetch(
  Uri url, {
  required int? viaProxyPort,
}) async {
  final kind = viaProxyPort == null
      ? PatrolProbeKind.directFetch
      : PatrolProbeKind.proxyFetch;
  final client = HttpClient();
  client.connectionTimeout = _connectTimeout;
  if (viaProxyPort != null) {
    client.findProxy = (_) => 'PROXY 127.0.0.1:$viaProxyPort';
  } else {
    client.findProxy = (_) => 'DIRECT';
  }
  try {
    final req = await client.getUrl(url).timeout(_fetchTimeout);
    req.headers.set(HttpHeaders.userAgentHeader, browserUa);
    final response = await req.close().timeout(_fetchTimeout);
    final status = response.statusCode;
    await response.drain<void>().catchError((_) {});
    return PatrolProbeOutcome(
      kind: kind,
      ok: status >= 200 && status < 400,
      detail: 'HTTP $status',
    );
  } catch (error) {
    return PatrolProbeOutcome(kind: kind, ok: false, detail: '$error');
  } finally {
    client.close(force: true);
  }
}

/// The app's own fetch path, verbatim: the same request helper the
/// subscription update uses, so its outcome is the ground truth for
/// "can the app fetch this at all right now". A non-2xx answer comes
/// back as a thrown DioException whose text carries the status code.
Future<PatrolProbeOutcome> _probeFetchViaAppPath(Uri url) async {
  try {
    final response = await request.getFileResponseForUrl(url.toString());
    final status = response.statusCode ?? 0;
    return PatrolProbeOutcome(
      kind: PatrolProbeKind.proxyFetch,
      ok: status >= 200 && status < 400,
      detail: 'HTTP $status',
    );
  } catch (error) {
    return PatrolProbeOutcome(
      kind: PatrolProbeKind.proxyFetch,
      ok: false,
      detail: '$error',
    );
  }
}
