import 'dart:io';

/// AngelaMihomo (T281, audit AM-05): destination guard for the
/// subscription download chain.
///
/// The guard blocks only the destinations a subscription URL must
/// never reach: link-local addresses — 169.254.0.0/16 (which includes
/// the cloud metadata address 169.254.169.254) and fe80::/10 — plus
/// the cloud metadata hostnames. Loopback and RFC1918 destinations
/// stay allowed on purpose: a subscription converter or subscription
/// server running on this machine or on the LAN is a legitimate,
/// user-entered configuration source, so blocking them would remove
/// a feature. The check is purely syntactic (URL host only, no DNS
/// resolution) and is applied to the initial request and to every
/// redirect hop by the download chain in request.dart.
enum DownloadTargetBlock { linkLocalAddress, cloudMetadataHost }

class BlockedDownloadTargetException implements Exception {
  BlockedDownloadTargetException(this.uri, this.reason);

  final Uri uri;
  final DownloadTargetBlock reason;

  @override
  String toString() =>
      'Blocked download target $uri (${reason.name}): link-local and '
      'cloud metadata destinations are not allowed for subscription '
      'downloads';
}

abstract final class DownloadTargetGuard {
  /// Hostnames that always resolve to a cloud metadata service.
  /// `metadata.google.internal` is the documented Google Cloud
  /// metadata hostname; `metadata.google` and the bare `metadata`
  /// name reach the same service through resolver search paths.
  static const Set<String> _metadataHostnames = {
    'metadata.google.internal',
    'metadata.google',
    'metadata',
  };

  /// Returns why [uri] must not be fetched, or null when the target
  /// is allowed. Only http/https URIs are classified; any other
  /// scheme returns null (the download chain only speaks http/https,
  /// and file:// sources are handled by a separate branch).
  static DownloadTargetBlock? blockFor(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;

    var host = uri.host.trim().toLowerCase();
    if (host.endsWith('.')) host = host.substring(0, host.length - 1);
    if (_metadataHostnames.contains(host)) {
      return DownloadTargetBlock.cloudMetadataHost;
    }

    // Strip an IPv6 zone id (fe80::1%eth0 / fe80::1%25eth0) so the
    // address parses.
    final zoneIndex = host.indexOf('%');
    final bareHost = zoneIndex >= 0 ? host.substring(0, zoneIndex) : host;
    final address = InternetAddress.tryParse(bareHost);
    if (address == null) return null;
    final raw = address.rawAddress;
    if (address.type == InternetAddressType.IPv4) {
      // 169.254.0.0/16 link-local (includes 169.254.169.254).
      if (raw[0] == 169 && raw[1] == 254) {
        return DownloadTargetBlock.linkLocalAddress;
      }
    } else if (address.type == InternetAddressType.IPv6) {
      // fe80::/10 link-local: first byte 0xfe, next two bits 10.
      if (raw[0] == 0xfe && (raw[1] & 0xc0) == 0x80) {
        return DownloadTargetBlock.linkLocalAddress;
      }
    }
    return null;
  }

  static bool isBlocked(Uri uri) => blockFor(uri) != null;

  static void ensureAllowed(Uri uri) {
    final reason = blockFor(uri);
    if (reason != null) throw BlockedDownloadTargetException(uri, reason);
  }
}
