import 'dart:convert';
import 'dart:io';

import 'package:angelamihomo/common/constant.dart';
import 'package:angelamihomo/common/data_signature.dart';
import 'package:angelamihomo/common/path.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// AngelaMihomo (chain.28, T199/T220): the managed script's data
/// channel. The bundled assets/scripts/managed.js remains the floor,
/// but between app releases the script can now be refreshed from the
/// project's own data repository (dukangalex/angelamihomo-geo), the
/// same signed channel as the city database:
///
/// 1. Fetch sha256sums.txt and sha256sums.txt.sig from the data
///    release. Unlike the city database's legacy transition, this
///    channel is new, so the Ed25519 signature is REQUIRED — no
///    signature, no update, and the failure is recorded with its
///    reason instead of being silently swallowed.
/// 2. Take managed.js's expected SHA-256 from the verified manifest,
///    download the script, and check its digest before storing it.
/// 3. Store the verified copy under the app support scripts
///    directory; ManagedScript resolves the effective script as the
///    channel copy when its @version is at least the bundled one.
///
/// Every outcome — success or failure with its reason — is recorded
/// in the channel meta (SharedPreferences), which is what the
/// resources page displays.

enum ManagedScriptUpdateOutcome { updated, alreadyLatest, failed }

/// Bookkeeping for the channel copy of the managed script.
class ManagedScriptChannelStatus {
  /// SHA-256 of the stored channel copy, from the verified manifest.
  final String? sha256;

  /// The stored channel copy's @version, when a copy exists.
  final String? channelVersion;

  /// When the stored channel copy was downloaded.
  final DateTime? updatedAt;

  /// Outcome of the most recent check: 'updated', 'alreadyLatest'
  /// or 'failed'.
  final String? lastOutcome;

  /// Why the most recent check failed, when it did. Failures are
  /// stated, never hidden (the app's failure-notice rule).
  final String? lastError;

  const ManagedScriptChannelStatus({
    this.sha256,
    this.channelVersion,
    this.updatedAt,
    this.lastOutcome,
    this.lastError,
  });

  Map<String, dynamic> toJson() => {
    if (sha256 != null) 'sha256': sha256,
    if (channelVersion != null) 'version': channelVersion,
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (lastOutcome != null) 'lastOutcome': lastOutcome,
    if (lastError != null) 'lastError': lastError,
  };

