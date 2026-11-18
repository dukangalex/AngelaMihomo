import 'dart:convert';
import 'dart:io';

import 'package:angelamihomo/common/constant.dart';
import 'package:angelamihomo/common/data_signature.dart';
import 'package:angelamihomo/common/path.dart';
import 'package:angelamihomo/common/release_updates.dart';
import 'package:angelamihomo/common/update_installer.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AngelaMihomo (chain.26, T194): city-level geolocation data, hosted
/// in the project's own data repository (dukangalex/angelamihomo-geo)
/// and pulled by the app itself — on first launch when missing, and on
/// demand from the About page. The downloaded file lands in the core
/// home directory as amcity.bin, where the core's local reader picks
/// it up; lookups never leave the device. The channel is the same
/// GitHub-releases-only channel the in-app updater (T179) uses, with
/// the same digest verification. Since chain.28 (T220) the digest on
/// the project-repository path comes from the release's
/// sha256sums.txt, and when that manifest ships its Ed25519 signature
/// (sha256sums.txt.sig) the signature must verify before anything is
/// installed — see data_signature.dart. The user may point the pull at
/// a source of their own instead (T201); a custom source must ship a
/// sha256sums.txt next to the file and passes the same digest
/// verification (custom sources stay hash-only: they are the user's
/// own choice, and no project key signs for them).

enum GeoUpdateOutcome { updated, alreadyLatest, failed, verifyFailed }

/// Bookkeeping for the locally stored city database. The meta file is
/// authoritative: a data file without readable meta counts as absent
/// and is fetched again, which keeps partial or foreign files from
/// being trusted.
class GeoDataMeta {
  final String tag;
  final DateTime downloadedAt;

  /// The user-chosen source URL the data was pulled from, when it
  /// did not come from the project data repository (T201). Recorded
  /// so the provenance of the local copy stays traceable.
  final String? sourceUrl;

  const GeoDataMeta({
    required this.tag,
    required this.downloadedAt,
    this.sourceUrl,
  });

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'downloadedAt': downloadedAt.toIso8601String(),
    if (sourceUrl != null) 'sourceUrl': sourceUrl,
  };

  static GeoDataMeta? fromJson(Object? raw) {
    try {
      if (raw is! Map) return null;
      final tag = raw['tag'];
      final at = raw['downloadedAt'];
      if (tag is! String || tag.isEmpty || at is! String) return null;
      final parsed = DateTime.tryParse(at);
      if (parsed == null) return null;
      final source = raw['sourceUrl'];
      return GeoDataMeta(
        tag: tag,
        downloadedAt: parsed,
        sourceUrl: source is String && source.isNotEmpty ? source : null,
      );
    } catch (_) {
      return null;
    }
  }
}

class GeoDataService {
  static const String assetName = 'amcity.bin.gz';
  static const String dataFileName = 'amcity.bin';
  static const String metaFileName = 'amcity.meta.json';

  /// Preferences key for the user-chosen source URL (T201). Absent
  /// means the default channel: the project data repository.
  static const String sourceUrlPrefKey = 'geoDataSourceUrl';

  /// Meta tag recorded for data pulled from a user-chosen source.
  static const String customTag = 'custom';

  final ReleaseUpdates _updates;
  final UpdateInstaller _installer;
  final List<Duration> _retryDelays;
  final Future<String?> Function() _loadSourceUrl;
  final Future<void> Function(String? url) _saveSourceUrl;

  /// Fetches the raw bytes of a manifest file (sha256sums.txt or its
  /// .sig) for the project-repository path (T220). Returns null when
  /// the file is absent (HTTP 404); other failures throw. Injectable
  /// for tests, following the loader/saver pattern above.
  final Future<List<int>?> Function(String url)? _manifestBytesFetcher;

  /// Public key the manifest signature must verify against (T220);
  /// null uses the embedded release key. Injectable for tests.
  final List<int>? _manifestPublicKeyBytes;

