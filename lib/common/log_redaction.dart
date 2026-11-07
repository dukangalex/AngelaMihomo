/// Log redaction for exports (T36).
///
/// App logs are only ever shared when the user explicitly exports or
/// copies them, but a single line can still carry a subscription URL
/// with its token, a node UUID/password, or a WebDAV credential. This
/// pure function scrubs those credential shapes while keeping the log
/// line's structure — timestamps, levels, target hosts, error text —
/// so an exported log stays diagnosable without leaking secrets.
///
/// Deliberately conservative: anything that *looks* like a credential
/// is masked even at the cost of masking an occasional long random
/// identifier that was harmless.
library;

const _mask = '•••';

final _proxyLinkPattern = RegExp(
  r'(vmess|vless|trojan|ss|ssr|hysteria|hysteria2|hy2|tuic|wireguard)://\S+',
  caseSensitive: false,
);

final _urlPattern = RegExp(r'https?://[^\s<>\]]+');

final _uuidPattern = RegExp(
  r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b',
);

final _bearerPattern = RegExp(
  r'\b(Bearer|Basic)\s+[A-Za-z0-9._~+/=-]+',
  caseSensitive: false,
);

final _secretKeyValuePattern = RegExp(
  r'''(password|passwd|pwd|token|secret|api[-_]?key|apikey|authorization|auth|dav[-_]?password)(["']?\s*[:=]\s*["']?)([^\s"',}\]]+)''',
  caseSensitive: false,
);

/// Long opaque blobs (share-link payloads, session tokens, keys that
/// escaped the structured patterns above). Requires a mix of letters
/// and digits so plain words and pure numbers survive.
final _blobPattern = RegExp(r'\b[A-Za-z0-9+/=_-]{40,}\b');

/// Redacts one log line (or a whole multi-line export — the patterns
/// never span lines).
String redactLogText(String input) {
  var text = input;
  // Share links first: their payload is one opaque credential blob.
  text = text.replaceAllMapped(
    _proxyLinkPattern,
    (m) => '${m.group(1)}://$_mask',
  );
  // URLs: keep scheme + host (+port) for diagnosability, drop
  // userinfo, path and query — that is where subscription tokens live.
  text = text.replaceAllMapped(_urlPattern, (m) {
    var raw = m.group(0)!;
    // The pattern may swallow trailing quotes from surrounding text.
    var trailer = '';
    while (raw.endsWith('"') || raw.endsWith("'")) {
      trailer = raw[raw.length - 1] + trailer;
      raw = raw.substring(0, raw.length - 1);
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return '$_mask$trailer';
    final port = uri.hasPort ? ':${uri.port}' : '';
    final hasTail =
        uri.userInfo.isNotEmpty ||
        uri.pathSegments.any((s) => s.isNotEmpty) ||
        uri.hasQuery;
    return '${uri.scheme}://${uri.host}$port${hasTail ? '/$_mask' : ''}$trailer';
  });
  text = text.replaceAll(_uuidPattern, _mask);
  text = text.replaceAllMapped(
    _bearerPattern,
    (m) => '${m.group(1)} $_mask',
  );
  text = text.replaceAllMapped(
    _secretKeyValuePattern,
    (m) => '${m.group(1)}${m.group(2)}$_mask',
  );
  text = text.replaceAllMapped(_blobPattern, (m) {
    final value = m.group(0)!;
    final hasLetter = value.contains(RegExp(r'[A-Za-z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));
    return hasLetter && hasDigit ? _mask : value;
  });
  return text;
}
