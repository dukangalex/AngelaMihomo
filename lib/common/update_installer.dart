import 'dart:io';

import 'package:bett_box/common/path.dart';
import 'package:bett_box/common/release_updates.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';

/// AngelaMihomo (chain.26, T179): the second half of the update flow —
/// download the validated release asset inside the app, verify it
/// against the SHA-256 digest GitHub reports for that exact asset,
/// then hand it to the platform installer. The update channel stays
/// limited to this repository's GitHub releases, as before.
class UpdateInstaller {
  final Dio _dio;

  UpdateInstaller({Dio? dio}) : _dio = dio ?? Dio();

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
