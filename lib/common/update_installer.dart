import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:angelamihomo/common/data_signature.dart';
import 'package:angelamihomo/common/path.dart';
import 'package:angelamihomo/common/release_updates.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';

/// Pause / resume handle for [UpdateInstaller.downloadPausable].
/// Pausing pauses the response stream's subscription, which stops
/// the transfer itself (TCP backpressure), not just its display.
class PausableDownloadHandle {
  StreamSubscription<List<int>>? _subscription;
  bool _paused = false;

  bool get isPaused => _paused;

  void _attach(StreamSubscription<List<int>> subscription) {
    _subscription = subscription;
    if (_paused) subscription.pause();
  }

  void pause() {
    if (_paused) return;
    _paused = true;
    _subscription?.pause();
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    _subscription?.resume();
  }

  void toggle() => _paused ? resume() : pause();
}

/// AngelaMihomo (chain.26, T179): the second half of the update flow —
/// download the validated release asset inside the app, verify it
/// against the SHA-256 digest GitHub reports for that exact asset,
/// then hand it to the platform installer. The update channel stays
/// limited to this repository's GitHub releases, as before.
///
/// T273: the in-app path additionally requires the release's signed
/// checksum manifest (`sha256sums.txt` + `sha256sums.txt.sig`, see
/// [updateSigningPublicKeyBase64]). The digest used for verification
/// must come from that signature-verified manifest and agree with the
/// digest GitHub reports; a release without a valid signed manifest
/// is not installed in-app (the browser download path stays
/// available, as for any asset without a digest).
class UpdateInstaller {
  final Dio _dio;

  UpdateInstaller({Dio? dio}) : _dio = dio ?? Dio();

  /// Downloads a small release asset (the checksum manifest or its
  /// signature) into memory through the same validated URL.
  Future<List<int>> downloadBytes(ReleaseAsset asset) async {
    final response = await _dio.get<List<int>>(
      asset.url,
      options: Options(
        responseType: ResponseType.bytes,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(minutes: 2),
        followRedirects: true,
      ),
    );
    return response.data ?? const [];
  }

  /// Returns the SHA-256 digest for [assetName] from a release's
  /// checksum manifest, but only when the manifest's detached Ed25519
  /// signature verifies against the update signing key. Any failure —
  /// bad signature, malformed manifest, asset not listed — returns
  /// null (fail closed).
  Future<String?> verifiedDigest({
    required List<int> manifestBytes,
    required List<int> signatureBytes,
    required String assetName,
    List<int>? publicKeyBytes,
  }) async {
    final keyBytes =
        publicKeyBytes ?? base64.decode(updateSigningPublicKeyBase64);
    final ok = await verifyManifestSignature(
      manifestBytes,
      signatureBytes,
      publicKeyBytes: keyBytes,
    );
    if (!ok) return null;
    return sha256DigestFromManifest(manifestBytes, assetName);
  }

  /// Normalizes a release asset name to a plain file name (T284,
  /// audit AM-08): the name comes from the release API response, so
  /// every directory component — forward- or backslash-separated —
  /// is stripped before it is joined with the local download
  /// directory, and a name like `../../x` can never escape it.
  /// Degenerate results fall back to a fixed file name.
  static String localAssetFileName(String assetName) {
    final segments = assetName.trim().split(RegExp(r'[/\\]'));
    final base = segments.isEmpty ? '' : segments.last;
    if (base.isEmpty || base == '.' || base == '..') {
      return 'update-package';
    }
    return base;
  }

  Future<File> download(
    ReleaseAsset asset, {
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await appPath.tempDir.future;
    final file = File('${dir.path}/${localAssetFileName(asset.name)}');
    await _dio.download(
      asset.url,
      file.path,
      cancelToken: cancelToken,
      onReceiveProgress: onProgress,
      options: Options(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(minutes: 10),
        followRedirects: true,
      ),
    );
    return file;
  }

  /// Lucian UX/UI Prompt #082 · MIT License — the update dialog's
  /// icon progress needs a transfer that can pause and resume in
  /// place: this variant streams the response to disk so pausing
  /// the stream subscription applies real backpressure (no bytes
  /// are dropped or re-fetched). The result goes through the same
  /// SHA-256 verification as [download], so a paused, resumed or
  /// truncated transfer can never install — it can only fail the
  /// digest check like any other bad download.
  Future<File> downloadPausable(
    ReleaseAsset asset, {
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
    PausableDownloadHandle? handle,
  }) async {
    final dir = await appPath.tempDir.future;
    final file = File('${dir.path}/${localAssetFileName(asset.name)}');
    final response = await _dio.get<ResponseBody>(
      asset.url,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(minutes: 10),
        followRedirects: true,
      ),
    );
    final body = response.data!;
    final total = body.contentLength;
    final sink = file.openWrite();
    var received = 0;
    final completer = Completer<void>();
    final subscription = body.stream.listen(
      (chunk) {
        received += chunk.length;
        sink.add(chunk);
        onProgress(received, total);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );
    handle?._attach(subscription);
    try {
      await completer.future;
      await sink.flush();
      await sink.close();
      return file;
    } catch (_) {
      await sink.close();
      try {
        await file.delete();
      } catch (_) {}
      rethrow;
    }
  }

  /// Streams the file through SHA-256 so even the largest package
  /// never loads into memory at once.
  Future<bool> verify(File file, String expectedSha256) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == expectedSha256.toLowerCase();
  }

  /// Hands the verified package to the platform's own installer.
  /// Returns an error description when the hand-off itself failed.
  Future<String?> launchInstaller(File file) async {
    try {
      if (Platform.isWindows && file.path.toLowerCase().endsWith('.exe')) {
        // Inno Setup installer: run it directly; it elevates itself.
        await Process.start(
          file.path,
          const [],
          mode: ProcessStartMode.detached,
        );
        return null;
      }
      if (Platform.isMacOS) {
        final res = await Process.run('open', [file.path]);
        return res.exitCode == 0 ? null : 'open exited ${res.exitCode}';
      }
      if (Platform.isLinux) {
        final res = await Process.run('xdg-open', [file.path]);
        return res.exitCode == 0 ? null : 'xdg-open exited ${res.exitCode}';
      }
      // Android (APK → system installer) and any other platform: the
      // system file opener resolves the right handler.
      final result = await OpenFilex.open(file.path);
      return result.type == ResultType.done ? null : result.message;
    } catch (e) {
      return e.toString();
    }
  }
}

/// Looks up [assetName] in a `sha256sums.txt` body and returns its
/// lowercase hex SHA-256 digest, or null when the asset is not listed
/// with a well-formed digest. Line format follows the coreutils
/// convention shared with the geo data manifest:
/// `<64 hex chars><whitespace>[*]<file name>`.
String? sha256DigestFromManifest(List<int> manifestBytes, String assetName) {
  final text = utf8.decode(manifestBytes, allowMalformed: true);
  for (final line in text.split('\n')) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length != 2) continue;
    final digest = parts[0].toLowerCase();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) continue;
    var name = parts[1];
    if (name.startsWith('*')) name = name.substring(1);
    if (name == assetName) return digest;
  }
  return null;
}
