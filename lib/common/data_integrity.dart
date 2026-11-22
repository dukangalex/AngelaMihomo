import 'dart:convert';
import 'dart:io';

import 'package:angelamihomo/common/constant.dart';
import 'package:angelamihomo/common/data_signature.dart';
import 'package:angelamihomo/common/path.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// AngelaMihomo (T228/T233): runtime integrity anchors for the data
/// the app ships and the data the core downloads.
///
/// The build pins the bundled core-bundle assets by SHA-256
/// (setup.dart), but a pin checked at build time says nothing about
/// the bytes an installed, possibly repacked app actually carries.
/// This service re-checks them at runtime against the data
/// repository's signed manifest — the same Ed25519 discipline as
/// the script and geo channels (fail-closed: no manifest, no
/// signature, or a bad signature means "could not verify", never
/// "trusted"):
///
/// - T228: the bundled BundleMRS.7z and zash.zip (assets/data/) are
///   hashed and compared with core-bundle-2026.12's signed
///   sha256sums.txt.
/// - T233: the .mrs rule files the core has downloaded into its
///   home ruleset/ directory are compared with geo-data-2026.11's
///   signed sha256sums.txt, which covers every provider file the
///   bundled managed.js references. A file whose digest differs is
///   deleted, so the core fetches a fresh copy instead of running
///   on a corrupted or swapped rule set. Files the manifest does
///   not list (a user's own providers) are left alone.
///
/// Every outcome is recorded in SharedPreferences and shown on the
/// resources page; failures are stated with their reason.

class DataIntegrityStatus {
  final DateTime? checkedAt;

  /// True when both bundled assets matched the signed manifest,
  /// false when any check failed, null before the first run.
  final bool? bundleOk;
  final String? bundleError;

  /// How many downloaded rule files were compared against the
  /// signed manifest in the last run, and how many were removed
  /// for digest mismatch.
  final int rulesetChecked;
  final int rulesetRemoved;
  final String? rulesetError;

  const DataIntegrityStatus({
    this.checkedAt,
    this.bundleOk,
    this.bundleError,
    this.rulesetChecked = 0,
    this.rulesetRemoved = 0,
    this.rulesetError,
  });

  Map<String, dynamic> toJson() => {
    if (checkedAt != null) 'checkedAt': checkedAt!.toIso8601String(),
    if (bundleOk != null) 'bundleOk': bundleOk,
    if (bundleError != null) 'bundleError': bundleError,
    'rulesetChecked': rulesetChecked,
    'rulesetRemoved': rulesetRemoved,
    if (rulesetError != null) 'rulesetError': rulesetError,
  };

  static DataIntegrityStatus? fromJson(Object? raw) {
    try {
      if (raw is! Map) return null;
      final at = raw['checkedAt'];
      return DataIntegrityStatus(
        checkedAt: at is String ? DateTime.tryParse(at) : null,
        bundleOk: raw['bundleOk'] is bool ? raw['bundleOk'] as bool : null,
        bundleError: raw['bundleError'] is String
            ? raw['bundleError'] as String
            : null,
        rulesetChecked: raw['rulesetChecked'] is int
            ? raw['rulesetChecked'] as int
            : 0,
        rulesetRemoved: raw['rulesetRemoved'] is int
            ? raw['rulesetRemoved'] as int
            : 0,
        rulesetError: raw['rulesetError'] is String
            ? raw['rulesetError'] as String
            : null,
      );
    } catch (_) {
      return null;
    }
  }
}

class DataIntegrityService {
  static const String metaPrefKey = 'dataIntegrityMeta';

  /// The bundled assets the core-bundle release's signed manifest
  /// covers, by their manifest (and asset) file names.
  static const List<String> bundleAssetNames = ['BundleMRS.7z', 'zash.zip'];

  final String _bundleBaseUrl;
  final String _geoBaseUrl;
  final Future<List<int>?> Function(String url) _fetchBytes;
  final Future<List<int>> Function(String assetName) _loadBundledAsset;
  final Future<String> Function() _homeDir;
  final Future<String?> Function() _loadMeta;
  final Future<void> Function(String? raw) _saveMeta;
  final List<int>? _manifestPublicKeyBytes;

  DataIntegrityService({
    String? bundleBaseUrl,
    String? geoBaseUrl,
    Future<List<int>?> Function(String url)? bytesFetcher,
    Future<List<int>> Function(String assetName)? bundledAssetLoader,
    Future<String> Function()? homeDirResolver,
    Future<String?> Function()? metaLoader,
    Future<void> Function(String? raw)? metaSaver,
    List<int>? manifestPublicKeyBytes,
  }) : _bundleBaseUrl = bundleBaseUrl ?? coreBundleRawUrl,
       _geoBaseUrl = geoBaseUrl ?? bundleMRSRawUrl,
       _fetchBytes = bytesFetcher ?? _defaultFetchBytes,
       _loadBundledAsset = bundledAssetLoader ?? _defaultBundledAsset,
       _homeDir = homeDirResolver ?? (() => appPath.homeDirPath),
       _loadMeta = metaLoader ?? _prefsMeta,
       _saveMeta = metaSaver ?? _savePrefsMeta,
       _manifestPublicKeyBytes = manifestPublicKeyBytes;