  static ManagedScriptChannelStatus? fromJson(Object? raw) {
    try {
      if (raw is! Map) return null;
      final at = raw['updatedAt'];
      return ManagedScriptChannelStatus(
        sha256: raw['sha256'] is String ? raw['sha256'] as String : null,
        channelVersion: raw['version'] is String
            ? raw['version'] as String
            : null,
        updatedAt: at is String ? DateTime.tryParse(at) : null,
        lastOutcome: raw['lastOutcome'] is String
            ? raw['lastOutcome'] as String
            : null,
        lastError: raw['lastError'] is String
            ? raw['lastError'] as String
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  ManagedScriptChannelStatus copyWith({
    String? sha256,
    String? channelVersion,
    DateTime? updatedAt,
    String? lastOutcome,
    String? lastError,
    bool clearError = false,
  }) => ManagedScriptChannelStatus(
    sha256: sha256 ?? this.sha256,
    channelVersion: channelVersion ?? this.channelVersion,
    updatedAt: updatedAt ?? this.updatedAt,
    lastOutcome: lastOutcome ?? this.lastOutcome,
    lastError: clearError ? null : (lastError ?? this.lastError),
  );
}

class ManagedScriptUpdateService {
  static const String scriptFileName = 'managed.js';

  /// The stored channel copy lives next to the managed script's own
  /// file in the app support scripts directory, under its own name
  /// so user-edited custom scripts (ManagedScript.save) never
  /// clobber it and it never clobbers them.
  static const String channelFileName = 'managed.channel.js';

  static const String metaPrefKey = 'managedScriptChannelMeta';

  /// The @version header pattern, shared with managed_script.dart.
  static final RegExp versionPattern = RegExp(
    r'^//\s*@version\s+(\d+)\s*$',
    multiLine: true,
  );

  static String? parseVersion(String content) =>
      versionPattern.firstMatch(content)?.group(1);

  static int compareVersions(String a, String b) {
    final numA = BigInt.tryParse(a);
    final numB = BigInt.tryParse(b);
    if (numA != null && numB != null) return numA.compareTo(numB);
    return a.compareTo(b);
  }

  /// The effective script content: the channel copy wins when it
  /// exists and its @version is at least the bundled copy's,
  /// otherwise the bundled asset stays in effect.
  static String resolveEffectiveContent({
    required String bundledContent,
    String? channelContent,
  }) {
    if (channelContent == null) return bundledContent;
    final channelVersion = parseVersion(channelContent);
    if (channelVersion == null) return bundledContent;
    final bundledVersion = parseVersion(bundledContent);
    if (bundledVersion == null) return channelContent;
    return compareVersions(channelVersion, bundledVersion) >= 0
        ? channelContent
        : bundledContent;
  }

  final String _baseUrl;
  final Future<List<int>?> Function(String url) _fetchBytes;
  final Future<String?> Function() _loadMeta;
  final Future<void> Function(String? raw) _saveMeta;
  final Future<File> Function() _channelFile;
  final List<int>? _manifestPublicKeyBytes;

  ManagedScriptUpdateService({
    String? baseUrl,
    Future<List<int>?> Function(String url)? bytesFetcher,
    Future<String?> Function()? metaLoader,
    Future<void> Function(String? raw)? metaSaver,
    Future<File> Function()? channelFileResolver,
    List<int>? manifestPublicKeyBytes,
  }) : _baseUrl = baseUrl ?? bundleMRSRawUrl,
       _fetchBytes = bytesFetcher ?? _defaultFetchBytes,
       _loadMeta = metaLoader ?? _prefsMeta,
       _saveMeta = metaSaver ?? _savePrefsMeta,
       _channelFile = channelFileResolver ?? _defaultChannelFile,
       _manifestPublicKeyBytes = manifestPublicKeyBytes;

  static Dio? _dio;

  /// Default byte fetcher: null on 404 (file absent), throws on any
  /// other failure, so "absent" stays distinguishable from "could
  /// not be checked".
  static Future<List<int>?> _defaultFetchBytes(String url) async {
    final dio = _dio ??= Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    try {
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<String?> _prefsMeta() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(metaPrefKey);
  }

  static Future<void> _savePrefsMeta(String? raw) async {
    final prefs = await SharedPreferences.getInstance();
    if (raw == null) {
      await prefs.remove(metaPrefKey);
    } else {
      await prefs.setString(metaPrefKey, raw);
    }
  }

  static Future<File> _defaultChannelFile() async {
    final managedPath = await appPath.getScriptPath('managed');
    return File(p.join(p.dirname(managedPath), channelFileName));
  }

  String _url(String name) =>
      '$_baseUrl${_baseUrl.endsWith('/') ? '' : '/'}$name';

  Future<ManagedScriptChannelStatus> _readStatus() async {
    try {
      final raw = await _loadMeta();
      if (raw == null || raw.isEmpty) {
        return const ManagedScriptChannelStatus();
      }
      return ManagedScriptChannelStatus.fromJson(json.decode(raw)) ??
          const ManagedScriptChannelStatus();
    } catch (_) {
      return const ManagedScriptChannelStatus();
    }
  }

  Future<void> _writeStatus(ManagedScriptChannelStatus status) async {
    try {
      await _saveMeta(json.encode(status.toJson()));
    } catch (_) {}
  }

  /// The channel's current state for display: the stored copy's
  /// version and digest, when it landed, and the last check's
  /// outcome or failure reason. [bundledVersion] is the app-bundled
  /// script's version, when the caller knows it (ManagedScript
  /// loads it at startup); it only feeds [effectiveVersion].
  Future<
    ({
      ManagedScriptChannelStatus status,
      String? bundledVersion,
      String? effectiveVersion,
    })
  >
  currentStatus({String? bundledVersion}) async {
    final status = await _readStatus();
    final channel = status.channelVersion;
    final effective =
        channel != null &&
            (bundledVersion == null ||
                compareVersions(channel, bundledVersion) >= 0)
        ? channel
        : (bundledVersion ?? channel);
    return (
      status: status,
      bundledVersion: bundledVersion,
      effectiveVersion: effective,
    );
  }

  /// The stored channel copy's content, or null when there is none
  /// (or it no longer matches the digest recorded for it — a
  /// corrupted copy is never served).
  Future<String?> readChannelCopy() async {
    try {
      final file = await _channelFile();
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final status = await _readStatus();
      final recorded = status.sha256;
      if (recorded != null && sha256.convert(bytes).toString() != recorded) {
        return null;
      }
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }

  /// One check of the data channel. Never throws: the outcome and,
  /// on failure, its reason are recorded in the channel meta, and
  /// any previously stored copy is left exactly as it was.
  Future<ManagedScriptUpdateOutcome> checkAndUpdate() async {
    final previous = await _readStatus();
    Future<ManagedScriptUpdateOutcome> fail(String reason) async {
      await _writeStatus(
        previous.copyWith(lastOutcome: 'failed', lastError: reason),
      );
      return ManagedScriptUpdateOutcome.failed;
    }

    try {
      final sumsBytes = await _fetchBytes(_url('sha256sums.txt'));
      if (sumsBytes == null) return await fail('sha256sums.txt not found');
      final sigBytes = await _fetchBytes(_url('sha256sums.txt.sig'));
      if (sigBytes == null) {
        // This channel signs from day one: a missing signature is a
        // failure with a stated reason, never a silent downgrade to
        // hash-only.
        return await fail('sha256sums.txt.sig not found');
      }
      final verified = await verifyManifestSignature(
        sumsBytes,
        sigBytes,
        publicKeyBytes: _manifestPublicKeyBytes,
      );
      if (!verified) {
        return await fail('manifest signature verification failed');
      }

      String? digest;
      for (final line in utf8.decode(sumsBytes).split('\n')) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length == 2 &&
            parts[1].replaceFirst('*', '') == scriptFileName) {
          digest = parts[0].toLowerCase();
          break;
        }
      }
      if (digest == null || !RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
        return await fail('managed.js missing from sha256sums.txt');
      }
      if (previous.sha256 == digest && await (await _channelFile()).exists()) {
        await _writeStatus(
          previous.copyWith(lastOutcome: 'alreadyLatest', clearError: true),
        );
        return ManagedScriptUpdateOutcome.alreadyLatest;
      }
      final scriptBytes = await _fetchBytes(_url(scriptFileName));
      if (scriptBytes == null) return await fail('managed.js not found');
      if (sha256.convert(scriptBytes).toString() != digest) {
        return await fail('managed.js sha256 mismatch');
      }
      final content = utf8.decode(scriptBytes);
      final version = parseVersion(content);
      final file = await _channelFile();
      final temp = File(
        '${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
      );
      await temp.parent.create(recursive: true);
      await temp.writeAsBytes(scriptBytes, flush: true);
      await temp.rename(file.path);
      await _writeStatus(
        ManagedScriptChannelStatus(
          sha256: digest,
          channelVersion: version,
          updatedAt: DateTime.now(),
          lastOutcome: 'updated',
        ),
      );
      return ManagedScriptUpdateOutcome.updated;
    } catch (e) {
      return fail(e.toString());
    }
  }
}
