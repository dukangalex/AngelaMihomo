import 'dart:convert';
import 'dart:io';

import 'package:angelamihomo/common/data_signature.dart';
import 'package:angelamihomo/common/path.dart';
import 'package:angelamihomo/common/release_updates.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';

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

  Future<File> download(
    ReleaseAsset asset, {
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await appPath.tempDir.future;
    final file = File('${dir.path}/${asset.name}');
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
