import 'package:dio/dio.dart';

/// Reads stable releases only. Never construct an installer URL: fork assets
/// may have different names, and a platform package may not have been built.
class ReleaseUpdates {
  final Dio client;
  final String repository;

  ReleaseUpdates({required this.repository, Dio? client})
    : client =
          client ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  String get releasesUrl => 'https://github.com/$repository/releases';

  Future<Map<String, dynamic>?> latest() async {
    try {
      final response = await client.get<Object?>(
        'https://api.github.com/repos/$repository/releases/latest',
        options: Options(headers: {'Accept': 'application/vnd.github+json'}),
      );
      final data = response.data;
      if (data is! Map || data['draft'] == true || data['prerelease'] == true) {
        return null;
      }
      final tag = data['tag_name'];
      if (tag is! String || tag.trim().isEmpty) return null;
      return {
        ...Map<String, dynamic>.from(data),
        // Use the repository we asked for, not an untrusted response URL.
        'html_url': '$releasesUrl/tag/${Uri.encodeComponent(tag)}',
      };
    } on DioException {
      // Public API rate limits or API outages must not prevent a manual check.
      // The web /latest endpoint redirects only to the latest stable release.
      final response = await client.get<Object?>(
        '$releasesUrl/latest',
        options: Options(
          followRedirects: false,
          validateStatus: (status) =>
              status != null && status >= 300 && status < 400,
        ),
      );
      final location = response.headers.value('location');
      if (location == null) return null;
      final uri = Uri.parse('$releasesUrl/latest').resolve(location);
      final prefix = Uri.parse('$releasesUrl/tag/');
      if (uri.scheme != prefix.scheme ||
          uri.host != prefix.host ||
          uri.pathSegments.length != 5 ||
          uri.pathSegments.take(4).join('/') !=
              prefix.pathSegments.take(4).join('/')) {
        return null;
      }
      final tag = uri.pathSegments.last;
      if (tag.isEmpty) return null;
      return {
        'tag_name': tag,
        'html_url': '$releasesUrl/tag/${Uri.encodeComponent(tag)}',
        'body': 'New version available. Please visit GitHub to download.',
        'assets': <Object?>[],
      };
    }
  }

  String downloadUrl(Map<String, dynamic> release, {String assetSuffix = ''}) {
    return assetFor(release, assetSuffix: assetSuffix)?.url ?? releasesUrlFor(release);
  }

  String releasesUrlFor(Map<String, dynamic> release) {
    final tag = release['tag_name'];
    if (tag is! String || tag.isEmpty) return releasesUrl;
    return '$releasesUrl/tag/${Uri.encodeComponent(tag)}';
  }

  /// AngelaMihomo (chain.26, T179): the validated release asset for
  /// in-app updates — same strict matching as [downloadUrl] (exact
  /// asset name, exact download URL for this repository and tag), but
  /// returns the asset's metadata so the caller can download it in-app
  /// and verify it against the digest GitHub reports.
  ReleaseAsset? assetFor(
    Map<String, dynamic> release, {
    String assetSuffix = '',
  }) {
    final tag = release['tag_name'];
    if (tag is! String || tag.isEmpty) return null;
    if (assetSuffix.isEmpty) return null;
    final version = tag.replaceFirst(RegExp(r'^v'), '');
    final names = {
      'AngelaMihomo-$version-$assetSuffix',
      // Legacy asset names from before the rebrand, kept so update
      // checks can still deep-link downloads of older releases.
      'Bettbox-$version-$assetSuffix',
      'AngelaBettbox-$version-$assetSuffix',
    };
    final assets = release['assets'];
    if (assets is! List) return null;
    final matches = assets
        .whereType<Map>()
        .where((asset) => names.contains(asset['name']))
        .toList();
    if (matches.length != 1) return null;
    final asset = matches.single;
    final url = asset['browser_download_url'];
    if (url is! String) return null;
    final uri = Uri.tryParse(url);
    // Only open an exact asset from this repository and this release tag.
    final expected = Uri.parse(
      'https://github.com/$repository/releases/download/${Uri.encodeComponent(tag)}/${Uri.encodeComponent(asset['name'] as String)}',
    );
    if (uri == null || uri != expected) return null;
    final size = asset['size'];
    final digest = asset['digest'];
    return ReleaseAsset(
      name: asset['name'] as String,
      url: url,
      size: size is int ? size : null,
      sha256: digest is String && digest.startsWith('sha256:')
          ? digest.substring('sha256:'.length)
          : null,
    );
  }
}

/// One validated asset of a GitHub release (see [ReleaseUpdates.assetFor]).
class ReleaseAsset {
  final String name;
  final String url;
  final int? size;

  /// Lowercase hex SHA-256 reported by the GitHub API, when present.
  final String? sha256;

  const ReleaseAsset({
    required this.name,
    required this.url,
    this.size,
    this.sha256,
  });
}