  GeoDataService({
    ReleaseUpdates? updates,
    UpdateInstaller? installer,
    List<Duration>? retryDelays,
    Future<String?> Function()? sourceUrlLoader,
    Future<void> Function(String? url)? sourceUrlSaver,
    Future<List<int>?> Function(String url)? manifestBytesFetcher,
    List<int>? manifestPublicKeyBytes,
  }) : _updates = updates ?? ReleaseUpdates(repository: geoDataRepository),
       _installer = installer ?? UpdateInstaller(),
       _retryDelays =
           retryDelays ?? const [Duration(seconds: 20), Duration(seconds: 60)],
       _loadSourceUrl = sourceUrlLoader ?? _prefsSourceUrl,
       _saveSourceUrl = sourceUrlSaver ?? _savePrefsSourceUrl,
       _manifestBytesFetcher = manifestBytesFetcher,
       _manifestPublicKeyBytes = manifestPublicKeyBytes;

  static Future<String?> _prefsSourceUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(sourceUrlPrefKey);
    return value == null || value.isEmpty ? null : value;
  }

  static Future<void> _savePrefsSourceUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.isEmpty) {
      await prefs.remove(sourceUrlPrefKey);
    } else {
      await prefs.setString(sourceUrlPrefKey, url);
    }
  }

  /// The user-chosen source URL for the city database, or null when
  /// the default project-repository channel applies (T201).
  Future<String?> customSourceUrl() async {
    try {
      final value = await _loadSourceUrl();
      return value == null || value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  /// Set or clear (null) the user-chosen source URL (T201).
  Future<void> setCustomSourceUrl(String? url) async {
    try {
      await _saveSourceUrl(url);
    } catch (_) {}
  }

  /// The download URL the next default-channel pull will use, for
  /// display on the resources page: the newest data release's asset
  /// URL, resolved the same way the pull itself resolves it (T216),
  /// or null when it cannot be resolved right now.
  Future<String?> latestDataAssetUrl() async {
    try {
      final release = await _updates.latestWithAsset(name: assetName);
      final tag = release?['tag_name'];
      if (tag is! String || tag.isEmpty) return null;
      return 'https://github.com/$geoDataRepository/releases/download/${Uri.encodeComponent(tag)}/$assetName';
    } catch (_) {
      return null;
    }
  }

  /// One pull at a time, shared by every caller (first-launch
  /// auto-pull, retries and the About page button may overlap).
  static Future<GeoUpdateOutcome>? _inFlight;

  Future<File> _dataFile() async =>
      File('${await appPath.homeDirPath}/$dataFileName');

  Future<File> _metaFile() async =>
      File('${await appPath.homeDirPath}/$metaFileName');

  /// The meta of the usable local database, or null when there is
  /// none (never downloaded, or bookkeeping unreadable).
  Future<GeoDataMeta?> currentMeta() async {
    try {
      if (!await (await _dataFile()).exists()) return null;
      final metaFile = await _metaFile();
      if (!await metaFile.exists()) return null;
      return GeoDataMeta.fromJson(json.decode(await metaFile.readAsString()));
    } catch (_) {
      return null;
    }
  }

  /// First-launch entry point: fetch the database when it is missing.
  /// Silent by design — a failed attempt retries within this launch
  /// (see [_retryDelays]) and again on the next launch, and the app
  /// keeps working with country-level data meanwhile. The in-launch
  /// retries matter: the single first attempt races the device still
  /// settling its network right after startup, which is how the
  /// chain.26 first build reached real phones without the database.
  Future<void> ensureData() async {
    try {
      if (await currentMeta() != null) return;
      var outcome = await updateNow();
      for (final delay in _retryDelays) {
        if (outcome == GeoUpdateOutcome.updated ||
            outcome == GeoUpdateOutcome.alreadyLatest) {
          return;
        }
        await Future<void>.delayed(delay);
        if (await currentMeta() != null) return;
        outcome = await updateNow();
      }
    } catch (_) {
      // Silent by design; see class doc.
    }
  }

  /// Fetch the latest database now. When the local copy already is
  /// the latest release, nothing is downloaded. Concurrent callers
  /// share the same in-flight pull.
  Future<GeoUpdateOutcome> updateNow({
    void Function(int received, int total)? onProgress,
  }) async {
    final running = _inFlight;
    if (running != null) return running;
    final future = _updateNow(onProgress: onProgress);
    _inFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlight, future)) _inFlight = null;
    }
  }

  Future<GeoUpdateOutcome> _updateNow({
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      // T201: a user-chosen source replaces the repository channel.
      // It is held to the same standard — the expected SHA-256 comes
      // from a sha256sums.txt shipped next to the file, and the
      // payload still has to pass the format check in _install.
      final custom = await customSourceUrl();
      if (custom != null) {
        final asset = await _assetFromSumsFile(custom);
        if (asset == null) return GeoUpdateOutcome.failed;
        return await _install(
          asset,
          tag: customTag,
          sourceUrl: custom,
          onProgress: onProgress,
        );
      }
      final release = await _updates.latestWithAsset(name: assetName);
      if (release == null) return GeoUpdateOutcome.failed;
      final tag = release['tag_name'];
      if (tag is! String || tag.isEmpty) return GeoUpdateOutcome.failed;
      final current = await currentMeta();
      if (current != null && current.tag == tag) {
        return GeoUpdateOutcome.alreadyLatest;
      }
      // T220: on the project-repository path the asset — and with it
      // the trusted digest — is derived from the release's
      // sha256sums.txt, signature-verified whenever the release ships
      // a signature. The GitHub API path above now only discovers
      // the target tag.
      final resolved = await _projectAsset(release, tag);
      if (resolved.verifyFailed) return GeoUpdateOutcome.verifyFailed;
      final asset = resolved.asset;
      if (asset == null) return GeoUpdateOutcome.failed;
      return await _install(asset, tag: tag, onProgress: onProgress);
    } catch (_) {
      return GeoUpdateOutcome.failed;
    }
  }

  /// Download [asset], verify its SHA-256 and the AMCITY01 format,
  /// then swap it in as the local database and record [tag] (and
  /// [sourceUrl] for user-chosen sources) in the meta file.
  Future<GeoUpdateOutcome> _install(
    ReleaseAsset asset, {
    required String tag,
    String? sourceUrl,
    void Function(int received, int total)? onProgress,
  }) async {
    final gz = await _installer.download(
      asset,
      onProgress: onProgress ?? (_, _) {},
    );
    try {
      if (!await _installer.verify(gz, asset.sha256!)) {
        return GeoUpdateOutcome.verifyFailed;
      }
      final raw = gzip.decode(await gz.readAsBytes());
      if (raw.length < 8 ||
          String.fromCharCodes(raw.sublist(0, 8)) != 'AMCITY01') {
        return GeoUpdateOutcome.verifyFailed;
      }
      final dataFile = await _dataFile();
      final tmp = File('${dataFile.path}.tmp');
      await tmp.writeAsBytes(raw, flush: true);
      await tmp.rename(dataFile.path);
      final meta = GeoDataMeta(
        tag: tag,
        downloadedAt: DateTime.now(),
        sourceUrl: sourceUrl,
      );
      await (await _metaFile()).writeAsString(
        json.encode(meta.toJson()),
        flush: true,
      );
      return GeoUpdateOutcome.updated;
    } finally {
      try {
        await gz.delete();
      } catch (_) {}
    }
  }

  /// Fetch the raw bytes at [url] through the release client's
  /// connection, for the manifest files of the project-repository
  /// path (T220). A 404 maps to null (the file is absent); every
  /// other failure throws, so callers can tell "absent" apart from
  /// "could not be checked".
  Future<List<int>?> _fetchManifestBytes(String url) async {
    final injected = _manifestBytesFetcher;
    if (injected != null) return injected(url);
    try {
      final response = await _updates.client.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Resolve the project-repository asset for [tag] from the
  /// release's sha256sums.txt (T220), which is the authoritative
  /// digest source on this path:
  ///
  /// - The manifest ships a signature (sha256sums.txt.sig):
  ///   verification is mandatory. A bad signature yields
  ///   `verifyFailed: true` and no asset — nothing is installed.
  /// - The manifest ships no signature: TRANSITION RULE — releases
  ///   published before manifest signing have no .sig; their
  ///   manifest-derived digest is accepted hash-only, exactly as
  ///   every release was before signing existed. Once every live
  ///   release is signed, a missing signature can be made fatal and
  ///   this branch removed.
  /// - The manifest itself is unreachable: fall back to the pre-T220
  ///   resolution (the GitHub-API asset with its reported digest, or
  ///   [_fallbackAsset], which fails on its own when there is no
  ///   manifest either).
  Future<({ReleaseAsset? asset, bool verifyFailed})> _projectAsset(
    Map<String, dynamic> release,
    String tag,
  ) async {
    final base =
        'https://github.com/$geoDataRepository/releases/download/${Uri.encodeComponent(tag)}';
    List<int>? sumsBytes;
    try {
      sumsBytes = await _fetchManifestBytes('$base/sha256sums.txt');
    } catch (_) {
      sumsBytes = null;
    }
    if (sumsBytes == null) {
      var asset = _updates.assetByName(release, name: assetName);
      if (asset == null || asset.sha256 == null) {
        asset = await _fallbackAsset(tag);
      }
      return (asset: asset, verifyFailed: false);
    }
    List<int>? sigBytes;
    try {
      sigBytes = await _fetchManifestBytes('$base/sha256sums.txt.sig');
    } catch (_) {
      // Whether a signature exists could not be determined; do not
      // install on a manifest whose verification state is unknown.
      return (asset: null, verifyFailed: false);
    }
    if (sigBytes != null) {
      final verified = await verifyManifestSignature(
        sumsBytes,
        sigBytes,
        publicKeyBytes: _manifestPublicKeyBytes,
      );
      if (!verified) return (asset: null, verifyFailed: true);
    }
    final asset = _assetFromSumsBytes(sumsBytes, fileUrl: '$base/$assetName');
    return (asset: asset, verifyFailed: false);
  }

  /// The expected SHA-256 for the file named [name] in a
  /// sha256sums.txt body, or null when the manifest does not carry a
  /// well-formed entry for it.
  static String? _digestFromSums(String text, String name) {
    for (final line in text.split('\n')) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length == 2 && parts[1].replaceFirst('*', '') == name) {
        final digest = parts[0].toLowerCase();
        return RegExp(r'^[0-9a-f]{64}$').hasMatch(digest) ? digest : null;
      }
    }
    return null;
  }

  /// Pair the file at [fileUrl] with the digest a (verified, on the
  /// project path) sha256sums.txt body carries for it.
  ReleaseAsset? _assetFromSumsBytes(
    List<int> sumsBytes, {
    required String fileUrl,
  }) {
    try {
      final uri = Uri.parse(fileUrl);
      if (uri.pathSegments.isEmpty) return null;
      final name = uri.pathSegments.last;
      if (name.isEmpty) return null;
      final digest = _digestFromSums(utf8.decode(sumsBytes), name);
      if (digest == null) return null;
      return ReleaseAsset(name: name, url: fileUrl, sha256: digest);
    } catch (_) {
      return null;
    }
  }

  /// Resolve the database asset straight from the release at [tag]
  /// when the API asset list is unavailable: the download URL is
  /// deterministic for this repository, and the expected SHA-256
  /// comes from the release's own sha256sums.txt.
  Future<ReleaseAsset?> _fallbackAsset(String tag) {
    final url =
        'https://github.com/$geoDataRepository/releases/download/${Uri.encodeComponent(tag)}/$assetName';
    return _assetFromSumsFile(url);
  }

  /// Resolve the expected SHA-256 for the file at [fileUrl] from a
  /// sha256sums.txt shipped in the same directory, and pair the two
  /// into an asset. Any source of the city database — the project
  /// repository or a user-chosen one — must meet this standard.
  Future<ReleaseAsset?> _assetFromSumsFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      if (uri.pathSegments.isEmpty) return null;
      final name = uri.pathSegments.last;
      if (name.isEmpty) return null;
      final sumsUrl = uri
          .replace(
            pathSegments: [
              ...uri.pathSegments.take(uri.pathSegments.length - 1),
              'sha256sums.txt',
            ],
          )
          .toString();
      final response = await _updates.client.get<Object?>(sumsUrl);
      final text = response.data?.toString();
      if (text == null) return null;
      final digest = _digestFromSums(text, name);
      if (digest == null) return null;
      return ReleaseAsset(name: name, url: fileUrl, sha256: digest);
    } catch (_) {
      return null;
    }
  }
}