  static Dio? _dio;

  /// Default byte fetcher: null on 404 (file absent), throws on any
  /// other failure, so "absent" stays distinguishable from "could
  /// not be checked" — the house pattern for manifest fetches.
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

  static Future<List<int>> _defaultBundledAsset(String assetName) async {
    final data = await rootBundle.load('assets/data/$assetName');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
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

  String _url(String base, String name) =>
      '$base${base.endsWith('/') ? '' : '/'}$name';

  Future<DataIntegrityStatus> currentStatus() async {
    try {
      final raw = await _loadMeta();
      if (raw == null || raw.isEmpty) return const DataIntegrityStatus();
      return DataIntegrityStatus.fromJson(json.decode(raw)) ??
          const DataIntegrityStatus();
    } catch (_) {
      return const DataIntegrityStatus();
    }
  }

  Future<void> _writeStatus(DataIntegrityStatus status) async {
    try {
      await _saveMeta(json.encode(status.toJson()));
    } catch (_) {}
  }

  /// Fetch a release's sha256sums.txt and verify its Ed25519
  /// signature before trusting a single digest in it. Returns the
  /// parsed digest map (file name → lowercase sha256), or throws a
  /// [StateError] whose message is the recorded failure reason.
  Future<Map<String, String>> _verifiedManifest(String baseUrl) async {
    List<int>? sumsBytes;
    try {
      sumsBytes = await _fetchBytes(_url(baseUrl, 'sha256sums.txt'));
    } catch (_) {
      throw StateError('sha256sums.txt unreachable');
    }
    if (sumsBytes == null) throw StateError('sha256sums.txt not found');
    List<int>? sigBytes;
    try {
      sigBytes = await _fetchBytes(_url(baseUrl, 'sha256sums.txt.sig'));
    } catch (_) {
      throw StateError('sha256sums.txt.sig unreachable');
    }
    if (sigBytes == null) throw StateError('sha256sums.txt.sig not found');
    final verified = await verifyManifestSignature(
      sumsBytes,
      sigBytes,
      publicKeyBytes: _manifestPublicKeyBytes,
    );
    if (!verified) throw StateError('manifest signature invalid');
    final digests = <String, String>{};
    for (final line in utf8.decode(sumsBytes).split('\n')) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length == 2) {
        final digest = parts[0].toLowerCase();
        if (RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
          digests[parts[1].replaceFirst('*', '')] = digest;
        }
      }
    }
    if (digests.isEmpty) throw StateError('manifest carries no digests');
    return digests;
  }

  /// Run both checks and record the outcome. Never throws: each
  /// half records its own failure reason.
  Future<DataIntegrityStatus> runChecks() async {
    bool? bundleOk;
    String? bundleError;
    try {
      final digests = await _verifiedManifest(_bundleBaseUrl);
      for (final name in bundleAssetNames) {
        final expected = digests[name];
        if (expected == null) {
          throw StateError('manifest has no entry for $name');
        }
        List<int> bytes;
        try {
          bytes = await _loadBundledAsset(name);
        } catch (_) {
          throw StateError('bundled asset missing: $name');
        }
        if (sha256.convert(bytes).toString() != expected) {
          throw StateError('$name digest mismatch');
        }
      }
      bundleOk = true;
    } on StateError catch (e) {
      bundleOk = false;
      bundleError = e.message;
    } catch (_) {
      bundleOk = false;
      bundleError = 'bundle check failed';
    }

    var rulesetChecked = 0;
    var rulesetRemoved = 0;
    String? rulesetError;
    try {
      final digests = await _verifiedManifest(_geoBaseUrl);
      final dir = Directory(p.join(await _homeDir(), 'ruleset'));
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is! File) continue;
          final name = p.basename(entity.path);
          if (!name.endsWith('.mrs')) continue;
          final expected = digests[name];
          if (expected == null) continue;
          rulesetChecked++;
          final actual = sha256.convert(await entity.readAsBytes()).toString();
          if (actual != expected) {
            await entity.delete();
            rulesetRemoved++;
          }
        }
      }
    } on StateError catch (e) {
      rulesetError = e.message;
    } catch (_) {
      rulesetError = 'ruleset check failed';
    }

    final status = DataIntegrityStatus(
      checkedAt: DateTime.now(),
      bundleOk: bundleOk,
      bundleError: bundleError,
      rulesetChecked: rulesetChecked,
      rulesetRemoved: rulesetRemoved,
      rulesetError: rulesetError,
    );
    await _writeStatus(status);
    return status;
  }
}
