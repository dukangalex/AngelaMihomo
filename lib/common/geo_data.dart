import 'dart:convert';
import 'dart:io';

import 'package:bett_box/common/constant.dart';
import 'package:bett_box/common/path.dart';
import 'package:bett_box/common/release_updates.dart';
import 'package:bett_box/common/update_installer.dart';

/// AngelaMihomo (chain.26, T194): city-level geolocation data, hosted
/// in the project's own data repository (dukangalex/angelamihomo-geo)
/// and pulled by the app itself — on first launch when missing, and on
/// demand from the About page. The downloaded file lands in the core
/// home directory as amcity.bin, where the core's local reader picks
/// it up; lookups never leave the device. The channel is the same
/// GitHub-releases-only channel the in-app updater (T179) uses, with
/// the same digest verification.

enum GeoUpdateOutcome { updated, alreadyLatest, failed, verifyFailed }

/// Bookkeeping for the locally stored city database. The meta file is
/// authoritative: a data file without readable meta counts as absent
/// and is fetched again, which keeps partial or foreign files from
/// being trusted.
class GeoDataMeta {
  final String tag;
  final DateTime downloadedAt;

  const GeoDataMeta({required this.tag, required this.downloadedAt});

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'downloadedAt': downloadedAt.toIso8601String(),
  };

  static GeoDataMeta? fromJson(Object? raw) {
    try {
      if (raw is! Map) return null;
      final tag = raw['tag'];
      final at = raw['downloadedAt'];
      if (tag is! String || tag.isEmpty || at is! String) return null;
      final parsed = DateTime.tryParse(at);
      if (parsed == null) return null;
      return GeoDataMeta(tag: tag, downloadedAt: parsed);
    } catch (_) {
      return null;
    }
  }
}

class GeoDataService {
  static const String assetName = 'amcity.bin.gz';
  static const String dataFileName = 'amcity.bin';
  static const String metaFileName = 'amcity.meta.json';

  final ReleaseUpdates _updates;
  final UpdateInstaller _installer;
  final List<Duration> _retryDelays;

  GeoDataService({
    ReleaseUpdates? updates,
    UpdateInstaller? installer,
    List<Duration>? retryDelays,
  }) : _updates = updates ?? ReleaseUpdates(repository: geoDataRepository),
       _installer = installer ?? UpdateInstaller(),
       _retryDelays =
           retryDelays ?? const [Duration(seconds: 20), Duration(seconds: 60)];

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
      final release = await _updates.latest();
      if (release == null) return GeoUpdateOutcome.failed;
      final tag = release['tag_name'];
      if (tag is! String || tag.isEmpty) return GeoUpdateOutcome.failed;
      final current = await currentMeta();
      if (current != null && current.tag == tag) {
        return GeoUpdateOutcome.alreadyLatest;
      }
      var asset = _updates.assetByName(release, name: assetName);
      if (asset == null || asset.sha256 == null) {
        // The release lookup fell back to the web redirect (API rate
        // limit or outage), which yields a tag but no asset list.
        // The data repository's URLs are deterministic and every
        // release ships a sha256sums.txt, so resolve the asset from
        // the release itself — same trust anchor (GitHub over HTTPS)
        // and the same digest verification below.
        asset = await _fallbackAsset(tag);
        if (asset == null) return GeoUpdateOutcome.failed;
      }
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
        final meta = GeoDataMeta(tag: tag, downloadedAt: DateTime.now());
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
    } catch (_) {
      return GeoUpdateOutcome.failed;
    }
  }

  /// Resolve the database asset straight from the release at [tag]
  /// when the API asset list is unavailable: the download URL is
  /// deterministic for this repository, and the expected SHA-256
  /// comes from the release's own sha256sums.txt.
  Future<ReleaseAsset?> _fallbackAsset(String tag) async {
    try {
      final base =
          'https://github.com/$geoDataRepository/releases/download/${Uri.encodeComponent(tag)}';
      final response = await _updates.client.get<Object?>(
        '$base/sha256sums.txt',
      );
      final text = response.data?.toString();
      if (text == null) return null;
      String? digest;
      for (final line in text.split('\n')) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length == 2 && parts[1].replaceFirst('*', '') == assetName) {
          digest = parts[0].toLowerCase();
          break;
        }
      }
      if (digest == null || !RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
        return null;
      }
      return ReleaseAsset(
        name: assetName,
        url: '$base/$assetName',
        sha256: digest,
      );
    } catch (_) {
      return null;
    }
  }
}
