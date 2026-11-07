import 'dart:ffi';
import 'dart:io';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/common/release_updates.dart';
import 'package:bett_box/plugins/app.dart';
import 'package:bett_box/state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

enum InAppUpdateOutcome {
  /// The system installer (Android) or the setup program (Windows)
  /// was launched.
  launched,

  /// The flow ended with a message shown; nothing else to do.
  handled,

  /// No verifiable in-app path exists for this release/device; the
  /// caller should open the release page (a reason was already shown).
  fellBackToPage,
}

String _platformName() => system.isAndroid
    ? 'android'
    : system.isWindows
    ? 'windows'
    : system.isMacOS
    ? 'macos'
    : 'linux';

/// Device architecture in release-asset token spelling.
String _deviceArch() => switch (Abi.current()) {
  Abi.androidArm64 => 'arm64-v8a',
  Abi.androidArm => 'armeabi-v7a',
  Abi.androidX64 => 'x86_64',
  Abi.androidIA32 => 'x86',
  Abi.windowsArm64 => 'arm64',
  _ => 'amd64',
};

Future<void> _showUpdateMessage(String text) async {
  await globalState.showMessage(
    title: appLocalizations.checkUpdate,
    message: TextSpan(text: text),
    cancelable: false,
  );
}

/// Runs the in-app update (T56) for Android/Windows: pick the asset
/// from the release's own list, fetch SHA256SUMS, download with
/// progress + cancel through the core proxy when running, verify the
/// digest, and only then hand the file to the installer. Any failure
/// path deletes the staged file and says why, in plain language.
Future<InAppUpdateOutcome> runInAppUpdate(
  BuildContext context,
  Map<String, dynamic> release, {
  required String repository,
  required Future<void> Function() exitApp,
}) async {
  final assets = releaseAssetsOf(release, repository: repository);
  final choice = selectUpdateAsset(
    assets,
    platform: _platformName(),
    arch: _deviceArch(),
    portable: system.isWindows && appPath.isPortable,
  );
  if (choice == null) {
    await _showUpdateMessage(appLocalizations.updateNoMatchingAsset);
    return InAppUpdateOutcome.fellBackToPage;
  }
  final sumsAsset = findSumsAsset(assets);
  if (sumsAsset == null) {
    await _showUpdateMessage(appLocalizations.updateSumsMissing);
    return InAppUpdateOutcome.fellBackToPage;
  }
  String? expected;
  try {
    final sumsText = await fetchUpdateText(sumsAsset.url);
    expected = parseSha256Sums(sumsText)[choice.name];
  } catch (_) {
    expected = null;
  }
  if (expected == null) {
    // No digest for this asset means no verification — fail closed.
    await _showUpdateMessage(appLocalizations.updateSumsMissing);
    return InAppUpdateOutcome.fellBackToPage;
  }

  final dir = Directory(
    '${(await getTemporaryDirectory()).path}/angela_updates',
  );
  // Stale staged packages are cleaned before every new download.
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
  if (!context.mounted) return InAppUpdateOutcome.handled;
  final result = await showDialog<({File? file, Object? error})>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateDownloadDialog(
      url: choice.url,
      dir: dir,
      fileName: choice.name,
      isAndroid: system.isAndroid,
    ),
  );
  final file = result?.file;
  if (file == null) {
    // Cancelled by the user, or the download failed (dialog showed
    // the error before closing).
    return InAppUpdateOutcome.handled;
  }
  final verified = await verifyFileSha256(file, expected);
  if (!verified) {
    await file.delete();
    await _showUpdateMessage(appLocalizations.updateChecksumMismatch);
    return InAppUpdateOutcome.handled;
  }
  if (system.isAndroid) {
    await App().installApk(file.path);
    return InAppUpdateOutcome.launched;
  }
  // Windows: launch the setup program, then exit so it can replace
  // the app's files (the installer stops the helper services first —
  // T55 — so no locked-DLL errors).
  await Process.start(
    file.path,
    const [],
    mode: ProcessStartMode.detached,
  );
  globalState.showNotifier(appLocalizations.updateInstallLaunch);
  await exitApp();
  return InAppUpdateOutcome.launched;
}

class _UpdateDownloadDialog extends StatefulWidget {
  final String url;
  final Directory dir;
  final String fileName;
  final bool isAndroid;

  const _UpdateDownloadDialog({
    required this.url,
    required this.dir,
    required this.fileName,
    required this.isAndroid,
  });

  @override
  State<_UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<_UpdateDownloadDialog> {
  final _cancelToken = CancelToken();
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final file = await downloadUpdateAsset(
        url: widget.url,
        dir: widget.dir,
        fileName: widget.fileName,
        cancelToken: _cancelToken,
        onProgress: (value) {
          if (mounted) setState(() => _progress = value);
        },
      );
      if (mounted) Navigator.of(context).pop((file: file, error: null));
    } catch (error) {
      if (!mounted) return;
      if (_cancelToken.isCancelled) {
        Navigator.of(context).pop((file: null, error: null));
        return;
      }
      setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(appLocalizations.updateProgressTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: _progress == 0 ? null : _progress),
          const SizedBox(height: 12),
          Text('${(_progress * 100).toStringAsFixed(0)}%'),
          if (widget.isAndroid) ...[
            const SizedBox(height: 12),
            Text(
              appLocalizations.updateInstallPermissionNote,
              style: context.textTheme.bodySmall,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: context.colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        if (_error == null)
          TextButton(
            onPressed: () => _cancelToken.cancel(),
            child: Text(appLocalizations.cancel),
          )
        else
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop((file: null, error: _error)),
            child: Text(appLocalizations.confirm),
          ),
      ],
    );
  }
}
