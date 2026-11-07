import 'package:dio/dio.dart';

/// One asset of a release, exactly as listed by the API (T56). The
/// in-app updater selects from this list — it never constructs an
/// asset name or URL itself.
class ReleaseAsset {
  final String name;
  final String url;

  const ReleaseAsset({required this.name, required this.url});
}

/// Parses the release's asset list, keeping only assets whose
/// download URL is the canonical one for this repository and tag
/// (same exactness rule as [ReleaseUpdates.downloadUrl]).
List<ReleaseAsset> releaseAssetsOf(
  Map<String, dynamic> release, {
  required String repository,
}) {
  final tag = release['tag_name'];
  final assets = release['assets'];
  if (tag is! String || tag.isEmpty || assets is! List) return const [];
  final result = <ReleaseAsset>[];
  for (final asset in assets.whereType<Map>()) {
    final name = asset['name'];
    final url = asset['browser_download_url'];
    if (name is! String || url is! String) continue;
    final expected =
        'https://github.com/$repository/releases/download/'
        '${Uri.encodeComponent(tag)}/${Uri.encodeComponent(name)}';
    if (url == expected) result.add(ReleaseAsset(name: name, url: url));
  }
  return result;
}

/// Selects the installer for this device from the release's actual
/// asset list (T56): platform + architecture match, best candidate
/// wins; null when the release carries nothing for this device (the
/// caller then falls back to the release page and says why).
ReleaseAsset? selectUpdateAsset(
  List<ReleaseAsset> assets, {
  required String platform,
  required String arch,
  bool portable = false,
}) {
  bool nameHas(ReleaseAsset asset, String token) =>
      asset.name.toLowerCase().contains(token.toLowerCase());
  ReleaseAsset? best(Iterable<ReleaseAsset> candidates, List<String> tokens) {
    ReleaseAsset? winner;
    var winnerScore = -1;
    for (final asset in candidates) {
      var score = 0;
      for (var i = 0; i < tokens.length; i++) {
        if (nameHas(asset, tokens[i])) {
          score = tokens.length - i;
          break;
        }
      }
      if (score > winnerScore) {
        winner = asset;
        winnerScore = score;
      }
    }
    return winnerScore > 0 ? winner : null;
  }

  switch (platform) {
    case 'android':
      final apks = assets.where(
        (a) => a.name.toLowerCase().endsWith('.apk') && nameHas(a, '-android-'),
      );
      // Exact device architecture first, the universal build second.
      return best(apks, ['-android-$arch.apk', '-android-universal.apk']);
    case 'windows':
      if (portable) {
        final zips = assets.where(
          (a) =>
              a.name.toLowerCase().endsWith('.zip') &&
              nameHas(a, '-windows-') &&
              nameHas(a, 'portable'),
        );
        return best(zips, [arch, 'amd64', 'x64']);
      }
      final installers = assets.where(
        (a) =>
            a.name.toLowerCase().endsWith('-setup.exe') &&
            nameHas(a, '-windows-'),
      );
      // Asset tokens spell Intel as both amd64 and x64 across builds.
      final tokens = arch == 'amd64' ? ['amd64', 'x64', 'arm64'] : [arch];
      return best(installers, tokens);
    default:
      // macOS / Linux stay on the release page this phase (T56 scope).
      return null;
  }
}

/// The SHA256SUMS asset of the release, when it carries one.
ReleaseAsset? findSumsAsset(List<ReleaseAsset> assets) {
  for (final asset in assets) {
    if (asset.name == 'SHA256SUMS') return asset;
  }
  return null;
}

/// Parses a SHA256SUMS file (`<hex>  <name>` per line, also the
/// `*<name>` binary form) into lower-case hex digests by file name.
Map<String, String> parseSha256Sums(String text) {
  final result = <String, String>{};
  final linePattern = RegExp(r'^([0-9a-fA-F]{64})\s+\*?(.+)$');
  for (final line in text.split('\n')) {
    final match = linePattern.firstMatch(line.trim());
    if (match == null) continue;
    final name = match.group(2)!.trim().split('/').last;
    result[name] = match.group(1)!.toLowerCase();
  }
  return result;
}

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
    final tag = release['tag_name'];
    if (tag is! String || tag.isEmpty) return releasesUrl;
    final page = '$releasesUrl/tag/${Uri.encodeComponent(tag)}';
    if (assetSuffix.isEmpty) return page;
    final version = tag.replaceFirst(RegExp(r'^v'), '');
    final names = {
      'AngelaMihomo-$version-$assetSuffix',
      // Legacy asset names from before the rebrand, kept so update
      // checks can still deep-link downloads of older releases.
      'Bettbox-$version-$assetSuffix',
      'AngelaBettbox-$version-$assetSuffix',
    };
    final assets = release['assets'];
    if (assets is! List) return page;
    final matches = assets
        .whereType<Map>()
        .where((asset) => names.contains(asset['name']))
        .toList();
    if (matches.length != 1) return page;
    final url = matches.single['browser_download_url'];
    if (url is! String) return page;
    final uri = Uri.tryParse(url);
    // Only open an exact asset from this repository and this release tag.
    final expected = Uri.parse(
      'https://github.com/$repository/releases/download/${Uri.encodeComponent(tag)}/${Uri.encodeComponent(matches.single['name'] as String)}',
    );
    if (uri == null || uri != expected) return page;
    return url;
  }
}
